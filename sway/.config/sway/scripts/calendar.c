// The calendar under the waybar clock, one process for the bar's lifetime,
// told by waybar-clock.c on its stdin what to do, a command a line:
//
//   peek X Y CX   show it unfocused, under the clock at CX on the output at X,Y
//   leave         the pointer left the clock: hide a peek, and an open one
//                 too unless the pointer went onto it
//   click X Y CX  open it focused, or close it when it is open
//   shift N       browse N months
//
// It quits when its stdin closes, that is with waybar.
#include <gdk/gdkkeysyms.h>
#include <gtk-layer-shell.h>
#include <gtk/gtk.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#define CELLS 42

static const char *MONTHS[] = {
    "styczeń", "luty",     "marzec",   "kwiecień",    "maj",      "czerwiec",
    "lipiec",  "sierpień", "wrzesień", "październik", "listopad", "grudzień"};
static const char *WEEKDAYS[] = {"pn", "wt", "śr", "cz", "pt", "so", "nd"};

typedef struct {
  GtkWidget *month;
  GtkWidget *year;
  GtkWidget *cells[CELLS];
  int shown_year, shown_month;
  int today_year, today_month, today_day;
  double scroll;
} Calendar;

static int days_in_month(int year, int month) {
  static const int days[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
  int leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  return days[month] + (month == 1 && leap);
}

// 0 for Monday
static int first_weekday(int year, int month) {
  struct tm tm = {
      .tm_year = year - 1900, .tm_mon = month, .tm_mday = 1, .tm_hour = 12};
  mktime(&tm);
  return (tm.tm_wday + 6) % 7;
}

static void set_classes(GtkWidget *w, gboolean weekend, gboolean outside,
                        gboolean today) {
  GtkStyleContext *ctx = gtk_widget_get_style_context(w);
  (weekend ? gtk_style_context_add_class
           : gtk_style_context_remove_class)(ctx, "weekend");
  (outside ? gtk_style_context_add_class
           : gtk_style_context_remove_class)(ctx, "outside");
  (today ? gtk_style_context_add_class
         : gtk_style_context_remove_class)(ctx, "today");
}

static void calendar_render(Calendar *cal) {
  int y = cal->shown_year, m = cal->shown_month;
  int prev_m = (m + 11) % 12, prev_y = m == 0 ? y - 1 : y;
  int lead = first_weekday(y, m);
  int len = days_in_month(y, m), prev_len = days_in_month(prev_y, prev_m);

  gtk_label_set_text(GTK_LABEL(cal->month), MONTHS[m]);
  char buf[16];
  snprintf(buf, sizeof(buf), "%d", y);
  gtk_label_set_text(GTK_LABEL(cal->year), buf);

  for (int i = 0; i < CELLS; i++) {
    int day = i - lead + 1;
    gboolean outside = day < 1 || day > len;
    if (day < 1)
      day += prev_len;
    else if (day > len)
      day -= len;

    snprintf(buf, sizeof(buf), "%d", day);
    gtk_label_set_text(GTK_LABEL(cal->cells[i]), buf);
    set_classes(cal->cells[i], i % 7 >= 5, outside,
                !outside && y == cal->today_year && m == cal->today_month &&
                    day == cal->today_day);
  }
}

static void calendar_shift(Calendar *cal, int months) {
  int n = cal->shown_year * 12 + cal->shown_month + months;
  cal->shown_year = n / 12;
  cal->shown_month = n % 12;
  calendar_render(cal);
}

// Back to the current month, today read anew, as the process lives across days
static void calendar_today(Calendar *cal) {
  time_t now = time(NULL);
  struct tm tm;
  localtime_r(&now, &tm);
  cal->today_year = cal->shown_year = tm.tm_year + 1900;
  cal->today_month = cal->shown_month = tm.tm_mon;
  cal->today_day = tm.tm_mday;
  calendar_render(cal);
}

static void calendar_scroll(Calendar *cal, GdkEventScroll *ev) {
  if (ev->direction == GDK_SCROLL_UP)
    calendar_shift(cal, -1);
  else if (ev->direction == GDK_SCROLL_DOWN)
    calendar_shift(cal, 1);
  else if (ev->direction == GDK_SCROLL_SMOOTH) {
    // a touchpad sends many small deltas, a wheel notch adds up to 1
    cal->scroll += ev->delta_y;
    for (; cal->scroll <= -1; cal->scroll++)
      calendar_shift(cal, -1);
    for (; cal->scroll >= 1; cal->scroll--)
      calendar_shift(cal, 1);
  }
}

static GtkWidget *calendar_label(const char *text, const char *class) {
  GtkWidget *l = gtk_label_new(text);
  gtk_style_context_add_class(gtk_widget_get_style_context(l), class);
  return l;
}

// The heading and the grid, showing the current month
static GtkWidget *calendar_new(Calendar *cal) {
  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 14);

  GtkWidget *header = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 10);
  gtk_style_context_add_class(gtk_widget_get_style_context(header), "heading");
  cal->month = calendar_label("", "title");
  cal->year = calendar_label("", "subtitle");
  gtk_box_pack_start(GTK_BOX(header), cal->month, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(header), cal->year, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box), header, FALSE, FALSE, 0);

  GtkWidget *grid = gtk_grid_new();
  gtk_grid_set_row_spacing(GTK_GRID(grid), 2);
  gtk_grid_set_column_spacing(GTK_GRID(grid), 4);
  for (int i = 0; i < 7; i++) {
    GtkWidget *l = calendar_label(WEEKDAYS[i], "weekday");
    gtk_widget_set_margin_bottom(l, 4);
    gtk_grid_attach(GTK_GRID(grid), l, i, 0, 1, 1);
  }
  for (int i = 0; i < CELLS; i++) {
    cal->cells[i] = calendar_label("", "day");
    gtk_grid_attach(GTK_GRID(grid), cal->cells[i], i % 7, 1 + i / 7, 1, 1);
  }
  gtk_box_pack_start(GTK_BOX(box), grid, FALSE, FALSE, 0);

  calendar_today(cal);
  return box;
}

