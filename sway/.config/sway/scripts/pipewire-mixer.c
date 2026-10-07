#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>
#include <json-c/json.h>
#include <stdlib.h>
#include <string.h>

#define MAX_STREAMS 32
#define STEP 5

typedef struct {
  int id;
  char name[64];
  int volume;
  gboolean muted;
} Stream;

typedef struct {
  Stream streams[MAX_STREAMS];
  int count;
  int selected;
  GtkWidget *list;
} Mixer;

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

static const char *prop(json_object *props, const char *key) {
  json_object *v;
  if (!json_object_object_get_ex(props, key, &v))
    return NULL;
  const char *s = json_object_get_string(v);
  return s && *s ? s : NULL;
}

// Mean of the channels
static int volume(json_object *channels) {
  int sum = 0, n = 0;
  json_object_object_foreach(channels, key, ch) {
    (void)key;
    json_object *pct;
    if (json_object_object_get_ex(ch, "value_percent", &pct)) {
      sum += atoi(json_object_get_string(pct));
      n++;
    }
  }
  return n ? sum / n : 0;
}

// pactl -f json, as its text output is translated
static void read_streams(Mixer *m) {
  int selected_id = m->count ? m->streams[m->selected].id : -1;
  m->count = 0;

  char *out = pactl("-f", "json", "list", "sink-inputs");
  json_object *root = out ? json_tokener_parse(out) : NULL;
  g_free(out);
  if (!root)
    return;

  size_t len = json_object_array_length(root);
  for (size_t i = 0; i < len && m->count < MAX_STREAMS; i++) {
    json_object *in = json_object_array_get_idx(root, i), *v, *props = NULL;
    json_object_object_get_ex(in, "properties", &props);
    const char *name = prop(props, "application.name");
    if (!name)
      name = prop(props, "media.name");
    if (!name || g_str_has_prefix(name, "speech-dispatcher"))
      continue;

    Stream *s = &m->streams[m->count++];
    json_object_object_get_ex(in, "index", &v);
    s->id = json_object_get_int(v);
    snprintf(s->name, sizeof(s->name), "%s", name);
    const char *bin = prop(props, "application.process.binary");
    if (!strcmp(name, "Chromium") && bin && !g_str_has_prefix(bin, "chrom")) {
      snprintf(s->name, sizeof(s->name), "%s", bin);
      char *ext = strstr(s->name, ".bin");
      if (ext)
        *ext = '\0';
    }
    s->muted =
        json_object_object_get_ex(in, "mute", &v) && json_object_get_boolean(v);
    s->volume = json_object_object_get_ex(in, "volume", &v) ? volume(v) : 0;
  }
  json_object_put(root);

  m->selected = 0;
  for (int i = 0; i < m->count; i++)
    if (m->streams[i].id == selected_id)
      m->selected = i;
}

static void add_class(GtkWidget *w, const char *class) {
  gtk_style_context_add_class(gtk_widget_get_style_context(w), class);
}

static GtkWidget *label(const char *text, const char *class) {
  GtkWidget *l = gtk_label_new(text);
  add_class(l, class);
  return l;
}

// A title and a muted subtitle over a rule
static GtkWidget *heading(const char *title, const char *subtitle) {
  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 10);
  add_class(box, "heading");
  GtkWidget *t = label(title, "title");
  gtk_label_set_ellipsize(GTK_LABEL(t), PANGO_ELLIPSIZE_END);
  gtk_box_pack_start(GTK_BOX(box), t, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box), label(subtitle, "subtitle"), FALSE, FALSE,
                     0);
  return box;
}

static void render(Mixer *m) {
  GList *rows = gtk_container_get_children(GTK_CONTAINER(m->list));
  for (GList *r = rows; r; r = r->next)
    gtk_widget_destroy(r->data);
  g_list_free(rows);

  if (m->count == 0) {
    GtkWidget *l = label("brak odtwarzanych strumieni", "note");
    gtk_label_set_xalign(GTK_LABEL(l), 0);
    gtk_box_pack_start(GTK_BOX(m->list), l, FALSE, FALSE, 0);
  }

  for (int i = 0; i < m->count; i++) {
    Stream *s = &m->streams[i];
    GtkWidget *row = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 18);
    add_class(row, "stream");
    if (i == m->selected)
      add_class(row, "selected");

    GtkWidget *name = label(s->name, "key");
    gtk_label_set_xalign(GTK_LABEL(name), 0);
    gtk_label_set_width_chars(GTK_LABEL(name), 16);
    gtk_label_set_max_width_chars(GTK_LABEL(name), 16);
    gtk_label_set_ellipsize(GTK_LABEL(name), PANGO_ELLIPSIZE_END);
    gtk_box_pack_start(GTK_BOX(row), name, FALSE, FALSE, 0);

    GtkWidget *bar = gtk_level_bar_new();
    gtk_level_bar_remove_offset_value(GTK_LEVEL_BAR(bar),
                                      GTK_LEVEL_BAR_OFFSET_LOW);
    gtk_level_bar_remove_offset_value(GTK_LEVEL_BAR(bar),
                                      GTK_LEVEL_BAR_OFFSET_HIGH);
    gtk_level_bar_remove_offset_value(GTK_LEVEL_BAR(bar),
                                      GTK_LEVEL_BAR_OFFSET_FULL);
    gtk_level_bar_set_value(GTK_LEVEL_BAR(bar),
                            CLAMP(s->volume, 0, 100) / 100.0);
    gtk_widget_set_valign(bar, GTK_ALIGN_CENTER);
    if (s->muted)
      add_class(bar, "muted");
    gtk_box_pack_start(GTK_BOX(row), bar, TRUE, TRUE, 0);

    char text[16];
    snprintf(text, sizeof(text), "%d %%", s->volume);
    GtkWidget *value =
        label(s->muted ? "wyciszone" : text, s->muted ? "note" : "value");
    gtk_label_set_xalign(GTK_LABEL(value), 1);
    gtk_label_set_width_chars(GTK_LABEL(value), 9);
    gtk_box_pack_start(GTK_BOX(row), value, FALSE, FALSE, 0);

    gtk_box_pack_start(GTK_BOX(m->list), row, FALSE, FALSE, 0);
  }
  gtk_widget_show_all(m->list);
}

