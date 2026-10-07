#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>
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

static void render(Calendar *cal) {
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

static void shift(Calendar *cal, int months) {
  int n = cal->shown_year * 12 + cal->shown_month + months;
  cal->shown_year = n / 12;
  cal->shown_month = n % 12;
  render(cal);
}

static void reset(Calendar *cal) {
  cal->shown_year = cal->today_year;
  cal->shown_month = cal->today_month;
  render(cal);
}

static gboolean on_key(GtkWidget *w, GdkEventKey *ev, gpointer data) {
  Calendar *cal = data;
  switch (ev->keyval) {
  case GDK_KEY_h:
  case GDK_KEY_Left:
  case GDK_KEY_k:
  case GDK_KEY_Up:
  case GDK_KEY_Page_Up:
    shift(cal, -1);
    break;
  case GDK_KEY_l:
  case GDK_KEY_Right:
  case GDK_KEY_j:
  case GDK_KEY_Down:
  case GDK_KEY_Page_Down:
    shift(cal, 1);
    break;
  case GDK_KEY_H:
    shift(cal, -12);
    break;
  case GDK_KEY_L:
    shift(cal, 12);
    break;
  case GDK_KEY_t:
  case GDK_KEY_Home:
  case GDK_KEY_space:
    reset(cal);
    break;
  case GDK_KEY_Escape:
  case GDK_KEY_q:
    gtk_main_quit();
    break;
  }
  return TRUE;
}

static gboolean on_scroll(GtkWidget *w, GdkEventScroll *ev, gpointer data) {
  Calendar *cal = data;
  if (ev->direction == GDK_SCROLL_UP)
    shift(cal, -1);
  else if (ev->direction == GDK_SCROLL_DOWN)
    shift(cal, 1);
  else if (ev->direction == GDK_SCROLL_SMOOTH) {
    // a touchpad sends many small deltas, a wheel notch adds up to 1
    static double acc;
    acc += ev->delta_y;
    for (; acc <= -1; acc++)
      shift(cal, -1);
    for (; acc >= 1; acc--)
      shift(cal, 1);
  }
  return TRUE;
}

static gboolean on_focus_out(GtkWidget *w, GdkEventFocus *ev, gpointer data) {
  gtk_main_quit();
  return FALSE;
}

static GtkWidget *label(const char *text, const char *class) {
  GtkWidget *l = gtk_label_new(text);
  gtk_style_context_add_class(gtk_widget_get_style_context(l), class);
  return l;
}

int main(int argc, char *argv[]) {
  g_set_prgname("sway-calendar");
  gtk_init(&argc, &argv);

  Calendar cal = {0};
  time_t now = time(NULL);
  struct tm *tm = localtime(&now);
  cal.today_year = tm->tm_year + 1900;
  cal.today_month = tm->tm_mon;
  cal.today_day = tm->tm_mday;

  GtkCssProvider *css = gtk_css_provider_new();
  char *path =
      g_build_filename(g_get_user_config_dir(), "sway/modal/style.css", NULL);
  gtk_css_provider_load_from_path(css, path, NULL);
  g_free(path);
  gtk_style_context_add_provider_for_screen(
      gdk_screen_get_default(), GTK_STYLE_PROVIDER(css),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

  GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(window), "Kalendarz");
  gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
  gtk_window_set_resizable(GTK_WINDOW(window), FALSE);

  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 14);
  gtk_style_context_add_class(gtk_widget_get_style_context(box), "modal");

  GtkWidget *header = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 10);
  gtk_style_context_add_class(gtk_widget_get_style_context(header), "heading");
  cal.month = label("", "title");
  cal.year = label("", "subtitle");
  gtk_box_pack_start(GTK_BOX(header), cal.month, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(header), cal.year, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box), header, FALSE, FALSE, 0);

  GtkWidget *grid = gtk_grid_new();
  gtk_grid_set_row_spacing(GTK_GRID(grid), 2);
  gtk_grid_set_column_spacing(GTK_GRID(grid), 4);
  for (int i = 0; i < 7; i++) {
    GtkWidget *l = label(WEEKDAYS[i], "weekday");
    gtk_widget_set_margin_bottom(l, 4);
    gtk_grid_attach(GTK_GRID(grid), l, i, 0, 1, 1);
  }
  for (int i = 0; i < CELLS; i++) {
    cal.cells[i] = label("", "day");
    gtk_grid_attach(GTK_GRID(grid), cal.cells[i], i % 7, 1 + i / 7, 1, 1);
  }
  gtk_box_pack_start(GTK_BOX(box), grid, FALSE, FALSE, 0);

  gtk_container_add(GTK_CONTAINER(window), box);
  reset(&cal);

  gtk_widget_add_events(window, GDK_SCROLL_MASK | GDK_SMOOTH_SCROLL_MASK);
  g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
  g_signal_connect(window, "key-press-event", G_CALLBACK(on_key), &cal);
  g_signal_connect(window, "scroll-event", G_CALLBACK(on_scroll), &cal);
  g_signal_connect(window, "focus-out-event", G_CALLBACK(on_focus_out), NULL);

  gtk_widget_show_all(window);
  gtk_main();
  return 0;
}
