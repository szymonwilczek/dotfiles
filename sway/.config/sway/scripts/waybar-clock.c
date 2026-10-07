// The clock of waybar as a CFFI module, "środa, 07.10 15:43", which shows
// the calendar process (calendar.c) under it while hovered and opens it on
// a click.
// Loaded into waybar, so it must not crash it: the calendar is a process of
// its own, told what to do over a socket, and started anew when it died.
#include <gtk/gtk.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#include "waybar_cffi_module.h"

const size_t wbcffi_version = 2;

typedef struct {
  GtkWidget *label;
  guint timer;
  int calendar; // -1 while it is not running
  double scroll;
} Clock;

static gboolean tick(gpointer data) {
  Clock *c = data;
  GDateTime *now = g_date_time_new_now_local();
  char *text = g_date_time_format(now, "%A, %d.%m %H:%M");
  if (text)
    gtk_label_set_text(GTK_LABEL(c->label), text);
  g_free(text);

  // At the next minute, but within 10 s, as a timer does not run in suspend
  int ms = 60000 - g_date_time_get_second(now) * 1000 -
           g_date_time_get_microsecond(now) / 1000;
  g_date_time_unref(now);
  c->timer = g_timeout_add(MIN(ms + 20, 10000), tick, c);
  return G_SOURCE_REMOVE;
}

static void start_calendar(Clock *c) {
  int sv[2];
  if (socketpair(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0, sv) < 0)
    return;
  char *bin =
      g_build_filename(g_get_user_config_dir(), "sway/scripts/calendar", NULL);
  char *argv[] = {bin, NULL};
  if (g_spawn_async_with_fds(NULL, argv, NULL, G_SPAWN_DEFAULT, NULL, NULL,
                             NULL, sv[1], -1, -1, NULL)) {
    c->calendar = sv[0];
  } else {
    close(sv[0]);
  }
  close(sv[1]);
  g_free(bin);
}

// No SIGPIPE when the calendar died: it is started anew instead
static void tell(Clock *c, const char *line) {
  for (int attempt = 0; attempt < 2; attempt++) {
    if (c->calendar < 0)
      start_calendar(c);
    if (c->calendar < 0)
      return;
    if (send(c->calendar, line, strlen(line), MSG_NOSIGNAL) >= 0)
      return;
    close(c->calendar);
    c->calendar = -1;
  }
}

// The output of the clock and the clock's centre on it
static void tell_where(Clock *c, const char *what) {
  GtkWidget *w = c->label;
  GdkWindow *win = gtk_widget_get_window(w);
  if (!win)
    return;
  GdkRectangle out;
  gdk_monitor_get_geometry(
      gdk_display_get_monitor_at_window(gtk_widget_get_display(w), win), &out);
  int cx, cy;
  gtk_widget_translate_coordinates(w, gtk_widget_get_toplevel(w),
                                   gtk_widget_get_allocated_width(w) / 2, 0,
                                   &cx, &cy);
  char line[64];
  snprintf(line, sizeof(line), "%s %d %d %d\n", what, out.x, out.y, cx);
  tell(c, line);
}

static gboolean on_enter(GtkWidget *w, GdkEventCrossing *ev, gpointer data) {
  if (ev->detail != GDK_NOTIFY_INFERIOR)
    tell_where(data, "peek");
  return FALSE;
}

static gboolean on_leave(GtkWidget *w, GdkEventCrossing *ev, gpointer data) {
  if (ev->detail != GDK_NOTIFY_INFERIOR)
    tell(data, "leave\n");
  return FALSE;
}

static gboolean on_click(GtkWidget *w, GdkEventButton *ev, gpointer data) {
  if (ev->type != GDK_BUTTON_PRESS || ev->button != GDK_BUTTON_PRIMARY)
    return FALSE;
  tell_where(data, "click");
  return TRUE;
}

// The wheel over the clock browses the months of the calendar
static gboolean on_scroll(GtkWidget *w, GdkEventScroll *ev, gpointer data) {
  Clock *c = data;
  int months = 0;
  if (ev->direction == GDK_SCROLL_UP)
    months = -1;
  else if (ev->direction == GDK_SCROLL_DOWN)
    months = 1;
  else if (ev->direction == GDK_SCROLL_SMOOTH) {
    // a touchpad sends many small deltas, a wheel notch adds up to 1
    c->scroll += ev->delta_y;
    months = (int)c->scroll;
    c->scroll -= months;
  }
  if (months) {
    char line[32];
    snprintf(line, sizeof(line), "shift %d\n", months);
    tell(c, line);
  }
  return TRUE;
}

void *wbcffi_init(const wbcffi_init_info *info,
                  const wbcffi_config_entry *config, size_t config_len) {
  Clock *c = g_new0(Clock, 1);
  c->calendar = -1;
  GtkContainer *root = info->get_root_widget(info->obj);

  GtkWidget *events = gtk_event_box_new();
  gtk_widget_add_events(events, GDK_SCROLL_MASK | GDK_SMOOTH_SCROLL_MASK |
                                    GDK_ENTER_NOTIFY_MASK |
                                    GDK_LEAVE_NOTIFY_MASK);
  g_signal_connect(events, "enter-notify-event", G_CALLBACK(on_enter), c);
  g_signal_connect(events, "leave-notify-event", G_CALLBACK(on_leave), c);
  g_signal_connect(events, "button-press-event", G_CALLBACK(on_click), c);
  g_signal_connect(events, "scroll-event", G_CALLBACK(on_scroll), c);

  c->label = gtk_label_new("");
  gtk_widget_set_name(c->label, "clock");
  gtk_container_add(GTK_CONTAINER(events), c->label);
  gtk_container_add(root, events);
  gtk_widget_show_all(events);

  start_calendar(c);
  tick(c);
  return c;
}

void wbcffi_deinit(void *instance) {
  Clock *c = instance;
  if (c->timer)
    g_source_remove(c->timer);
  // The calendar quits on the end of its stdin
  if (c->calendar >= 0)
    close(c->calendar);
  g_free(c);
}
