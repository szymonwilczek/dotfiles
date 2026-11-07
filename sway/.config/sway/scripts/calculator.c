#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "modal.h"

typedef struct {
  GtkWidget *entry;
  GtkWidget *result_label;
  GtkWidget *result_box;
  Modal modal;
  guint debounce_tag;
  char last_result[512];
  char last_expr[512];
  gboolean has_result;
} Calc;

static void add_class(GtkWidget *w, const char *class) {
  gtk_style_context_add_class(gtk_widget_get_style_context(w), class);
}

static GtkWidget *label(const char *text, const char *class) {
  GtkWidget *l = gtk_label_new(text);
  add_class(l, class);
  return l;
}

static GtkWidget *heading(const char *title, const char *subtitle) {
  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 10);
  add_class(box, "heading");
  gtk_box_pack_start(GTK_BOX(box), label(title, "title"), FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box), label(subtitle, "subtitle"), FALSE, FALSE,
                     0);
  return box;
}

static const char *get_qalc(void) {
  static const char *resolved = NULL;
  static char path[512];
  if (resolved)
    return resolved;
  const char *home = g_get_home_dir();
  snprintf(path, sizeof(path), "%s/.local/bin/qalc", home);
  if (access(path, X_OK) == 0)
    resolved = path;
  else
    resolved = "qalc";
  return resolved;
}

static void copy_to_clipboard(const char *text) {
  if (!text || !*text)
    return;
  char *escaped = g_shell_quote(text);
  char *cmd = g_strdup_printf("wl-copy -- %s", escaped);
  g_spawn_command_line_async(cmd, NULL);
  g_free(cmd);
  g_free(escaped);
}

static void evaluate(Calc *c) {
  const char *raw = gtk_entry_get_text(GTK_ENTRY(c->entry));
  if (!raw || !*raw) {
    gtk_label_set_text(GTK_LABEL(c->result_label), "");
    c->has_result = FALSE;
    c->last_result[0] = '\0';
    c->last_expr[0] = '\0';
    return;
  }

  char *trimmed = g_strdup(raw);
  g_strstrip(trimmed);
  if (!*trimmed) {
    g_free(trimmed);
    gtk_label_set_text(GTK_LABEL(c->result_label), "");
    c->has_result = FALSE;
    c->last_result[0] = '\0';
    c->last_expr[0] = '\0';
    return;
  }

  if (strcmp(trimmed, c->last_expr) == 0) {
    g_free(trimmed);
    if (c->has_result) {
      char *display = g_strdup_printf("= %s", c->last_result);
      gtk_label_set_text(GTK_LABEL(c->result_label), display);
      g_free(display);
    }
    return;
  }

  g_strlcpy(c->last_expr, trimmed, sizeof(c->last_expr));

  char *argv[] = {(char *)get_qalc(), "-m", "200", "-t", trimmed, NULL};
  char *out = NULL;
  int status = 0;
  gboolean ok = g_spawn_sync(NULL, argv, NULL, G_SPAWN_SEARCH_PATH, NULL, NULL,
                             &out, NULL, &status, NULL);
  g_free(trimmed);

  if (ok && WIFEXITED(status) && WEXITSTATUS(status) == 0 && out) {
    g_strstrip(out);
    if (*out) {
      g_strlcpy(c->last_result, out, sizeof(c->last_result));
      c->has_result = TRUE;
      char *display = g_strdup_printf("= %s", out);
      gtk_label_set_text(GTK_LABEL(c->result_label), display);
      g_free(display);
      g_free(out);
      return;
    }
  }

  if (out)
    g_free(out);
  c->has_result = FALSE;
  c->last_result[0] = '\0';
  gtk_label_set_text(GTK_LABEL(c->result_label), "");
}

static gboolean on_debounce(gpointer data) {
  Calc *c = data;
  c->debounce_tag = 0;
  evaluate(c);
  return G_SOURCE_REMOVE;
}

static void on_entry_changed(GtkEditable *editable, gpointer data) {
  Calc *c = data;
  if (c->debounce_tag > 0) {
    g_source_remove(c->debounce_tag);
    c->debounce_tag = 0;
  }
  const char *text = gtk_entry_get_text(GTK_ENTRY(c->entry));
  if (!text || !*text) {
    evaluate(c);
    return;
  }
  c->debounce_tag = g_timeout_add(30, on_debounce, c);
}