// Closing on a click elsewhere, which may land on the clock, must not reopen it
#define REOPEN_GUARD_US 300000

typedef enum { HIDDEN, PEEK, OPEN } Mode;

typedef struct {
  GtkWidget *window;
  Calendar cal;
  Mode mode;
  gboolean pointer_inside;
  gboolean over_clock;
  guint hide_timer;
  gint64 closed_at;
} App;

static void hide(App *app) {
  if (app->mode == OPEN)
    app->closed_at = g_get_monotonic_time();
  app->mode = HIDDEN;
  app->pointer_inside = FALSE;
  gtk_widget_hide(app->window);
}

static void cancel_hide(App *app) {
  if (app->hide_timer)
    g_source_remove(app->hide_timer);
  app->hide_timer = 0;
}

static gboolean hide_open(gpointer data) {
  App *app = data;
  app->hide_timer = 0;
  if (app->mode == OPEN && !app->pointer_inside && !app->over_clock)
    hide(app);
  return G_SOURCE_REMOVE;
}

// An open calendar stays while the pointer is on it or on the clock,
// with a moment to move between the two
static void hide_open_soon(App *app) {
  cancel_hide(app);
  app->hide_timer = g_timeout_add(300, hide_open, app);
}

// Under the clock, centred on it, but within the output
static void place(App *app, int x, int y, int cx) {
  GdkDisplay *display = gdk_display_get_default();
  GdkMonitor *monitor = NULL;
  for (int i = 0; i < gdk_display_get_n_monitors(display); i++) {
    GdkRectangle r;
    gdk_monitor_get_geometry(gdk_display_get_monitor(display, i), &r);
    if (r.x == x && r.y == y)
      monitor = gdk_display_get_monitor(display, i);
  }
  if (!monitor)
    return;

  GdkRectangle r;
  gdk_monitor_get_geometry(monitor, &r);
  int width;
  gtk_widget_get_preferred_width(app->window, NULL, &width);
  gtk_layer_set_monitor(GTK_WINDOW(app->window), monitor);
  gtk_layer_set_margin(GTK_WINDOW(app->window), GTK_LAYER_SHELL_EDGE_LEFT,
                       CLAMP(cx - width / 2, 0, MAX(r.width - width, 0)));
}

