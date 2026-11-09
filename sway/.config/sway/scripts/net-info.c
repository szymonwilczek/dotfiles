#include <arpa/inet.h>
#include <dirent.h>
#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <netdb.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include "modal.h"

#define GIB (1024.0 * 1024.0 * 1024.0)
#define MIB (1024.0 * 1024.0)
#define KIB 1024.0

typedef struct {
  GtkWidget *bar;
  GtkWidget *value;
} LevelRow;

typedef struct {
  GtkWidget *key;
  GtkWidget *value;
} TextRow;

typedef struct {
  char iface[32];
  char driver[32];
  char mac[32];
  char chip[128];
  int speed_mbps;
  int mtu;
  char duplex[16];

  // Routing
  char ip[128];
  char gateway[64];
  char dns[64];
  char tailscale[64];

  // Traffic rates
  unsigned long long prev_rx_bytes;
  unsigned long long prev_tx_bytes;
  GDateTime *prev_time;

  // Widgets
  Modal modal;
  guint timer_id;

  // Rows
  TextRow r_chip;
  TextRow r_mac;
  TextRow r_mtu;

  TextRow r_ip;
  TextRow r_gateway;
  TextRow r_dns;
  TextRow r_tailscale;

  LevelRow r_rx_rate;
  LevelRow r_tx_rate;

  TextRow r_totals;
  TextRow r_packets;
  TextRow r_errors;
  TextRow r_drops;

  TextRow r_ping_gw;
  TextRow r_ping_inet;
} NetApp;

static void add_class(GtkWidget *w, const char *class) {
  gtk_style_context_add_class(gtk_widget_get_style_context(w), class);
}

static GtkWidget *label(const char *text, const char *class) {
  GtkWidget *l = gtk_label_new(text);
  add_class(l, class);
  return l;
}

static unsigned long long read_ull(const char *path) {
  FILE *f = fopen(path, "r");
  if (!f)
    return 0;
  unsigned long long val = 0;
  if (fscanf(f, "%llu", &val) != 1)
    val = 0;
  fclose(f);
  return val;
}

static void read_str(const char *path, char *buf, size_t sz) {
  FILE *f = fopen(path, "r");
  if (!f) {
    buf[0] = '\0';
    return;
  }
  if (fgets(buf, sz, f))
    buf[strcspn(buf, "\r\n")] = '\0';
  else
    buf[0] = '\0';
  fclose(f);
  g_strstrip(buf);
}

static void find_default_route(char *iface, size_t isz, char *gw, size_t gsz) {
  iface[0] = '\0';
  gw[0] = '\0';
  FILE *f = fopen("/proc/net/route", "r");
  if (!f)
    return;
  char line[256];
  while (fgets(line, sizeof(line), f)) {
    char dev[32];
    unsigned long dest = 0, gaddr = 0;
    if (sscanf(line, "%31s %lx %lx", dev, &dest, &gaddr) == 3) {
      if (dest == 0) { // default route
        g_strlcpy(iface, dev, isz);
        struct in_addr in = {.s_addr = gaddr};
        g_strlcpy(gw, inet_ntoa(in), gsz);
        break;
      }
    }
  }
  fclose(f);
  if (!iface[0])
    g_strlcpy(iface, "enp42s0", isz);
}

static void find_ips(NetApp *app) {
  app->ip[0] = '\0';
  app->tailscale[0] = '\0';
  struct ifaddrs *ifaddr, *ifa;
  if (getifaddrs(&ifaddr) == -1)
    return;

  for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
    if (!ifa->ifa_addr || ifa->ifa_addr->sa_family != AF_INET)
      continue;
    char host[64];
    if (getnameinfo(ifa->ifa_addr, sizeof(struct sockaddr_in), host,
                    sizeof(host), NULL, 0, NI_NUMERICHOST) == 0) {
      if (!strcmp(ifa->ifa_name, app->iface)) {
        // Compute CIDR mask
        int cidr = 0;
        if (ifa->ifa_netmask) {
          uint32_t mask =
              ntohl(((struct sockaddr_in *)ifa->ifa_netmask)->sin_addr.s_addr);
          while (mask) {
            cidr += (mask & 1);
            mask >>= 1;
          }
        }
        snprintf(app->ip, sizeof(app->ip), "%s/%d", host, cidr);
      } else if (!strcmp(ifa->ifa_name, "tailscale0")) {
        g_strlcpy(app->tailscale, host, sizeof(app->tailscale));
      }
    }
  }
  freeifaddrs(ifaddr);
}

