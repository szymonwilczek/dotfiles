#include <dirent.h>
#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/statvfs.h>
#include <unistd.h>

typedef struct {
  char cpu_hwmon[256];
  char gpu_hwmon[256];
  char ssd_hwmon[256];
  char cpu_name[128];
  char gpu_name[128];
  unsigned long long prev_idle;
  unsigned long long prev_total;
  GtkWidget *label;
} AppData;

static void detect_hardware(AppData *app) {
  app->cpu_hwmon[0] = '\0';
  app->gpu_hwmon[0] = '\0';
  app->ssd_hwmon[0] = '\0';
  strcpy(app->cpu_name, "Procesor");
  strcpy(app->gpu_name, "Karta Graficzna");

  // CPU
  FILE *fc = fopen("/proc/cpuinfo", "r");
  if (fc) {
    char line[256];
    while (fgets(line, sizeof(line), fc)) {
      if (strncmp(line, "model name", 10) == 0) {
        char *colon = strchr(line, ':');
        if (colon) {
          colon++;
          while (*colon == ' ' || *colon == '\t')
            colon++;
          colon[strcspn(colon, "\r\n")] = 0;
          char *sub = strstr(colon, " 8-Core");
          if (sub)
            *sub = '\0';
          sub = strstr(colon, " with");
          if (sub)
            *sub = '\0';
          snprintf(app->cpu_name, sizeof(app->cpu_name), "%s", colon);
        }
        break;
      }
    }
    fclose(fc);
  }

  // GPU
  FILE *fg = popen("lspci 2>/dev/null | grep -iE 'vga|3d' | sed -n "
                   "'s/.*\\[\\(Radeon[^]]*\\)\\].*/\\1/p'",
                   "r");
  if (fg) {
    char gbuf[128] = "";
    if (fgets(gbuf, sizeof(gbuf), fg)) {
      gbuf[strcspn(gbuf, "\r\n")] = 0;
      if (strlen(gbuf) > 0) {
        snprintf(app->gpu_name, sizeof(app->gpu_name), "AMD %s", gbuf);
      }
    }
    pclose(fg);
  }

  if (strcmp(app->gpu_name, "Karta Graficzna") == 0) {
    FILE *fg2 =
        popen("lspci 2>/dev/null | grep -iE 'vga|3d' | cut -d: -f3", "r");
    if (fg2) {
      char gbuf2[128] = "";
      if (fgets(gbuf2, sizeof(gbuf2), fg2)) {
        gbuf2[strcspn(gbuf2, "\r\n")] = 0;
        char *clean = gbuf2;
        while (*clean == ' ' || *clean == '\t')
          clean++;
        if (strlen(clean) > 0) {
          snprintf(app->gpu_name, sizeof(app->gpu_name), "%s", clean);
        }
      }
      pclose(fg2);
    }
  }

  // HWMon
  DIR *d = opendir("/sys/class/hwmon");
  if (d) {
    struct dirent *dir;
    while ((dir = readdir(d)) != NULL) {
      if (strncmp(dir->d_name, "hwmon", 5) == 0) {
        char name_path[512];
        snprintf(name_path, sizeof(name_path), "/sys/class/hwmon/%s/name",
                 dir->d_name);
        FILE *f = fopen(name_path, "r");
        if (f) {
          char name_buf[64] = "";
          if (fgets(name_buf, sizeof(name_buf), f)) {
            name_buf[strcspn(name_buf, "\r\n")] = 0;
            if (strcmp(name_buf, "k10temp") == 0 ||
                strcmp(name_buf, "coretemp") == 0) {
              snprintf(app->cpu_hwmon, sizeof(app->cpu_hwmon),
                       "/sys/class/hwmon/%s", dir->d_name);
            } else if (strcmp(name_buf, "amdgpu") == 0 ||
                       strcmp(name_buf, "nvidia") == 0) {
              snprintf(app->gpu_hwmon, sizeof(app->gpu_hwmon),
                       "/sys/class/hwmon/%s", dir->d_name);
            } else if (strcmp(name_buf, "nvme") == 0 ||
                       strncmp(name_buf, "sd", 2) == 0) {
              snprintf(app->ssd_hwmon, sizeof(app->ssd_hwmon),
                       "/sys/class/hwmon/%s", dir->d_name);
            }
          }
          fclose(f);
        }
      }
    }
    closedir(d);
  }
}

static long read_sysfs_int(const char *path) {
  FILE *f = fopen(path, "r");
  if (!f)
    return 0;
  long val = 0;
  fscanf(f, "%ld", &val);
  fclose(f);
  return val;
}