static gboolean on_key_press(GtkWidget *w, GdkEventKey *ev, gpointer data) {
  Calc *c = data;
  if (ev->keyval == GDK_KEY_Escape) {
    modal_hide(&c->modal);
    return TRUE;
  }
  if (ev->keyval == GDK_KEY_Return || ev->keyval == GDK_KEY_KP_Enter) {
    if (c->debounce_tag > 0) {
      g_source_remove(c->debounce_tag);
      c->debounce_tag = 0;
      evaluate(c);
    }
    if (c->has_result && c->last_result[0])
      copy_to_clipboard(c->last_result);
    modal_hide(&c->modal);
    return TRUE;
  }
  if (ev->keyval == GDK_KEY_Tab || ev->keyval == GDK_KEY_ISO_Left_Tab) {
    if (c->has_result && c->last_result[0]) {
      gtk_entry_set_text(GTK_ENTRY(c->entry), c->last_result);
      gtk_editable_set_position(GTK_EDITABLE(c->entry), -1);
    }
    return TRUE;
  }
  return FALSE;
}

static gboolean grab_focus_idle(gpointer data) {
  gtk_widget_grab_focus(GTK_WIDGET(data));
  return G_SOURCE_REMOVE;
}

static void on_show(gpointer data) {
  Calc *c = data;
  if (c->debounce_tag > 0) {
    g_source_remove(c->debounce_tag);
    c->debounce_tag = 0;
  }
  gtk_entry_set_text(GTK_ENTRY(c->entry), "");
  gtk_label_set_text(GTK_LABEL(c->result_label), "");
  c->has_result = FALSE;
  c->last_result[0] = '\0';
  c->last_expr[0] = '\0';
  g_idle_add(grab_focus_idle, c->entry);
}

static void on_hide(gpointer data) {
  Calc *c = data;
  if (c->debounce_tag > 0) {
    g_source_remove(c->debounce_tag);
    c->debounce_tag = 0;
  }
  gtk_entry_set_text(GTK_ENTRY(c->entry), "");
  gtk_label_set_text(GTK_LABEL(c->result_label), "");
  c->has_result = FALSE;
  c->last_result[0] = '\0';
  c->last_expr[0] = '\0';
}

int main(int argc, char *argv[]) {
  modal_init(&argc, &argv, "sway-calculator");

  static Calc c;
  c.modal = (Modal){.on_show = on_show, .on_hide = on_hide, .data = &c};
  GtkWidget *window = modal_window(&c.modal, "Kalkulator");
  gtk_widget_set_size_request(window, 440, -1);

  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  add_class(box, "modal");
  add_class(box, "calc-box");

  GtkWidget *head = heading("Kalkulator", "qalc");
  gtk_box_pack_start(GTK_BOX(box), head, FALSE, FALSE, 0);

  c.entry = gtk_entry_new();
  add_class(c.entry, "calc-entry");
  gtk_entry_set_placeholder_text(GTK_ENTRY(c.entry), "Wpisz działanie...");
  gtk_widget_set_margin_top(c.entry, 14);
  gtk_box_pack_start(GTK_BOX(box), c.entry, FALSE, FALSE, 0);

  c.result_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  add_class(c.result_box, "calc-result-row");
  c.result_label = label("", "calc-result-text");
  gtk_label_set_xalign(GTK_LABEL(c.result_label), 0.0);
  gtk_label_set_ellipsize(GTK_LABEL(c.result_label), PANGO_ELLIPSIZE_END);
  gtk_box_pack_start(GTK_BOX(c.result_box), c.result_label, TRUE, TRUE, 0);
  gtk_box_pack_start(GTK_BOX(box), c.result_box, FALSE, FALSE, 0);

  GtkWidget *hint =
      label("Enter: kopiuj  •  Tab: wstaw  •  Esc: zamknij", "calc-help");
  gtk_label_set_xalign(GTK_LABEL(hint), 0.5);
  gtk_box_pack_start(GTK_BOX(box), hint, FALSE, FALSE, 0);

  gtk_container_add(GTK_CONTAINER(window), box);
  gtk_window_set_focus(GTK_WINDOW(window), c.entry);

  g_signal_connect(c.entry, "changed", G_CALLBACK(on_entry_changed), &c);
  g_signal_connect(c.entry, "key-press-event", G_CALLBACK(on_key_press), &c);
  g_signal_connect(window, "key-press-event", G_CALLBACK(on_key_press), &c);

  modal_run(&c.modal, "calculator", argc, argv);
  return 0;
}
