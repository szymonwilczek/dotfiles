// pactl for the mixer and the output picker: its commands, its JSON,
// and its events, which keep what they show read before they are shown
#pragma once

#include <gtk/gtk.h>
#include <json-c/json.h>
#include <signal.h>
#include <string.h>
#include <sys/prctl.h>

// Output of a pactl command, NULL when it failed; argv is not run by a shell
static char *pactl(const char *a, const char *b, const char *c, const char *d) {
  const char *argv[] = {"pactl", a, b, c, d, NULL};
  char *out = NULL;
  int status;
  if (!g_spawn_sync(NULL, (char **)argv, NULL,
                    G_SPAWN_SEARCH_PATH | G_SPAWN_STDERR_TO_DEV_NULL, NULL,
                    NULL, &out, NULL, &status, NULL) ||
      !g_spawn_check_wait_status(status, NULL)) {
    g_free(out);
    return NULL;
  }
  return out;
}

// pactl -f json, as the text of pactl and wpctl is translated and decorated
static json_object *pactl_json(const char *what) {
  char *out = pactl("-f", "json", "list", what);
  json_object *root = out ? json_tokener_parse(out) : NULL;
  g_free(out);
  return root;
}

static const char *str(json_object *obj, const char *key) {
  json_object *v;
  if (!obj || !json_object_object_get_ex(obj, key, &v))
    return NULL;
  const char *s = json_object_get_string(v);
  return s && *s ? s : NULL;
}

// What a modal shows of pactl, read in a thread as each pactl takes a while:
// read gives a copy of it and apply takes it over on the main thread
typedef struct {
  gpointer (*read)(void);
  void (*apply)(gpointer data, gpointer read);
  gpointer data;
  gboolean streams; // its events too, or of sinks and the server alone
  guint pending;
  gboolean reading, again;
  int queued; // commands of pactl_later not run yet
} Watch;

static void pactl_watch(Watch *w);
static void watch_read(Watch *w);

static void watch_on_read(GObject *src, GAsyncResult *res, gpointer data) {
  Watch *w = data;
  gpointer read = g_task_propagate_pointer(G_TASK(res), NULL);
  w->reading = FALSE;
  // Read before the commands still queued, so it is read again after them
  if (w->again || w->queued) {
    w->again = FALSE;
    g_free(read);
    if (!w->queued)
      watch_read(w);
    return;
  }
  w->apply(w->data, read);
}

static void watch_thread(GTask *task, gpointer src, gpointer data,
                         GCancellable *c) {
  Watch *w = data;
  g_task_return_pointer(task, w->read(), g_free);
}

static void watch_read(Watch *w) {
  if (w->reading) {
    w->again = TRUE;
    return;
  }
  w->reading = TRUE;
  GTask *task = g_task_new(NULL, NULL, watch_on_read, w);
  g_task_set_task_data(task, w, NULL);
  g_task_run_in_thread(task, watch_thread);
  g_object_unref(task);
}

// Not while commands are queued, as it is read once they ran
static gboolean watch_changed(gpointer data) {
  Watch *w = data;
  w->pending = 0;
  if (!w->queued)
    watch_read(w);
  return G_SOURCE_REMOVE;
}

static gboolean watch_restart(gpointer data) {
  pactl_watch(data);
  return G_SOURCE_REMOVE;
}

// A burst of events, as a stream starting, is read once
static gboolean watch_on_line(GIOChannel *ch, GIOCondition cond,
                              gpointer data) {
  Watch *w = data;
  char *line = NULL;
  GIOStatus status;
  while ((status = g_io_channel_read_line(ch, &line, NULL, NULL, NULL)) ==
         G_IO_STATUS_NORMAL) {
    gboolean stream = strstr(line, "sink-input") != NULL;
    if ((stream ? w->streams : strstr(line, "sink") != NULL) ||
        strstr(line, "server")) {
      if (!w->pending)
        w->pending = g_timeout_add(30, watch_changed, w);
    }
    g_free(line);
  }
  if (status == G_IO_STATUS_EOF || status == G_IO_STATUS_ERROR) {
    // PipeWire restarted: read it all anew once it is back
    g_io_channel_shutdown(ch, FALSE, NULL);
    g_timeout_add(1000, watch_restart, w);
    return G_SOURCE_REMOVE;
  }
  return G_SOURCE_CONTINUE;
}

// pactl takes no SIGPIPE, so it would outlive this process
static void die_with_parent(gpointer data) { prctl(PR_SET_PDEATHSIG, SIGTERM); }

static void reap(GPid pid, int status, gpointer data) {
  g_spawn_close_pid(pid);
}

// apply on the events of sinks, streams and the default sink, as by
// pactl subscribe, which runs as long as this process
static void pactl_watch(Watch *w) {
  const char *argv[] = {"pactl", "subscribe", NULL};
  // Its events untranslated, to be told apart
  char **env = g_environ_setenv(g_get_environ(), "LC_ALL", "C", TRUE);
  int out;
  GPid pid;
  gboolean started = g_spawn_async_with_pipes(
      NULL, (char **)argv, env,
      G_SPAWN_SEARCH_PATH | G_SPAWN_STDERR_TO_DEV_NULL |
          G_SPAWN_DO_NOT_REAP_CHILD,
      die_with_parent, NULL, &pid, NULL, &out, NULL, NULL);
  g_strfreev(env);
  if (!started) {
    g_timeout_add(1000, watch_restart, w);
    return;
  }
  g_child_watch_add(pid, reap, NULL);
  GIOChannel *ch = g_io_channel_unix_new(out);
  g_io_channel_set_close_on_unref(ch, TRUE);
  g_io_channel_set_flags(ch, G_IO_FLAG_NONBLOCK, NULL);
  g_io_add_watch(ch, G_IO_IN | G_IO_HUP | G_IO_ERR, watch_on_line, w);
  g_io_channel_unref(ch);
  watch_read(w);
}

typedef struct {
  Watch *w;
  char *argv[5];
} Later;

static gboolean later_done(gpointer data) {
  Later *l = data;
  if (--l->w->queued == 0)
    watch_read(l->w);
  for (int i = 0; i < 4; i++)
    g_free(l->argv[i]);
  g_free(l);
  return G_SOURCE_REMOVE;
}

static void later_run(gpointer data, gpointer user_data) {
  Later *l = data;
  g_free(pactl(l->argv[0], l->argv[1], l->argv[2], l->argv[3]));
  g_idle_add(later_done, l);
}

// A pactl command run in a thread, after the ones before it;
// what w shows is read anew once none is left, as the modal shows it
// changed at once
static inline void pactl_later(Watch *w, const char *a, const char *b,
                               const char *c, const char *d) {
  static GThreadPool *queue;
  if (!queue)
    queue = g_thread_pool_new(later_run, NULL, 1, FALSE, NULL);
  Later *l = g_new0(Later, 1);
  l->w = w;
  const char *args[] = {a, b, c, d};
  // NULL ends them, as for pactl
  for (int i = 0; i < 4 && args[i]; i++)
    l->argv[i] = g_strdup(args[i]);
  w->queued++;
  g_thread_pool_push(queue, l, NULL);
}