static float calc_cpu_usage(AppData *app) {
  FILE *f = fopen("/proc/stat", "r");
  if (!f)
    return 0.0f;

  char user_str[32];
  unsigned long long user, nice, system, idle, iowait, irq, softirq, steal;
  if (fscanf(f, "%s %llu %llu %llu %llu %llu %llu %llu %llu", user_str, &user,
             &nice, &system, &idle, &iowait, &irq, &softirq, &steal) < 9) {
    fclose(f);
    return 0.0f;
  }
  fclose(f);

  unsigned long long total_idle = idle + iowait;
  unsigned long long total =
      user + nice + system + idle + iowait + irq + softirq + steal;

  unsigned long long diff_idle = total_idle - app->prev_idle;
  unsigned long long diff_total = total - app->prev_total;

  app->prev_idle = total_idle;
  app->prev_total = total;

  if (diff_total == 0)
    return 0.0f;
  return (float)(diff_total - diff_idle) / diff_total * 100.0f;
}

static void get_ram_info(float *used_gb, float *total_gb, int *percent) {
  FILE *f = fopen("/proc/meminfo", "r");
  if (!f)
    return;

  unsigned long total_kb = 0, avail_kb = 0;
  char line[128];
  while (fgets(line, sizeof(line), f)) {
    if (strncmp(line, "MemTotal:", 9) == 0) {
      sscanf(line + 9, "%lu", &total_kb);
    } else if (strncmp(line, "MemAvailable:", 13) == 0) {
      sscanf(line + 13, "%lu", &avail_kb);
    }
  }
  fclose(f);

  unsigned long used_kb = total_kb - avail_kb;
  *total_gb = total_kb / (1024.0f * 1024.0f);
  *used_gb = used_kb / (1024.0f * 1024.0f);
  *percent = (int)((used_kb * 100.0f) / (total_kb > 0 ? total_kb : 1));
}

static void get_ssd_storage(float *used_gb, float *total_gb, int *percent) {
  struct statvfs st;
  if (statvfs("/", &st) == 0) {
    unsigned long long total_bytes =
        (unsigned long long)st.f_blocks * st.f_frsize;
    unsigned long long free_bytes =
        (unsigned long long)st.f_bavail * st.f_frsize;
    unsigned long long used_bytes = total_bytes - free_bytes;

    *total_gb = total_bytes / (1024.0f * 1024.0f * 1024.0f);
    *used_gb = used_bytes / (1024.0f * 1024.0f * 1024.0f);
    *percent =
        (int)((used_bytes * 100.0f) / (total_bytes > 0 ? total_bytes : 1));
  } else {
    *used_gb = 0.0f;
    *total_gb = 0.0f;
    *percent = 0;
  }
}