static void show(App *app, Mode mode) {
  cancel_hide(app);
  if (app->mode == HIDDEN)
    calendar_today(&app->cal);
  app->mode = mode;

  GtkStyleContext *ctx = gtk_widget_get_style_context(app->window);
  if (mode == OPEN)
    gtk_style_context_add_class(ctx, "open");
  else
    gtk_style_context_remove_class(ctx, "open");

  // A peek takes no keys, so it never takes focus from a window;
  // open one takes them all, until a click elsewhere
  gtk_layer_set_keyboard_mode(GTK_WINDOW(app->window),
                              mode == OPEN
                                  ? GTK_LAYER_SHELL_KEYBOARD_MODE_EXCLUSIVE
                                  : GTK_LAYER_SHELL_KEYBOARD_MODE_NONE);
  gtk_widget_show_all(app->window);
}

static void command(App *app, const char *line) {
  int x, y, cx, n;
  if (sscanf(line, "peek %d %d %d", &x, &y, &cx) == 3) {
    app->over_clock = TRUE;
    cancel_hide(app);
    if (app->mode == HIDDEN)
      place(app, x, y, cx);
    if (app->mode != OPEN)
      show(app, PEEK);
  } else if (!strcmp(line, "leave")) {
    app->over_clock = FALSE;
    if (app->mode == PEEK)
      hide(app);
    else if (app->mode == OPEN)
      hide_open_soon(app);
  } else if (sscanf(line, "click %d %d %d", &x, &y, &cx) == 3) {
    if (app->mode == OPEN ||
        g_get_monotonic_time() - app->closed_at < REOPEN_GUARD_US) {
      hide(app);
      return;
    }
    if (app->mode == HIDDEN)
      place(app, x, y, cx);
    show(app, OPEN);
  } else if (sscanf(line, "shift %d", &n) == 1) {
    if (app->mode != HIDDEN)
      calendar_shift(&app->cal, n);
  }
}

static gboolean on_stdin(GIOChannel *ch, GIOCondition cond, gpointer data) {
  char *line = NULL;
  GIOStatus status;
  while ((status = g_io_channel_read_line(ch, &line, NULL, NULL, NULL)) ==
         G_IO_STATUS_NORMAL) {
    command(data, g_strstrip(line));
    g_free(line);
  }
  if (status == G_IO_STATUS_EOF || status == G_IO_STATUS_ERROR) {
    gtk_main_quit();
    return G_SOURCE_REMOVE;
  }
  return G_SOURCE_CONTINUE;
}

static gboolean on_key(GtkWidget *w, GdkEventKey *ev, gpointer data) {
  App *app = data;
  Calendar *cal = &app->cal;
  switch (ev->keyval) {
  case GDK_KEY_h:
  case GDK_KEY_Left:
  case GDK_KEY_k:
  case GDK_KEY_Up:
  case GDK_KEY_Page_Up:
    calendar_shift(cal, -1);
    break;
  case GDK_KEY_l:
  case GDK_KEY_Right:
  case GDK_KEY_j:
  case GDK_KEY_Down:
  case GDK_KEY_Page_Down:
    calendar_shift(cal, 1);
    break;
  case GDK_KEY_H:
    calendar_shift(cal, -12);
    break;
  case GDK_KEY_L:
    calendar_shift(cal, 12);
    break;
  case GDK_KEY_t:
  case GDK_KEY_Home:
  case GDK_KEY_space:
    calendar_today(cal);
    break;
  case GDK_KEY_Escape:
  case GDK_KEY_q:
    hide(app);
    break;
  }
  return TRUE;
}

static gboolean on_scroll(GtkWidget *w, GdkEventScroll *ev, gpointer data) {
  App *app = data;
  calendar_scroll(&app->cal, ev);
  return TRUE;
}

