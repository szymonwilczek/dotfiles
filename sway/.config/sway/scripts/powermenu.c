#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>
#include <stdio.h>

#include "modal.h"

typedef struct {
  const char *name;
  const char *note;
  const char *command;
} Action;

static const Action ACTIONS[] = {
    {"Wyloguj", "zamyka sway", "swaymsg exit"},
    {"Uruchom ponownie", "restart systemu", "systemctl reboot"},
    {"Wyłącz", "wyłącza komputer", "systemctl poweroff"},
};
#define COUNT ((int)G_N_ELEMENTS(ACTIONS))

typedef struct {
  int selected;
  GtkWidget *list;
  GtkWidget *uptime;
  Modal modal;
} Menu;

static void apply(Menu *m) {
  modal_hide(&m->modal);
  g_spawn_command_line_async(ACTIONS[m->selected].command, NULL);
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
static GtkWidget *heading(const char *title, GtkWidget **subtitle) {
  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 10);
  add_class(box, "heading");
  gtk_box_pack_start(GTK_BOX(box), label(title, "title"), FALSE, FALSE, 0);
  *subtitle = label("", "subtitle");
  gtk_box_pack_start(GTK_BOX(box), *subtitle, FALSE, FALSE, 0);
  return box;
}

static gboolean on_click(GtkWidget *w, GdkEventButton *ev, gpointer data) {
  Menu *m = data;
  if (ev->button != GDK_BUTTON_PRIMARY)
    return FALSE;
  m->selected = GPOINTER_TO_INT(g_object_get_data(G_OBJECT(w), "index"));
  apply(m);
  return TRUE;
}

static void render(Menu *m) {
  GList *rows = gtk_container_get_children(GTK_CONTAINER(m->list));
  for (GList *r = rows; r; r = r->next)
    gtk_widget_destroy(r->data);
  g_list_free(rows);

  for (int i = 0; i < COUNT; i++) {
    GtkWidget *row = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 18);
    add_class(row, "stream");
    if (i == m->selected)
      add_class(row, "selected");

    GtkWidget *name = label(ACTIONS[i].name, "key");
    gtk_label_set_xalign(GTK_LABEL(name), 0);
    gtk_label_set_width_chars(GTK_LABEL(name), 20);
    gtk_box_pack_start(GTK_BOX(row), name, FALSE, FALSE, 0);

    GtkWidget *note = label(ACTIONS[i].note, "note");
    gtk_label_set_xalign(GTK_LABEL(note), 0);
    gtk_label_set_width_chars(GTK_LABEL(note), 18);
    gtk_box_pack_start(GTK_BOX(row), note, TRUE, TRUE, 0);

    GtkWidget *click = gtk_event_box_new();
    g_object_set_data(G_OBJECT(click), "index", GINT_TO_POINTER(i));
    g_signal_connect(click, "button-press-event", G_CALLBACK(on_click), m);
    gtk_container_add(GTK_CONTAINER(click), row);
    gtk_box_pack_start(GTK_BOX(m->list), click, FALSE, FALSE, 0);
  }
  gtk_widget_show_all(m->list);
}

static gboolean on_key(GtkWidget *w, GdkEventKey *ev, gpointer data) {
  Menu *m = data;
  switch (ev->keyval) {
  case GDK_KEY_Escape:
  case GDK_KEY_q:
    modal_hide(&m->modal);
    break;
  case GDK_KEY_j:
  case GDK_KEY_Down:
  case GDK_KEY_Tab:
    m->selected = (m->selected + 1) % COUNT;
    render(m);
    break;
  case GDK_KEY_k:
  case GDK_KEY_Up:
  case GDK_KEY_ISO_Left_Tab:
    m->selected = (m->selected + COUNT - 1) % COUNT;
    render(m);
    break;
  case GDK_KEY_Return:
  case GDK_KEY_KP_Enter:
  case GDK_KEY_l:
  case GDK_KEY_space:
    apply(m);
    break;
  }
  return TRUE;
}

// How long the system runs, read on each show
static void read_uptime(Menu *m) {
  double secs = 0;
  FILE *f = fopen("/proc/uptime", "r");
  if (f) {
    if (fscanf(f, "%lf", &secs) != 1)
      secs = 0;
    fclose(f);
  }
  long min = (long)secs / 60;
  char text[64];
  if (min >= 24 * 60)
    snprintf(text, sizeof(text), "działa %ld d %ld h", min / (24 * 60),
             min / 60 % 24);
  else if (min >= 60)
    snprintf(text, sizeof(text), "działa %ld h %ld min", min / 60, min % 60);
  else
    snprintf(text, sizeof(text), "działa %ld min", min);
  gtk_label_set_text(GTK_LABEL(m->uptime), text);
}

// From the first action on each show
static void on_show(gpointer data) {
  Menu *m = data;
  m->selected = 0;
  read_uptime(m);
  render(m);
}

int main(int argc, char *argv[]) {
  modal_init(&argc, &argv, "sway-powermenu");

  static Menu m;
  m.modal = (Modal){.on_show = on_show, .data = &m};
  GtkWidget *window = modal_window(&m.modal, "Zasilanie");

  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  add_class(box, "modal");

  GtkWidget *section = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  add_class(section, "section");
  gtk_box_pack_start(GTK_BOX(section), heading("Zasilanie", &m.uptime), FALSE,
                     FALSE, 0);

  m.list = gtk_box_new(GTK_ORIENTATION_VERTICAL, 6);
  add_class(m.list, "rows");
  gtk_box_pack_start(GTK_BOX(section), m.list, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box), section, FALSE, FALSE, 0);

  const char *keys[] = {"j/k", "Wybór",   "Enter", "Wykonaj",
                        "Esc", "Zamknij", NULL};
  gtk_box_pack_start(GTK_BOX(box), modal_hint(keys), FALSE, FALSE, 0);

  gtk_container_add(GTK_CONTAINER(window), box);
  g_signal_connect(window, "key-press-event", G_CALLBACK(on_key), &m);

  modal_run(&m.modal, "powermenu", argc, argv);
  return 0;
}
