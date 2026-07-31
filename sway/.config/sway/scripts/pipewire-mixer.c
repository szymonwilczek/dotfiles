#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define MAX_STREAMS 32

typedef struct {
  int id;
  char name[128];
  int volume;
  int muted;
} AudioStream;

typedef struct {
  AudioStream streams[MAX_STREAMS];
  int count;
  int selected_idx;
  GtkWidget *label;
} AppState;

static void parse_streams(AppState *app) {
  app->count = 0;
  FILE *fp = popen("pactl list sink-inputs 2>/dev/null", "r");
  if (!fp)
    return;

  char line[512];
  AudioStream current;
  memset(&current, 0, sizeof(current));
  int in_stream = 0;

  while (fgets(line, sizeof(line), fp)) {
    if (strstr(line, "odpływ wejścia") || strstr(line, "Sink Input #")) {
      if (in_stream && current.id > 0 && strlen(current.name) > 0) {
        if (strstr(current.name, "speech-dispatcher") == NULL &&
            app->count < MAX_STREAMS) {
          app->streams[app->count++] = current;
        }
      }
      memset(&current, 0, sizeof(current));
      sscanf(line, "%d", &current.id);
      in_stream = 1;
    } else if (in_stream) {
      if (strstr(line, "application.name = ")) {
        char *start = strchr(line, '"');
        if (start) {
          start++;
          char *end = strchr(start, '"');
          if (end)
            *end = '\0';
          snprintf(current.name, sizeof(current.name), "%s", start);
        }
      } else if (strstr(line, "media.name = ") && strlen(current.name) == 0) {
        char *start = strchr(line, '"');
        if (start) {
          start++;
          char *end = strchr(start, '"');
          if (end)
            *end = '\0';
          snprintf(current.name, sizeof(current.name), "%s", start);
        }
      } else if (strstr(line, "Wyciszenie:") || strstr(line, "Mute:")) {
        if (strstr(line, "tak") || strstr(line, "yes")) {
          current.muted = 1;
        } else {
          current.muted = 0;
        }
      } else if (strstr(line, "Poziom głośności:") || strstr(line, "Volume:")) {
        char *pct = strchr(line, '%');
        if (pct) {
          char *p = pct;
          while (p > line && *(p - 1) >= '0' && *(p - 1) <= '9')
            p--;
          sscanf(p, "%d", &current.volume);
        }
      }
    }
  }
  if (in_stream && current.id > 0 && strlen(current.name) > 0) {
    if (strstr(current.name, "speech-dispatcher") == NULL &&
        app->count < MAX_STREAMS) {
      app->streams[app->count++] = current;
    }
  }
  pclose(fp);

  if (app->selected_idx >= app->count) {
    app->selected_idx = app->count > 0 ? app->count - 1 : 0;
  }
}

static void update_display(AppState *app) {
  parse_streams(app);

  char markup[4096];
  int offset = 0;

  offset += snprintf(markup + offset, sizeof(markup) - offset, "<tt>");

  if (app->count == 0) {
    offset += snprintf(markup + offset, sizeof(markup) - offset,
                       "<span color='#777777'><i>Brak aktywnych strumieni "
                       "dźwięku</i></span>\n");
  } else {
    for (int i = 0; i < app->count; i++) {
      int is_selected = (i == app->selected_idx);
      AudioStream *s = &app->streams[i];

      char bar[32] = "";
      int blocks = s->volume / 10;
      if (blocks > 10)
        blocks = 10;
      for (int b = 0; b < 10; b++) {
        if (b < blocks)
          strcat(bar, "█");
        else
          strcat(bar, "░");
      }

      const char *prefix = is_selected ? " ▶ " : "   ";
      const char *name_color = is_selected ? "#4c7899" : "#cccccc";

      if (s->muted) {
        offset += snprintf(markup + offset, sizeof(markup) - offset,
                           "%s<b><span color='%s'>%-16s</span></b>  "
                           "[WYCISZONE]  <span color='#666666'>%d%%</span>\n",
                           prefix, name_color, s->name, s->volume);
      } else {
        offset += snprintf(
            markup + offset, sizeof(markup) - offset,
            "%s<b><span color='%s'>%-16s</span></b>  [%s]  <b>%d%%</b>\n",
            prefix, name_color, s->name, bar, s->volume);
      }
    }
  }

  offset += snprintf(markup + offset, sizeof(markup) - offset, "</tt>");

  gtk_label_set_markup(GTK_LABEL(app->label), markup);
}

static gboolean on_key_press(GtkWidget *widget, GdkEventKey *event,
                             gpointer user_data) {
  AppState *app = (AppState *)user_data;

  switch (event->keyval) {
  case GDK_KEY_j:
  case GDK_KEY_Down:
    if (app->count > 0) {
      app->selected_idx = (app->selected_idx + 1) % app->count;
      update_display(app);
    }
    return TRUE;

  case GDK_KEY_k:
  case GDK_KEY_Up:
    if (app->count > 0) {
      app->selected_idx = (app->selected_idx - 1 + app->count) % app->count;
      update_display(app);
    }
    return TRUE;

  case GDK_KEY_l:
  case GDK_KEY_Right:
    if (app->count > 0 && app->selected_idx < app->count) {
      char cmd[256];
      snprintf(cmd, sizeof(cmd), "pactl set-sink-input-volume %d +5%%",
               app->streams[app->selected_idx].id);
      system(cmd);
      update_display(app);
    }
    return TRUE;

  case GDK_KEY_h:
  case GDK_KEY_Left:
    if (app->count > 0 && app->selected_idx < app->count) {
      char cmd[256];
      snprintf(cmd, sizeof(cmd), "pactl set-sink-input-volume %d -5%%",
               app->streams[app->selected_idx].id);
      system(cmd);
      update_display(app);
    }
    return TRUE;

  case GDK_KEY_m:
    if (app->count > 0 && app->selected_idx < app->count) {
      char cmd[256];
      snprintf(cmd, sizeof(cmd), "pactl set-sink-input-mute %d toggle",
               app->streams[app->selected_idx].id);
      system(cmd);
      update_display(app);
    }
    return TRUE;

  case GDK_KEY_Escape:
  default:
    gtk_main_quit();
    return TRUE;
  }
}

static gboolean on_focus_out(GtkWidget *widget, GdkEventFocus *event,
                             gpointer user_data) {
  gtk_main_quit();
  return FALSE;
}

int main(int argc, char *argv[]) {
  gtk_init(&argc, &argv);

  AppState app;
  memset(&app, 0, sizeof(app));

  GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(window), "Mikser dźwięku");
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

  update_display(&app);

  g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
  g_signal_connect(window, "key-press-event", G_CALLBACK(on_key_press), &app);
  g_signal_connect(window, "focus-out-event", G_CALLBACK(on_focus_out), &app);

  gtk_widget_show_all(window);
  gtk_main();

  return 0;
}
