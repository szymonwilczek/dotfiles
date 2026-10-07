#include <dirent.h>
#include <gtk/gtk.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <sys/statvfs.h>

// A bar turns red from this fraction of its limit on
#define CRITICAL 0.85
#define GIB (1024.0 * 1024.0 * 1024.0)

typedef struct {
  GtkWidget *bar;
  GtkWidget *value;
} Row;

typedef struct {
  char cpu_hwmon[300];
  char gpu_hwmon[300];
  char nvme_hwmon[300];
  unsigned long long prev_idle, prev_total;
  Row load, cpu_temp;
  Row gpu_edge, gpu_junction, gpu_mem, gpu_fan, gpu_power;
  Row ram, disk, nvme_temp;
} App;

static long read_long(const char *dir, const char *file, long fallback) {
  char path[340];
  snprintf(path, sizeof(path), "%s/%s", dir, file);
  FILE *f = fopen(path, "r");
  if (!f)
    return fallback;
  long v;
  if (fscanf(f, "%ld", &v) != 1)
    v = fallback;
  fclose(f);
  return v;
}

static void read_line(const char *path, char *buf, size_t len) {
  FILE *f = fopen(path, "r");
  if (!f)
    return;
  if (fgets(buf, len, f))
    buf[strcspn(buf, "\n")] = '\0';
  fclose(f);
  g_strstrip(buf);
}

static void find_hwmons(App *app) {
  DIR *d = opendir("/sys/class/hwmon");
  if (!d)
    return;
  struct dirent *e;
  while ((e = readdir(d))) {
    if (strncmp(e->d_name, "hwmon", 5) != 0)
      continue;
    char dir[300], path[320], name[32] = "";
    snprintf(dir, sizeof(dir), "/sys/class/hwmon/%s", e->d_name);
    snprintf(path, sizeof(path), "%s/name", dir);
    read_line(path, name, sizeof(name));
    if (!strcmp(name, "k10temp") || !strcmp(name, "coretemp"))
      snprintf(app->cpu_hwmon, sizeof(app->cpu_hwmon), "%s", dir);
    else if (!strcmp(name, "amdgpu"))
      snprintf(app->gpu_hwmon, sizeof(app->gpu_hwmon), "%s", dir);
    else if (!strcmp(name, "nvme"))
      snprintf(app->nvme_hwmon, sizeof(app->nvme_hwmon), "%s", dir);
  }
  closedir(d);
}

static void cpu_name(char *buf, size_t len) {
  FILE *f = fopen("/proc/cpuinfo", "r");
  if (!f)
    return;
  char line[256];
  while (fgets(line, sizeof(line), f)) {
    char *colon = strchr(line, ':');
    if (strncmp(line, "model name", 10) != 0 || !colon)
      continue;
    char *name = g_strstrip(colon + 1);
    char *cut = strstr(name, "-Core");
    if (cut) {
      while (cut > name && cut[-1] != ' ')
        cut--;
      *cut = '\0';
    }
    snprintf(buf, len, "%s", g_strstrip(name));
    break;
  }
  fclose(f);
}

static void gpu_name(char *buf, size_t len) {
  FILE *p = popen("lspci 2>/dev/null", "r");
  if (!p)
    return;
  char line[256];
  while (fgets(line, sizeof(line), p)) {
    if (!strstr(line, "VGA") && !strstr(line, "3D controller"))
      continue;
    char *open = strrchr(line, '['), *close = strrchr(line, ']');
    if (open && close > open) {
      *close = '\0';
      snprintf(buf, len, "%s", open + 1);
    } else {
      char *name = strstr(line, ": ");
      snprintf(buf, len, "%s", name ? g_strstrip(name + 2) : "");
    }
    break;
  }
  pclose(p);
}

static double cpu_load(App *app) {
  FILE *f = fopen("/proc/stat", "r");
  if (!f)
    return 0;
  unsigned long long user, nice, sys, idle, iowait, irq, softirq, steal;
  int n = fscanf(f, "cpu %llu %llu %llu %llu %llu %llu %llu %llu", &user, &nice,
                 &sys, &idle, &iowait, &irq, &softirq, &steal);
  fclose(f);
  if (n != 8)
    return 0;

  unsigned long long all_idle = idle + iowait;
  unsigned long long total =
      user + nice + sys + irq + softirq + steal + all_idle;
  unsigned long long d_idle = all_idle - app->prev_idle;
  unsigned long long d_total = total - app->prev_total;
  app->prev_idle = all_idle;
  app->prev_total = total;
  return d_total ? (double)(d_total - d_idle) / d_total : 0;
}