static void find_dns(char *buf, size_t sz) {
  buf[0] = '\0';
  FILE *f = fopen("/etc/resolv.conf", "r");
  if (!f)
    return;
  char line[128];
  while (fgets(line, sizeof(line), f)) {
    if (strncmp(line, "nameserver", 10) == 0) {
      char ns[64] = "";
      if (sscanf(line, "nameserver %63s", ns) == 1) {
        if (buf[0])
          g_strlcat(buf, ", ", sz);
        g_strlcat(buf, ns, sz);
      }
    }
  }
  fclose(f);
}

static void find_chip(NetApp *app) {
  app->chip[0] = '\0';
  FILE *p = popen("lspci -vmm 2>/dev/null", "r");
  if (!p)
    return;
  char line[256];
  char vendor[64] = "", dev[128] = "";
  gboolean is_eth = FALSE;

  while (fgets(line, sizeof(line), p)) {
    if (line[0] == '\n') {
      if (is_eth && dev[0])
        break;
      is_eth = FALSE;
      vendor[0] = '\0';
      dev[0] = '\0';
      continue;
    }
    if (strncmp(line, "Class:\t", 7) == 0 && strstr(line, "Ethernet"))
      is_eth = TRUE;
    else if (strncmp(line, "Vendor:\t", 8) == 0) {
      char *v = line + 8;
      sscanf(v, "%63s", vendor);
    } else if (strncmp(line, "Device:\t", 8) == 0) {
      char *d = line + 8;
      g_strlcpy(dev, d, sizeof(dev));
      g_strstrip(dev);
    }
  }
  pclose(p);

  if (is_eth && dev[0]) {
    const char *suffixes[] = {" PCI Express", " Gigabit Ethernet", " Ethernet",
                              " Controller",  " Adapter",          NULL};
    for (int i = 0; suffixes[i]; i++) {
      char *pos = strstr(dev, suffixes[i]);
      if (pos)
        *pos = '\0';
    }
    g_strstrip(dev);
    if (vendor[0])
      snprintf(app->chip, sizeof(app->chip), "%s %s", vendor, dev);
    else
      snprintf(app->chip, sizeof(app->chip), "%s", dev);
  } else {
    g_strlcpy(app->chip, "Ethernet", sizeof(app->chip));
  }
}

static void set_level_row(LevelRow *r, double fraction, const char *fmt, ...) {
  fraction = CLAMP(fraction, 0.0, 1.0);
  gtk_level_bar_set_value(GTK_LEVEL_BAR(r->bar), fraction);

  char text[64];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(text, sizeof(text), fmt, ap);
  va_end(ap);
  gtk_label_set_text(GTK_LABEL(r->value), text);
}

static void set_text_row(TextRow *r, gboolean alert, const char *fmt, ...) {
  char text[128];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(text, sizeof(text), fmt, ap);
  va_end(ap);
  gtk_label_set_text(GTK_LABEL(r->value), text);

  GtkStyleContext *ctx = gtk_widget_get_style_context(r->value);
  if (alert)
    gtk_style_context_add_class(ctx, "critical");
  else
    gtk_style_context_remove_class(ctx, "critical");
}

static void format_bytes(double b, char *out, size_t sz) {
  if (b >= GIB)
    snprintf(out, sz, "%.1f GB", b / GIB);
  else if (b >= MIB)
    snprintf(out, sz, "%.1f MB", b / MIB);
  else if (b >= KIB)
    snprintf(out, sz, "%.0f KB", b / KIB);
  else
    snprintf(out, sz, "%.0f B", b);
}

static void format_rate(double bps, char *out, size_t sz) {
  if (bps >= MIB)
    snprintf(out, sz, "%.2f MB/s", bps / MIB);
  else if (bps >= KIB)
    snprintf(out, sz, "%.1f KB/s", bps / KIB);
  else
    snprintf(out, sz, "%.0f B/s", bps);
}

// Background ping for LAN gateway and Internet
typedef struct {
  NetApp *app;
  char gw[64];
  double gw_ms;
  double inet_ms;
} PingTask;

static gboolean ping_done(gpointer data);

