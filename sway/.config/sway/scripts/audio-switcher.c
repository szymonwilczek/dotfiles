#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>
#include <json-c/json.h>
#include <string.h>

#define MAX_SINKS 16

typedef struct {
  char name[256];
  char device[96];
  char nick[64];
} Sink;

typedef struct {
  Sink sinks[MAX_SINKS];
  int count;
  int selected;
  int current;
  GtkWidget *list;
} Switcher;

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

static const char *str(json_object *obj, const char *key) {
  json_object *v;
  if (!obj || !json_object_object_get_ex(obj, key, &v))
    return NULL;
  const char *s = json_object_get_string(v);
  return s && *s ? s : NULL;
}

// pactl -f json, as the text of pactl and wpctl is translated and decorated
static void read_sinks(Switcher *sw) {
  char *def = pactl("get-default-sink", NULL, NULL, NULL);
  if (def)
    g_strstrip(def);

  char *out = pactl("-f", "json", "list", "sinks");
  json_object *root = out ? json_tokener_parse(out) : NULL;
  g_free(out);

  size_t len = root ? json_object_array_length(root) : 0;
  for (size_t i = 0; i < len && sw->count < MAX_SINKS; i++) {
    json_object *in = json_object_array_get_idx(root, i), *props = NULL;
    json_object_object_get_ex(in, "properties", &props);
    const char *name = str(in, "name");
    if (!name)
      continue;

    Sink *s = &sw->sinks[sw->count];
    const char *device = str(props, "device.description");
    const char *nick = str(props, "node.nick");
    snprintf(s->name, sizeof(s->name), "%s", name);
    snprintf(s->device, sizeof(s->device), "%s",
             device                   ? device
             : str(in, "description") ? str(in, "description")
                                      : name);
    snprintf(s->nick, sizeof(s->nick), "%s", nick ? nick : "");
    if (def && !strcmp(name, def))
      sw->current = sw->selected = sw->count;
    sw->count++;
  }
  if (root)
    json_object_put(root);
  g_free(def);
}

static void apply(Switcher *sw) {
  const char *name = sw->sinks[sw->selected].name;
  g_free(pactl("set-default-sink", name, NULL, NULL));

  char *out = pactl("-f", "json", "list", "sink-inputs");
  json_object *root = out ? json_tokener_parse(out) : NULL;
  g_free(out);
  size_t len = root ? json_object_array_length(root) : 0;
  for (size_t i = 0; i < len; i++) {
    json_object *v;
    if (!json_object_object_get_ex(json_object_array_get_idx(root, i), "index",
                                   &v))
      continue;
    char id[16];
    snprintf(id, sizeof(id), "%d", json_object_get_int(v));
    g_free(pactl("move-sink-input", id, name, NULL));
  }
  if (root)
    json_object_put(root);
  gtk_main_quit();
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

static gboolean on_click(GtkWidget *w, GdkEventButton *ev, gpointer data) {
  Switcher *sw = data;
  if (ev->button != GDK_BUTTON_PRIMARY)
    return FALSE;
  sw->selected = GPOINTER_TO_INT(g_object_get_data(G_OBJECT(w), "index"));
  apply(sw);
  return TRUE;
}

static void render(Switcher *sw) {
  GList *rows = gtk_container_get_children(GTK_CONTAINER(sw->list));
  for (GList *r = rows; r; r = r->next)
    gtk_widget_destroy(r->data);
  g_list_free(rows);

  if (sw->count == 0) {
    GtkWidget *l = label("brak wyjść dźwięku", "note");
    gtk_label_set_xalign(GTK_LABEL(l), 0);
    gtk_box_pack_start(GTK_BOX(sw->list), l, FALSE, FALSE, 0);
  }

  for (int i = 0; i < sw->count; i++) {
    Sink *s = &sw->sinks[i];
    GtkWidget *row = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 18);
    add_class(row, "stream");
    if (i == sw->selected)
      add_class(row, "selected");

    GtkWidget *device = label(s->device, "key");
    gtk_label_set_xalign(GTK_LABEL(device), 0);
    gtk_label_set_width_chars(GTK_LABEL(device), 36);
    gtk_label_set_max_width_chars(GTK_LABEL(device), 36);
    gtk_label_set_ellipsize(GTK_LABEL(device), PANGO_ELLIPSIZE_END);
    gtk_box_pack_start(GTK_BOX(row), device, FALSE, FALSE, 0);

    GtkWidget *nick = label(s->nick, "note");
    gtk_label_set_xalign(GTK_LABEL(nick), 0);
    gtk_label_set_width_chars(GTK_LABEL(nick), 14);
    gtk_box_pack_start(GTK_BOX(row), nick, TRUE, TRUE, 0);

    GtkWidget *state = label(i == sw->current ? "domyślne" : "", "value");
    gtk_label_set_xalign(GTK_LABEL(state), 1);
    gtk_label_set_width_chars(GTK_LABEL(state), 9);
    gtk_box_pack_start(GTK_BOX(row), state, FALSE, FALSE, 0);

    GtkWidget *click = gtk_event_box_new();
    g_object_set_data(G_OBJECT(click), "index", GINT_TO_POINTER(i));
    g_signal_connect(click, "button-press-event", G_CALLBACK(on_click), sw);
    gtk_container_add(GTK_CONTAINER(click), row);
    gtk_box_pack_start(GTK_BOX(sw->list), click, FALSE, FALSE, 0);
  }
  gtk_widget_show_all(sw->list);
}