static gboolean update_stats_cb(gpointer user_data) {
  AppData *app = (AppData *)user_data;

  float cpu_usage = calc_cpu_usage(app);

  char path[512];
  snprintf(path, sizeof(path), "%s/temp1_input",
           app->cpu_hwmon[0] ? app->cpu_hwmon : "/sys/class/hwmon/hwmon2");
  float cpu_temp = read_sysfs_int(path) / 1000.0f;

  snprintf(path, sizeof(path), "%s/temp1_input",
           app->gpu_hwmon[0] ? app->gpu_hwmon : "/sys/class/hwmon/hwmon1");
  float gpu_edge = read_sysfs_int(path) / 1000.0f;

  snprintf(path, sizeof(path), "%s/temp2_input",
           app->gpu_hwmon[0] ? app->gpu_hwmon : "/sys/class/hwmon/hwmon1");
  float gpu_junc = read_sysfs_int(path) / 1000.0f;

  snprintf(path, sizeof(path), "%s/temp3_input",
           app->gpu_hwmon[0] ? app->gpu_hwmon : "/sys/class/hwmon/hwmon1");
  float gpu_vram = read_sysfs_int(path) / 1000.0f;

  snprintf(path, sizeof(path), "%s/fan1_input",
           app->gpu_hwmon[0] ? app->gpu_hwmon : "/sys/class/hwmon/hwmon1");
  long gpu_fan = read_sysfs_int(path);

  snprintf(path, sizeof(path), "%s/power1_average",
           app->gpu_hwmon[0] ? app->gpu_hwmon : "/sys/class/hwmon/hwmon1");
  long p_raw = read_sysfs_int(path);
  if (p_raw == 0) {
    snprintf(path, sizeof(path), "%s/power1_input",
             app->gpu_hwmon[0] ? app->gpu_hwmon : "/sys/class/hwmon/hwmon1");
    p_raw = read_sysfs_int(path);
  }
  float gpu_power = p_raw / 1000000.0f;

  float ram_used, ram_total;
  int ram_pct;
  get_ram_info(&ram_used, &ram_total, &ram_pct);

  float ssd_used, ssd_total;
  int ssd_pct;
  get_ssd_storage(&ssd_used, &ssd_total, &ssd_pct);

  char markup[4096];
  snprintf(markup, sizeof(markup),
           "<tt>"
           "<b><span color='#4c7899'>PROCESOR</span></b>      ::  <span "
           "color='#cccccc'>%s</span>\n"
           "<span "
           "color='#333333'>--------------------------------------------</"
           "span>\n"
           "OBCIĄŻENIE    ::  <b>%.1f%%</b>\n"
           "TEMPERATURA   ::  <b>%.1f°C</b>\n\n"
           "<b><span color='#1ed760'>GRAFIKA</span></b>       ::  <span "
           "color='#cccccc'>%s</span>\n"
           "<span "
           "color='#333333'>--------------------------------------------</"
           "span>\n"
           "RDZEŃ (EDGE)  ::  <b>%.1f°C</b>  (JUNCTION: %.1f°C)\n"
           "PAMIĘĆ VRAM   ::  <b>%.1f°C</b>\n"
           "WENTYLATORY   ::  <b>%ld RPM</b>\n"
           "POBÓR MOCY    ::  <b>%.1f W</b>\n\n"
           "<b><span color='#e5c07b'>PAMIĘĆ I DYSK</span></b>\n"
           "<span "
           "color='#333333'>--------------------------------------------</"
           "span>\n"
           "PAMIĘĆ RAM    ::  <b>%.1f GB / %.1f GB (%d%%)</b>\n"
           "DYSK SSD      ::  <b>%.1f GB / %.1f GB (%d%%)</b></tt>",
           app->cpu_name, cpu_usage, cpu_temp, app->gpu_name, gpu_edge,
           gpu_junc, gpu_vram, gpu_fan, gpu_power, ram_used, ram_total, ram_pct,
           ssd_used, ssd_total, ssd_pct);

  gtk_label_set_markup(GTK_LABEL(app->label), markup);
  return TRUE;
}

static gboolean on_key_press(GtkWidget *widget, GdkEventKey *event,
                             gpointer user_data) {
  gtk_main_quit();
  return TRUE;
}

static gboolean on_focus_out(GtkWidget *widget, GdkEventFocus *event,
                             gpointer user_data) {
  gtk_main_quit();
  return FALSE;
}

int main(int argc, char *argv[]) {
  gtk_init(&argc, &argv);

  AppData app;
  memset(&app, 0, sizeof(app));
  detect_hardware(&app);

  GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(window), "Informacje");
  gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
  gtk_window_set_position(GTK_WINDOW(window), GTK_WIN_POS_CENTER);
  gtk_window_set_resizable(GTK_WINDOW(window), FALSE);
  gtk_container_set_border_width(GTK_CONTAINER(window), 0);

  GtkCssProvider *css = gtk_css_provider_new();
  gtk_css_provider_load_from_data(css,
                                  "window {\n"
                                  "  background-color: #141418;\n"
                                  "  border: 2px solid #4c7899;\n"
                                  "  border-radius: 0px;\n"
                                  "}\n"
                                  "#main-box {\n"
                                  "  padding: 24px 32px;\n"
                                  "}\n",
                                  -1, NULL);

  gtk_style_context_add_provider_for_screen(
      gdk_screen_get_default(), GTK_STYLE_PROVIDER(css),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  gtk_widget_set_name(box, "main-box");

  app.label = gtk_label_new(NULL);
  gtk_label_set_xalign(GTK_LABEL(app.label), 0.0);
  gtk_box_pack_start(GTK_BOX(box), app.label, TRUE, TRUE, 0);

  gtk_container_add(GTK_CONTAINER(window), box);

  update_stats_cb(&app);

  g_timeout_add(350, update_stats_cb, &app);

  g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
  g_signal_connect(window, "key-press-event", G_CALLBACK(on_key_press), NULL);
  g_signal_connect(window, "focus-out-event", G_CALLBACK(on_focus_out), NULL);

  gtk_widget_show_all(window);
  gtk_main();

  return 0;
}