static gboolean on_crossing(GtkWidget *w, GdkEventCrossing *ev, gpointer data) {
  App *app = data;
  if (ev->detail == GDK_NOTIFY_INFERIOR)
    return FALSE;
  app->pointer_inside = ev->type == GDK_ENTER_NOTIFY;
  if (app->pointer_inside)
    cancel_hide(app);
  else if (app->mode == OPEN)
    hide_open_soon(app);
  return FALSE;
}

// Also on motion, as a surface hidden under the pointer gets no enter on
// being shown again
static gboolean on_motion(GtkWidget *w, GdkEventMotion *ev, gpointer data) {
  App *app = data;
  app->pointer_inside = TRUE;
  cancel_hide(app);
  return FALSE;
}

// A click on a window or another output
static gboolean on_focus_out(GtkWidget *w, GdkEventFocus *ev, gpointer data) {
  App *app = data;
  if (app->mode == OPEN)
    hide(app);
  return FALSE;
}

int main(int argc, char *argv[]) {
  g_set_prgname("sway-calendar");
  gtk_init(&argc, &argv);

  GtkCssProvider *css = gtk_css_provider_new();
  char *path =
      g_build_filename(g_get_user_config_dir(), "sway/modal/style.css", NULL);
  gtk_css_provider_load_from_path(css, path, NULL);
  g_free(path);
  gtk_style_context_add_provider_for_screen(
      gdk_screen_get_default(), GTK_STYLE_PROVIDER(css),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

  App app = {.window = gtk_window_new(GTK_WINDOW_TOPLEVEL)};
  GtkWindow *window = GTK_WINDOW(app.window);
  gtk_window_set_title(window, "Kalendarz");
  gtk_window_set_resizable(window, FALSE);
  gtk_style_context_add_class(gtk_widget_get_style_context(app.window),
                              "calendar");

  // Above windows, under the bar, whose exclusive zone it keeps out of
  gtk_layer_init_for_window(window);
  gtk_layer_set_namespace(window, "calendar");
  gtk_layer_set_layer(window, GTK_LAYER_SHELL_LAYER_OVERLAY);
  gtk_layer_set_anchor(window, GTK_LAYER_SHELL_EDGE_TOP, TRUE);
  gtk_layer_set_anchor(window, GTK_LAYER_SHELL_EDGE_LEFT, TRUE);

  GtkWidget *box = calendar_new(&app.cal);
  gtk_style_context_add_class(gtk_widget_get_style_context(box), "modal");
  gtk_container_add(GTK_CONTAINER(window), box);

  gtk_widget_add_events(app.window, GDK_SCROLL_MASK | GDK_SMOOTH_SCROLL_MASK |
                                        GDK_ENTER_NOTIFY_MASK |
                                        GDK_LEAVE_NOTIFY_MASK |
                                        GDK_POINTER_MOTION_MASK);
  g_signal_connect(app.window, "key-press-event", G_CALLBACK(on_key), &app);
  g_signal_connect(app.window, "scroll-event", G_CALLBACK(on_scroll), &app);
  g_signal_connect(app.window, "enter-notify-event", G_CALLBACK(on_crossing),
                   &app);
  g_signal_connect(app.window, "leave-notify-event", G_CALLBACK(on_crossing),
                   &app);
  g_signal_connect(app.window, "motion-notify-event", G_CALLBACK(on_motion),
                   &app);
  g_signal_connect(app.window, "focus-out-event", G_CALLBACK(on_focus_out),
                   &app);
  g_signal_connect(app.window, "delete-event",
                   G_CALLBACK(gtk_widget_hide_on_delete), NULL);

  // Not blocking, so on_stdin reads what came and returns to GTK
  GIOChannel *in = g_io_channel_unix_new(0);
  g_io_channel_set_flags(in, G_IO_FLAG_NONBLOCK, NULL);
  g_io_add_watch(in, G_IO_IN | G_IO_HUP | G_IO_ERR, on_stdin, &app);

  gtk_main();
  return 0;
}