static gpointer ping_worker(gpointer data) {
  PingTask *pt = data;
  pt->gw_ms = -1;
  pt->inet_ms = -1;

  if (pt->gw[0]) {
    char cmd[128];
    snprintf(cmd, sizeof(cmd), "ping -c 1 -W 1 -q %s 2>/dev/null", pt->gw);
    FILE *p = popen(cmd, "r");
    if (p) {
      char line[128];
      while (fgets(line, sizeof(line), p)) {
        if (strstr(line, "min/avg/max")) {
          char *eq = strchr(line, '=');
          if (eq) {
            char *slash = strchr(eq, '/');
            if (slash)
              pt->gw_ms = g_ascii_strtod(slash + 1, NULL);
          }
        }
      }
      pclose(p);
    }
  }

  // Cloudflare DNS
  FILE *p = popen("ping -c 1 -W 1 -q 1.1.1.1 2>/dev/null", "r");
  if (p) {
    char line[128];
    while (fgets(line, sizeof(line), p)) {
      if (strstr(line, "min/avg/max")) {
        char *eq = strchr(line, '=');
        if (eq) {
          char *slash = strchr(eq, '/');
          if (slash)
            pt->inet_ms = g_ascii_strtod(slash + 1, NULL);
        }
      }
    }
    pclose(p);
  }
  g_idle_add(ping_done, pt);
  return NULL;
}

static gboolean ping_done(gpointer data) {
  PingTask *pt = data;
  NetApp *app = pt->app;

  if (pt->gw_ms >= 0)
    set_text_row(&app->r_ping_gw, FALSE, "%.1f ms", pt->gw_ms);
  else
    set_text_row(&app->r_ping_gw, TRUE, "timeout");

  if (pt->inet_ms >= 0)
    set_text_row(&app->r_ping_inet, FALSE, "%.1f ms", pt->inet_ms);
  else
    set_text_row(&app->r_ping_inet, TRUE, "timeout");

  g_free(pt);
  return G_SOURCE_REMOVE;
}

static void run_ping(NetApp *app) {
  set_text_row(&app->r_ping_gw, FALSE, "mierzenie...");
  set_text_row(&app->r_ping_inet, FALSE, "mierzenie...");

  PingTask *pt = g_new0(PingTask, 1);
  pt->app = app;
  g_strlcpy(pt->gw, app->gateway, sizeof(pt->gw));
  GThread *t = g_thread_new("ping_worker", ping_worker, pt);
  g_thread_unref(t);
}

static gboolean update(gpointer data) {
  NetApp *app = data;
  char path[300];

  // Dynamic traffic rate
  snprintf(path, sizeof(path), "/sys/class/net/%s/statistics/rx_bytes",
           app->iface);
  unsigned long long rx = read_ull(path);
  snprintf(path, sizeof(path), "/sys/class/net/%s/statistics/tx_bytes",
           app->iface);
  unsigned long long tx = read_ull(path);

  GDateTime *now = g_date_time_new_now_local();
  double dt = 1.0;
  if (app->prev_time) {
    GTimeSpan span = g_date_time_difference(now, app->prev_time);
    dt = span / 1000000.0;
    if (dt <= 0.05)
      dt = 1.0;
  }

  double rx_rate = (app->prev_rx_bytes && rx >= app->prev_rx_bytes)
                       ? (rx - app->prev_rx_bytes) / dt
                       : 0;
  double tx_rate = (app->prev_tx_bytes && tx >= app->prev_tx_bytes)
                       ? (tx - app->prev_tx_bytes) / dt
                       : 0;

  app->prev_rx_bytes = rx;
  app->prev_tx_bytes = tx;
  if (app->prev_time)
    g_date_time_unref(app->prev_time);
  app->prev_time = now;

  double max_bytes_sec =
      (app->speed_mbps > 0 ? app->speed_mbps : 1000) * 1e6 / 8.0;

  char rx_buf[32], tx_buf[32];
  format_rate(rx_rate, rx_buf, sizeof(rx_buf));
  format_rate(tx_rate, tx_buf, sizeof(tx_buf));

  set_level_row(&app->r_rx_rate, rx_rate / max_bytes_sec, "%s", rx_buf);
  set_level_row(&app->r_tx_rate, tx_rate / max_bytes_sec, "%s", tx_buf);

  // totals
  char rx_tot[32], tx_tot[32];
  format_bytes((double)rx, rx_tot, sizeof(rx_tot));
  format_bytes((double)tx, tx_tot, sizeof(tx_tot));
  set_text_row(&app->r_totals, FALSE, "%s ↓  /  %s ↑", rx_buf[0] ? rx_tot : "—",
               tx_tot);

  // packets
  snprintf(path, sizeof(path), "/sys/class/net/%s/statistics/rx_packets",
           app->iface);
  unsigned long long rx_pkts = read_ull(path);
  snprintf(path, sizeof(path), "/sys/class/net/%s/statistics/tx_packets",
           app->iface);
  unsigned long long tx_pkts = read_ull(path);
  set_text_row(&app->r_packets, FALSE, "%llu rx  /  %llu tx", rx_pkts, tx_pkts);

  // errors and drops
  snprintf(path, sizeof(path), "/sys/class/net/%s/statistics/rx_errors",
           app->iface);
  unsigned long long rx_err = read_ull(path);
  snprintf(path, sizeof(path), "/sys/class/net/%s/statistics/tx_errors",
           app->iface);
  unsigned long long tx_err = read_ull(path);
  set_text_row(&app->r_errors, (rx_err > 0 || tx_err > 0),
               "%llu rx  /  %llu tx", rx_err, tx_err);

  snprintf(path, sizeof(path), "/sys/class/net/%s/statistics/rx_dropped",
           app->iface);
  unsigned long long rx_drop = read_ull(path);
  snprintf(path, sizeof(path), "/sys/class/net/%s/statistics/tx_dropped",
           app->iface);
  unsigned long long tx_drop = read_ull(path);
  set_text_row(&app->r_drops, FALSE, "%llu rx  /  %llu tx", rx_drop, tx_drop);

  return G_SOURCE_CONTINUE;
}

