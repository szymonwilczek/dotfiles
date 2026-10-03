// Splits the focused tiled window along its longer side, so the next
// window opens beside a wide one and below a tall one.
//
// Talks to sway over two IPC connections kept open, one for window
// events and one for the tree and the commands, and reads the tree
// only when a tiled window gets focus or moves.
//
// Tabbed and stacked containers are left alone.
//
// Built and started by autotiling.sh.

#include <errno.h>
#include <json-c/json.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#define IPC_MAGIC "i3-ipc"
#define IPC_HEADER_SIZE (sizeof(IPC_MAGIC) - 1 + 2 * sizeof(uint32_t))

#define IPC_COMMAND 0
#define IPC_SUBSCRIBE 2
#define IPC_GET_TREE 4

static int ipc_connect(const char *path) {
  struct sockaddr_un addr = {.sun_family = AF_UNIX};
  if (strlen(path) >= sizeof(addr.sun_path)) {
    fprintf(stderr, "autotiling: socket path too long\n");
    return -1;
  }
  strcpy(addr.sun_path, path);

  int fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
  if (fd < 0 || connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    perror("autotiling: connect");
    if (fd >= 0)
      close(fd);
    return -1;
  }
  return fd;
}

static int write_all(int fd, const void *buf, size_t len) {
  const char *p = buf;
  while (len > 0) {
    ssize_t n = write(fd, p, len);
    if (n < 0 && errno == EINTR)
      continue;
    if (n <= 0)
      return -1;
    p += n;
    len -= n;
  }
  return 0;
}

static int read_all(int fd, void *buf, size_t len) {
  char *p = buf;
  while (len > 0) {
    ssize_t n = read(fd, p, len);
    if (n < 0 && errno == EINTR)
      continue;
    if (n <= 0)
      return -1;
    p += n;
    len -= n;
  }
  return 0;
}

static int ipc_send(int fd, uint32_t type, const char *payload) {
  char header[IPC_HEADER_SIZE];
  uint32_t len = strlen(payload);
  memcpy(header, IPC_MAGIC, sizeof(IPC_MAGIC) - 1);
  memcpy(header + sizeof(IPC_MAGIC) - 1, &len, sizeof(len));
  memcpy(header + sizeof(IPC_MAGIC) - 1 + sizeof(len), &type, sizeof(type));
  if (write_all(fd, header, sizeof(header)) < 0 ||
      write_all(fd, payload, len) < 0)
    return -1;
  return 0;
}

// returns the payload of the next message, parsed, or NULL once sway is gone
static json_object *ipc_recv(int fd) {
  char header[IPC_HEADER_SIZE];
  if (read_all(fd, header, sizeof(header)) < 0 ||
      memcmp(header, IPC_MAGIC, sizeof(IPC_MAGIC) - 1) != 0)
    return NULL;

  uint32_t len;
  memcpy(&len, header + sizeof(IPC_MAGIC) - 1, sizeof(len));
  char *payload = malloc(len + 1);
  if (!payload || read_all(fd, payload, len) < 0) {
    free(payload);
    return NULL;
  }
  payload[len] = '\0';

  json_object *obj = json_tokener_parse(payload);
  free(payload);
  // a payload that does not parse is still a message, not the end of sway
  return obj ? obj : json_object_new_null();
}

static json_object *ipc_request(int fd, uint32_t type, const char *payload) {
  if (ipc_send(fd, type, payload) < 0)
    return NULL;
  return ipc_recv(fd);
}

static const char *get_string(json_object *obj, const char *key) {
  json_object *val;
  if (!json_object_object_get_ex(obj, key, &val))
    return "";
  const char *str = json_object_get_string(val);
  return str ? str : "";
}

static int64_t get_int(json_object *obj, const char *key) {
  json_object *val;
  if (!json_object_object_get_ex(obj, key, &val))
    return 0;
  return json_object_get_int64(val);
}

// finds the focused node among the tiled descendants of NODE,
// and sets *PARENT to the node holding it
static json_object *find_focused(json_object *node, json_object **parent) {
  json_object *nodes;
  if (!json_object_object_get_ex(node, "nodes", &nodes))
    return NULL;
  size_t n = json_object_array_length(nodes);
  for (size_t i = 0; i < n; i++) {
    json_object *child = json_object_array_get_idx(nodes, i);
    json_object *focused;
    if (json_object_object_get_ex(child, "focused", &focused) &&
        json_object_get_boolean(focused)) {
      *parent = node;
      return child;
    }
    json_object *found = find_focused(child, parent);
    if (found)
      return found;
  }
  return NULL;
}

static void autotile(int fd) {
  json_object *tree = ipc_request(fd, IPC_GET_TREE, "");
  if (!tree)
    return;

  json_object *parent = NULL;
  json_object *con = find_focused(tree, &parent);
  json_object *nodes;
  if (!con || strcmp(get_string(con, "type"), "con") != 0 ||
      get_int(con, "fullscreen_mode") != 0 ||
      // only windows, not containers focused with focus parent
      (json_object_object_get_ex(con, "nodes", &nodes) &&
       json_object_array_length(nodes) > 0))
    goto out;

  const char *layout = get_string(parent, "layout");
  if (strcmp(layout, "tabbed") == 0 || strcmp(layout, "stacked") == 0)
    goto out;

  json_object *rect;
  if (!json_object_object_get_ex(con, "rect", &rect))
    goto out;
  const char *split =
      get_int(rect, "height") > get_int(rect, "width") ? "splitv" : "splith";
  if (strcmp(layout, split) == 0)
    goto out;

  char cmd[64];
  snprintf(cmd, sizeof(cmd), "[con_id=%lld] %s", (long long)get_int(con, "id"),
           split);
  json_object *reply = ipc_request(fd, IPC_COMMAND, cmd);
  json_object_put(reply);

out:
  json_object_put(tree);
}

int main(void) {
  const char *path = getenv("SWAYSOCK");
  if (!path) {
    fprintf(stderr, "autotiling: SWAYSOCK is not set\n");
    return 1;
  }

  int events = ipc_connect(path);
  int requests = ipc_connect(path);
  if (events < 0 || requests < 0)
    return 1;

  json_object *reply = ipc_request(events, IPC_SUBSCRIBE, "[\"window\"]");
  json_object *success;
  if (!reply || !json_object_object_get_ex(reply, "success", &success) ||
      !json_object_get_boolean(success)) {
    fprintf(stderr, "autotiling: cannot subscribe to window events\n");
    return 1;
  }
  json_object_put(reply);

  json_object *event;
  while ((event = ipc_recv(events))) {
    const char *change = get_string(event, "change");
    json_object *con;
    // a window got focus, moved, or was tiled;
    // the container in the event says cheaply whether it is tiled,
    // before the tree is read
    if ((strcmp(change, "focus") == 0 || strcmp(change, "move") == 0 ||
         strcmp(change, "floating") == 0) &&
        json_object_object_get_ex(event, "container", &con) &&
        strcmp(get_string(con, "type"), "con") == 0 &&
        get_int(con, "fullscreen_mode") == 0)
      autotile(requests);
    json_object_put(event);
  }
  return 0;
}