static gboolean refresh(gpointer data) {
  read_streams(data);
  render(data);
  return G_SOURCE_CONTINUE;
}

static void change_volume(Mixer *m, int delta) {
  Stream *s = &m->streams[m->selected];
  char id[16], vol[16];
  snprintf(id, sizeof(id), "%d", s->id);
  snprintf(vol, sizeof(vol), "%d%%", CLAMP(s->volume + delta, 0, 100));
  g_free(pactl("set-sink-input-volume", id, vol, NULL));
}

static void toggle_mute(Mixer *m) {
  char id[16];
  snprintf(id, sizeof(id), "%d", m->streams[m->selected].id);
  g_free(pactl("set-sink-input-mute", id, "toggle", NULL));
}

static gboolean on_key(GtkWidget *w, GdkEventKey *ev, gpointer data) {
  Mixer *m = data;
  switch (ev->keyval) {
  case GDK_KEY_Escape:
  case GDK_KEY_q:
    gtk_main_quit();
    return TRUE;
  }
  if (m->count == 0)
    return TRUE;

  switch (ev->keyval) {
  case GDK_KEY_j:
  case GDK_KEY_Down:
    m->selected = (m->selected + 1) % m->count;
    render(m);
    return TRUE;
  case GDK_KEY_k:
  case GDK_KEY_Up:
    m->selected = (m->selected + m->count - 1) % m->count;
    render(m);
    return TRUE;
  case GDK_KEY_l:
  case GDK_KEY_Right:
    change_volume(m, STEP);
    break;
  case GDK_KEY_h:
  case GDK_KEY_Left:
    change_volume(m, -STEP);
    break;
  case GDK_KEY_m:
    toggle_mute(m);
    break;
  default:
    return TRUE;
  }
  refresh(m);
  return TRUE;
}

static gboolean on_focus_out(GtkWidget *w, GdkEventFocus *ev, gpointer data) {
  gtk_main_quit();
  return FALSE;
}

// Device and short name of the default sink, for the heading
static void default_sink(char *device, char *nick, size_t len) {
  char *name = pactl("get-default-sink", NULL, NULL, NULL);
  char *out = name ? pactl("-f", "json", "list", "sinks") : NULL;
  json_object *root = out ? json_tokener_parse(out) : NULL;
  if (name)
    g_strstrip(name);

  size_t n = root ? json_object_array_length(root) : 0;
  for (size_t i = 0; i < n; i++) {
    json_object *sink = json_object_array_get_idx(root, i), *v, *props;
    if (!json_object_object_get_ex(sink, "name", &v) ||
        strcmp(json_object_get_string(v), name) ||
        !json_object_object_get_ex(sink, "properties", &props))
      continue;
    const char *d = prop(props, "device.description");
    const char *k = prop(props, "node.nick");
    snprintf(device, len, "%s", d ? d : name);
    snprintf(nick, len, "%s", k ? k : "");
    break;
  }
  if (root)
    json_object_put(root);
  g_free(out);
  g_free(name);
}

int main(int argc, char *argv[]) {
  g_set_prgname("sway-mixer");
  gtk_init(&argc, &argv);

  GtkCssProvider *css = gtk_css_provider_new();
  char *path =
      g_build_filename(g_get_user_config_dir(), "sway/modal/style.css", NULL);
  gtk_css_provider_load_from_path(css, path, NULL);
  g_free(path);
  gtk_style_context_add_provider_for_screen(
      gdk_screen_get_default(), GTK_STYLE_PROVIDER(css),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

  GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(window), "Mikser dźwięku");
  gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
  gtk_window_set_resizable(GTK_WINDOW(window), FALSE);

  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  add_class(box, "modal");

  GtkWidget *section = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  add_class(section, "section");
  char device[96] = "brak wyjścia", nick[96] = "";
  default_sink(device, nick, sizeof(device));
  gtk_box_pack_start(GTK_BOX(section), heading(device, nick), FALSE, FALSE, 0);

  Mixer m = {.list = gtk_box_new(GTK_ORIENTATION_VERTICAL, 6)};
  add_class(m.list, "rows");
  gtk_box_pack_start(GTK_BOX(section), m.list, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box), section, FALSE, FALSE, 0);

  GtkWidget *hint = label("j/k wybór   h/l głośność   m wycisz", "hint");
  gtk_label_set_xalign(GTK_LABEL(hint), 0);
  gtk_box_pack_start(GTK_BOX(box), hint, FALSE, FALSE, 0);

  gtk_container_add(GTK_CONTAINER(window), box);
  refresh(&m);
  g_timeout_add(1000, refresh, &m);

  g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
  g_signal_connect(window, "key-press-event", G_CALLBACK(on_key), &m);
  g_signal_connect(window, "focus-out-event", G_CALLBACK(on_focus_out), NULL);

  gtk_widget_show_all(window);
  gtk_main();
  return 0;
}
