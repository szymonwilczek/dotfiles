// A modal of sway/scripts that keeps running hidden between uses, so that
// it shows at once: modal.sh toggles it with SIGUSR1, sent to the pid it
// leaves in $XDG_RUNTIME_DIR/<name>.pid, as pkill takes longer than the
// whole of showing it
#pragma once

#include <glib-unix.h>
#include <gtk/gtk.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef struct {
  GtkWidget *window;
  void (*on_show)(gpointer data); // to read what it shows anew
  void (*on_hide)(gpointer data);
  gpointer data;
  char *pidfile;
} Modal;

static void modal_hide(Modal *m) {
  if (!gtk_widget_get_visible(m->window))
    return;
  gtk_widget_hide(m->window);
  if (m->on_hide)
    m->on_hide(m->data);
}

static void modal_show(Modal *m) {
  if (m->on_show)
    m->on_show(m->data);
  gtk_widget_show_all(m->window);
}

static gboolean modal_on_toggle(gpointer data) {
  Modal *m = data;
  if (gtk_widget_get_visible(m->window))
    modal_hide(m);
  else
    modal_show(m);
  return G_SOURCE_CONTINUE;
}

static gboolean modal_on_quit(gpointer data) {
  gtk_main_quit();
  return G_SOURCE_REMOVE;
}

static gboolean modal_on_focus_out(GtkWidget *w, GdkEventFocus *ev,
                                   gpointer data) {
  modal_hide(data);
  return FALSE;
}

static gboolean modal_on_delete(GtkWidget *w, GdkEvent *ev, gpointer data) {
  modal_hide(data);
  return TRUE;
}

// The CSS of the modals, before any widget is made
static void modal_init(int *argc, char ***argv, const char *app_id) {
  g_set_prgname(app_id);
  gtk_init(argc, argv);

  GtkCssProvider *css = gtk_css_provider_new();
  char *path =
      g_build_filename(g_get_user_config_dir(), "sway/modal/style.css", NULL);
  gtk_css_provider_load_from_path(css, path, NULL);
  g_free(path);
  gtk_style_context_add_provider_for_screen(
      gdk_screen_get_default(), GTK_STYLE_PROVIDER(css),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
}

static GtkWidget *modal_window(Modal *m, const char *title) {
  m->window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(m->window), title);
  gtk_window_set_decorated(GTK_WINDOW(m->window), FALSE);
  gtk_window_set_resizable(GTK_WINDOW(m->window), FALSE);
  g_signal_connect(m->window, "focus-out-event", G_CALLBACK(modal_on_focus_out),
                   m);
  g_signal_connect(m->window, "delete-event", G_CALLBACK(modal_on_delete), m);
  return m->window;
}

// Shown at once unless started with --hidden, as sway does at its start
static void modal_run(Modal *m, const char *name, int argc, char *argv[]) {
  char *pid = g_strdup_printf("%d\n", getpid());
  m->pidfile = g_strdup_printf("%s/%s.pid", g_get_user_runtime_dir(), name);
  g_file_set_contents(m->pidfile, pid, -1, NULL);
  g_free(pid);

  g_unix_signal_add(SIGUSR1, modal_on_toggle, m);
  g_unix_signal_add(SIGTERM, modal_on_quit, m);
  g_unix_signal_add(SIGINT, modal_on_quit, m);

  if (!(argc > 1 && !strcmp(argv[1], "--hidden")))
    modal_show(m);
  gtk_main();

  // Unless a newer one, started as this one quit, left its own
  char *now = NULL;
  if (g_file_get_contents(m->pidfile, &now, NULL, NULL) &&
      atoi(now) == getpid())
    unlink(m->pidfile);
  g_free(now);
}