static void set_row(Row *row, double fraction, const char *fmt, ...) {
  fraction = CLAMP(fraction, 0, 1);
  gtk_level_bar_set_value(GTK_LEVEL_BAR(row->bar), fraction);

  char text[64];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(text, sizeof(text), fmt, ap);
  va_end(ap);
  gtk_label_set_text(GTK_LABEL(row->value), text);

  GtkWidget *widgets[] = {row->bar, row->value};
  for (int i = 0; i < 2; i++) {
    GtkStyleContext *ctx = gtk_widget_get_style_context(widgets[i]);
    if (fraction >= CRITICAL)
      gtk_style_context_add_class(ctx, "critical");
    else
      gtk_style_context_remove_class(ctx, "critical");
  }
}

static void set_temp(Row *row, const char *hwmon, int n, double limit) {
  char file[32];
  snprintf(file, sizeof(file), "temp%d_input", n);
  long milli = hwmon[0] ? read_long(hwmon, file, -1) : -1;
  if (milli < 0) {
    set_row(row, 0, "—");
    return;
  }
  snprintf(file, sizeof(file), "temp%d_crit", n);
  long crit = read_long(hwmon, file, 0);
  if (crit > 0)
    limit = crit / 1000.0;
  set_row(row, milli / 1000.0 / limit, "%.0f °C", milli / 1000.0);
}

static void update_memory(App *app) {
  FILE *f = fopen("/proc/meminfo", "r");
  if (!f)
    return;
  unsigned long total = 0, avail = 0;
  char line[128];
  while (fgets(line, sizeof(line), f)) {
    sscanf(line, "MemTotal: %lu", &total);
    sscanf(line, "MemAvailable: %lu", &avail);
  }
  fclose(f);
  double used = (total - avail) * 1024.0 / GIB, all = total * 1024.0 / GIB;
  set_row(&app->ram, all ? used / all : 0, "%.1f / %.0f GB", used, all);

  struct statvfs st;
  if (statvfs("/", &st) == 0) {
    double size = (double)st.f_blocks * st.f_frsize / GIB;
    double free = (double)st.f_bavail * st.f_frsize / GIB;
    set_row(&app->disk, size ? (size - free) / size : 0, "%.0f / %.0f GB",
            size - free, size);
  }
}

static gboolean update(gpointer data) {
  App *app = data;
  double load = cpu_load(app);
  set_row(&app->load, load, "%.0f %%", load * 100);
  set_temp(&app->cpu_temp, app->cpu_hwmon, 1, 95);

  set_temp(&app->gpu_edge, app->gpu_hwmon, 1, 100);
  set_temp(&app->gpu_junction, app->gpu_hwmon, 2, 110);
  set_temp(&app->gpu_mem, app->gpu_hwmon, 3, 105);
  if (app->gpu_hwmon[0]) {
    long rpm = read_long(app->gpu_hwmon, "fan1_input", 0);
    long rpm_max = read_long(app->gpu_hwmon, "fan1_max", 0);
    set_row(&app->gpu_fan, rpm_max ? (double)rpm / rpm_max : 0, "%ld obr/min",
            rpm);

    long uw = read_long(app->gpu_hwmon, "power1_average", -1);
    if (uw < 0)
      uw = read_long(app->gpu_hwmon, "power1_input", 0);
    long cap = read_long(app->gpu_hwmon, "power1_cap", 0);
    set_row(&app->gpu_power, cap ? (double)uw / cap : 0, "%.0f W", uw / 1e6);
  }

  update_memory(app);
  set_temp(&app->nvme_temp, app->nvme_hwmon, 1, 85);
  return G_SOURCE_CONTINUE;
}

static GtkWidget *label(const char *text, const char *class) {
  GtkWidget *l = gtk_label_new(text);
  gtk_style_context_add_class(gtk_widget_get_style_context(l), class);
  return l;
}

// [ name ][ detail ]
static GtkWidget *section(GtkWidget *parent, const char *title,
                          const char *detail) {
  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  gtk_style_context_add_class(gtk_widget_get_style_context(box), "section");

  GtkWidget *header = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_widget_set_halign(header, GTK_ALIGN_START);
  gtk_box_pack_start(GTK_BOX(header), label(title, "segment-dark"), FALSE,
                     FALSE, 0);
  gtk_box_pack_start(GTK_BOX(header), label("", "segment-arrow"), FALSE,
                     FALSE, 0);
  gtk_box_pack_start(GTK_BOX(header), label(detail, "segment-light"), FALSE,
                     FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box), header, FALSE, FALSE, 0);

  GtkWidget *rows = gtk_grid_new();
  gtk_style_context_add_class(gtk_widget_get_style_context(rows), "rows");
  gtk_grid_set_row_spacing(GTK_GRID(rows), 6);
  gtk_grid_set_column_spacing(GTK_GRID(rows), 18);
  gtk_box_pack_start(GTK_BOX(box), rows, FALSE, FALSE, 0);

  gtk_box_pack_start(GTK_BOX(parent), box, FALSE, FALSE, 0);
  return rows;
}