static gboolean on_key(GtkWidget *w, GdkEventKey *ev, gpointer data) {
  Switcher *sw = data;
  switch (ev->keyval) {
  case GDK_KEY_Escape:
  case GDK_KEY_q:
    gtk_main_quit();
    return TRUE;
  }
  if (sw->count == 0)
    return TRUE;

  switch (ev->keyval) {
  case GDK_KEY_j:
  case GDK_KEY_Down:
  case GDK_KEY_Tab:
    sw->selected = (sw->selected + 1) % sw->count;
    render(sw);
    break;
  case GDK_KEY_k:
  case GDK_KEY_Up:
  case GDK_KEY_ISO_Left_Tab:
    sw->selected = (sw->selected + sw->count - 1) % sw->count;
    render(sw);
    break;
  case GDK_KEY_Return:
  case GDK_KEY_KP_Enter:
  case GDK_KEY_l:
  case GDK_KEY_space:
    apply(sw);
    break;
  }
  return TRUE;
}

static gboolean on_focus_out(GtkWidget *w, GdkEventFocus *ev, gpointer data) {
  gtk_main_quit();
  return FALSE;
}

int main(int argc, char *argv[]) {
  g_set_prgname("sway-audio-switcher");
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
  gtk_window_set_title(GTK_WINDOW(window), "Wyjście dźwięku");
  gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
  gtk_window_set_resizable(GTK_WINDOW(window), FALSE);

  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  add_class(box, "modal");

  Switcher sw = {.list = gtk_box_new(GTK_ORIENTATION_VERTICAL, 6)};
  read_sinks(&sw);

  GtkWidget *section = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  add_class(section, "section");
  Sink *cur = sw.count ? &sw.sinks[sw.current] : NULL;
  gtk_box_pack_start(
      GTK_BOX(section),
      heading(cur ? cur->device : "brak wyjścia", cur ? cur->nick : ""), FALSE,
      FALSE, 0);

  add_class(sw.list, "rows");
  gtk_box_pack_start(GTK_BOX(section), sw.list, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box), section, FALSE, FALSE, 0);

  GtkWidget *hint = label("j/k wybór   enter ustaw   esc zamknij", "hint");
  gtk_label_set_xalign(GTK_LABEL(hint), 0);
  gtk_box_pack_start(GTK_BOX(box), hint, FALSE, FALSE, 0);

  gtk_container_add(GTK_CONTAINER(window), box);
  render(&sw);

  g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
  g_signal_connect(window, "key-press-event", G_CALLBACK(on_key), &sw);
  g_signal_connect(window, "focus-out-event", G_CALLBACK(on_focus_out), NULL);

  gtk_widget_show_all(window);
  gtk_main();
  return 0;
}
