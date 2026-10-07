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

typedef struct {
  void (*on_change)(gpointer data);
  gpointer data;
  guint pending;
} Watch;

static void pactl_watch(Watch *w);

static gboolean watch_changed(gpointer data) {
  Watch *w = data;
  w->pending = 0;
  w->on_change(w->data);
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
    if (strstr(line, "sink") || strstr(line, "server")) {
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

// on_change on the events of sinks, streams and the default sink, as by
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
  w->on_change(w->data);
}