static GtkWidget *section(GtkWidget *parent, const char *title,
                          const char *detail) {
  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  add_class(box, "section");

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
  add_class(rows, "rows");
  gtk_grid_set_row_spacing(GTK_GRID(rows), 6);
  gtk_grid_set_column_spacing(GTK_GRID(rows), 18);
  gtk_box_pack_start(GTK_BOX(box), rows, FALSE, FALSE, 0);

  gtk_box_pack_start(GTK_BOX(parent), box, FALSE, FALSE, 0);
  return rows;
}

static LevelRow level_row(GtkWidget *rows, const char *key) {
  int y = 0;
  while (gtk_grid_get_child_at(GTK_GRID(rows), 0, y))
    y++;

  GtkWidget *k = label(key, "key");
  gtk_label_set_xalign(GTK_LABEL(k), 0);
  gtk_label_set_width_chars(GTK_LABEL(k), 14);
  gtk_grid_attach(GTK_GRID(rows), k, 0, y, 1, 1);

  LevelRow r = {.bar = gtk_level_bar_new(), .value = label("", "value")};
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

static TextRow text_row(GtkWidget *rows, const char *key) {
  int y = 0;
  while (gtk_grid_get_child_at(GTK_GRID(rows), 0, y))
    y++;

  GtkWidget *k = label(key, "key");
  gtk_label_set_xalign(GTK_LABEL(k), 0);
  gtk_label_set_width_chars(GTK_LABEL(k), 14);
  gtk_grid_attach(GTK_GRID(rows), k, 0, y, 1, 1);

  TextRow r = {.key = k, .value = label("", "value")};
  gtk_label_set_xalign(GTK_LABEL(r.value), 1);
  gtk_widget_set_hexpand(r.value, TRUE);
  gtk_grid_attach(GTK_GRID(rows), r.value, 1, y, 2, 1);
  return r;
}

static void on_show(gpointer data) {
  NetApp *app = data;
  find_default_route(app->iface, sizeof(app->iface), app->gateway,
                     sizeof(app->gateway));
  find_ips(app);
  find_dns(app->dns, sizeof(app->dns));

  set_text_row(&app->r_ip, FALSE, "%s", app->ip[0] ? app->ip : "—");
  set_text_row(&app->r_gateway, FALSE, "%s",
               app->gateway[0] ? app->gateway : "—");
  set_text_row(&app->r_dns, FALSE, "%s", app->dns[0] ? app->dns : "—");
  if (app->tailscale[0])
    set_text_row(&app->r_tailscale, FALSE, "%s (aktywny)", app->tailscale);
  else
    set_text_row(&app->r_tailscale, FALSE, "nieaktywny");

  update(app);
  run_ping(app);

  if (!app->timer_id)
    app->timer_id = g_timeout_add(1000, update, app);
}

static void on_hide(gpointer data) {
  NetApp *app = data;
  if (app->timer_id) {
    g_source_remove(app->timer_id);
    app->timer_id = 0;
  }
}

static gboolean on_key(GtkWidget *w, GdkEventKey *ev, gpointer data) {
  NetApp *app = data;
  switch (ev->keyval) {
  case GDK_KEY_Escape:
  case GDK_KEY_q:
    modal_hide(&app->modal);
    break;
  case GDK_KEY_r:
    update(app);
    run_ping(app);
    break;
  }
  return TRUE;
}

int main(int argc, char *argv[]) {
  static NetApp app = {0};

  modal_init(&argc, &argv, "sway-net-info");

  find_default_route(app.iface, sizeof(app.iface), app.gateway,
                     sizeof(app.gateway));
  find_chip(&app);

  char path[300];
  snprintf(path, sizeof(path), "/sys/class/net/%s/address", app.iface);
  read_str(path, app.mac, sizeof(app.mac));

  snprintf(path, sizeof(path), "/sys/class/net/%s/speed", app.iface);
  app.speed_mbps = (int)read_ull(path);

  snprintf(path, sizeof(path), "/sys/class/net/%s/duplex", app.iface);
  read_str(path, app.duplex, sizeof(app.duplex));

  snprintf(path, sizeof(path), "/sys/class/net/%s/mtu", app.iface);
  app.mtu = (int)read_ull(path);

  char drv_link[320];
  snprintf(path, sizeof(path), "/sys/class/net/%s/device/driver", app.iface);
  ssize_t len = readlink(path, drv_link, sizeof(drv_link) - 1);
  if (len > 0) {
    drv_link[len] = '\0';
    g_strlcpy(app.driver, g_path_get_basename(drv_link), sizeof(app.driver));
  } else {
    g_strlcpy(app.driver, "ethernet", sizeof(app.driver));
  }

  app.modal = (Modal){.on_show = on_show, .on_hide = on_hide, .data = &app};
  GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  app.modal.window = window;
  gtk_window_set_title(GTK_WINDOW(window), "Statystyki sieci");
  gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
  gtk_window_set_resizable(GTK_WINDOW(window), FALSE);
  g_signal_connect(window, "delete-event", G_CALLBACK(modal_on_delete),
                   &app.modal);

  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  add_class(box, "modal");

  char iface_hdr[160];
  snprintf(iface_hdr, sizeof(iface_hdr), "%s · %d Mb/s %s", app.iface,
           app.speed_mbps > 0 ? app.speed_mbps : 1000,
           app.duplex[0] ? app.duplex : "full");
  GtkWidget *s1 = section(box, "interfejs", iface_hdr);
  app.r_chip = text_row(s1, "kontroler");
  set_text_row(&app.r_chip, FALSE, "%s (%s)", app.chip, app.driver);
  app.r_mac = text_row(s1, "adres mac");
  set_text_row(&app.r_mac, FALSE, "%s", app.mac[0] ? app.mac : "—");
  app.r_mtu = text_row(s1, "mtu");
  set_text_row(&app.r_mtu, FALSE, "%d B", app.mtu ? app.mtu : 1500);

  GtkWidget *s2 = section(box, "adresowanie", "stos ipv4 & routing");
  app.r_ip = text_row(s2, "ipv4");
  app.r_gateway = text_row(s2, "brama domyślna");
  app.r_dns = text_row(s2, "serwery dns");
  app.r_tailscale = text_row(s2, "tailscale vpn");

  GtkWidget *s3 = section(box, "ruch na żywo", "przepustowość");
  app.r_rx_rate = level_row(s3, "odbieranie (rx)");
  app.r_tx_rate = level_row(s3, "wysyłanie (tx)");

  GtkWidget *s4 = section(box, "liczniki jądra", "od rozruchu systemu");
  app.r_totals = text_row(s4, "przesłano bajtów");
  app.r_packets = text_row(s4, "pakiety");
  app.r_errors = text_row(s4, "błędy (errors)");
  app.r_drops = text_row(s4, "odrzucone (drops)");

  GtkWidget *s5 = section(box, "diagnostyka", "opóźnienie rtt");
  app.r_ping_gw = text_row(s5, "ping brama");
  app.r_ping_inet = text_row(s5, "ping 1.1.1.1");

  gtk_container_add(GTK_CONTAINER(window), box);
  g_signal_connect(window, "key-press-event", G_CALLBACK(on_key), &app);

  modal_run(&app.modal, "net-info", argc, argv);
  return 0;
}