static Row row(GtkWidget *rows, const char *key) {
  int y = 0;
  while (gtk_grid_get_child_at(GTK_GRID(rows), 0, y))
    y++;

  GtkWidget *k = label(key, "key");
  gtk_label_set_xalign(GTK_LABEL(k), 0);
  gtk_label_set_width_chars(GTK_LABEL(k), 12);
  gtk_grid_attach(GTK_GRID(rows), k, 0, y, 1, 1);

  Row r = {.bar = gtk_level_bar_new(), .value = label("", "value")};
  // no low/high/full classes of the GTK theme, "critical" is set here
  gtk_level_bar_remove_offset_value(GTK_LEVEL_BAR(r.bar),
                                    GTK_LEVEL_BAR_OFFSET_LOW);
  gtk_level_bar_remove_offset_value(GTK_LEVEL_BAR(r.bar),
                                    GTK_LEVEL_BAR_OFFSET_HIGH);
  gtk_level_bar_remove_offset_value(GTK_LEVEL_BAR(r.bar),
                                    GTK_LEVEL_BAR_OFFSET_FULL);
  gtk_widget_set_valign(r.bar, GTK_ALIGN_CENTER);
  gtk_widget_set_hexpand(r.bar, TRUE);
  gtk_grid_attach(GTK_GRID(rows), r.bar, 1, y, 1, 1);

  gtk_label_set_xalign(GTK_LABEL(r.value), 1);
  gtk_label_set_width_chars(GTK_LABEL(r.value), 14);
  gtk_grid_attach(GTK_GRID(rows), r.value, 2, y, 1, 1);
  return r;
}

static gboolean quit(GtkWidget *w, GdkEvent *ev, gpointer data) {
  gtk_main_quit();
  return TRUE;
}

int main(int argc, char *argv[]) {
  App app = {0};
  cpu_load(&app);

  g_set_prgname("sway-sys-info");
  gtk_init(&argc, &argv);
  find_hwmons(&app);

  GtkCssProvider *css = gtk_css_provider_new();
  char *path =
      g_build_filename(g_get_user_config_dir(), "sway/modal/style.css", NULL);
  gtk_css_provider_load_from_path(css, path, NULL);
  g_free(path);
  gtk_style_context_add_provider_for_screen(
      gdk_screen_get_default(), GTK_STYLE_PROVIDER(css),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

  GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(window), "Informacje");
  gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
  gtk_window_set_resizable(GTK_WINDOW(window), FALSE);

  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  gtk_style_context_add_class(gtk_widget_get_style_context(box), "modal");

  char cpu[96] = "procesor", gpu[96] = "karta graficzna", ram[32],
       disk[96] = "";
  cpu_name(cpu, sizeof(cpu));
  gpu_name(gpu, sizeof(gpu));
  long mem_kb = 0;
  FILE *f = fopen("/proc/meminfo", "r");
  if (f) {
    if (fscanf(f, "MemTotal: %ld", &mem_kb) != 1)
      mem_kb = 0;
    fclose(f);
  }
  snprintf(ram, sizeof(ram), "%.0f GB", mem_kb * 1024.0 / GIB);
  read_line("/sys/class/nvme/nvme0/model", disk, sizeof(disk));
  if (!disk[0])
    snprintf(disk, sizeof(disk), "/");

  GtkWidget *rows = section(box, "procesor", cpu);
  app.load = row(rows, "obciążenie");
  app.cpu_temp = row(rows, "temperatura");

  rows = section(box, "grafika", gpu);
  app.gpu_edge = row(rows, "rdzeń");
  app.gpu_junction = row(rows, "hotspot");
  app.gpu_mem = row(rows, "vram");
  app.gpu_fan = row(rows, "wentylator");
  app.gpu_power = row(rows, "pobór mocy");

  rows = section(box, "pamięć", ram);
  app.ram = row(rows, "ram");

  rows = section(box, "dysk", disk);
  app.disk = row(rows, "zajęte");
  app.nvme_temp = row(rows, "temperatura");

  gtk_container_add(GTK_CONTAINER(window), box);
  update(&app);
  g_timeout_add(1000, update, &app);

  g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
  g_signal_connect(window, "key-press-event", G_CALLBACK(quit), NULL);
  g_signal_connect(window, "focus-out-event", G_CALLBACK(quit), NULL);

  gtk_widget_show_all(window);
  gtk_main();
  return 0;
}
