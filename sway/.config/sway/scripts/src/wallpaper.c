// Picks the wallpaper of all outputs out of sway/wallpapers.list and draws it
// with a swaybg of its own, started over the one before, which is ended once
// the new one had the time to draw.
// Every wallpaper is decoded once, in the background, into a thumbnail
// and a copy as large as the largest output, so that showing them and swaybg
// starting take next to no time
#include <dirent.h>
#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>
#include <stdio.h>
#include <sys/stat.h>

#include "modal.h"

#define COLUMNS 4
#define ROWS 3 // shown at once, the rest scrolled to
#define THUMB_W 224
#define THUMB_H 126
#define SWAP_MS 1000 // left to a new swaybg to draw before the old one ends

typedef struct {
  char *path;
  char *thumb, *full; // in the cache, named after the path, size and mtime
  GtkWidget *cell, *frame, *image;
} Item;

typedef struct {
  GArray *items;
  int selected;
  int current;
  char *current_path;
  char *pending; // picked, still being decoded
  time_t list_mtime;
  int full_w, full_h;
  GHashTable *thumbs; // path -> GdkPixbuf, kept across rereads of the list
  GThreadPool *pool, *urgent;
  GPid swaybg;
  guint swap;
  GtkWidget *grid, *scroll, *subtitle, *name;
  Modal modal;
} Picker;

typedef struct {
  Picker *p;
  char *path, *thumb, *full;
  gboolean apply;
  GdkPixbuf *pixbuf; // the thumbnail, back to the main thread
} Job;

static char *list_path(void) {
  return g_build_filename(g_get_user_config_dir(), "sway/wallpapers.list",
                          NULL);
}

static char *state_path(void) {
  return g_build_filename(g_get_user_state_dir(), "sway/wallpaper", NULL);
}

// The largest pixbuf that covers w x h at the aspect of src, cut to it
static GdkPixbuf *cover(GdkPixbuf *src, int w, int h, gboolean crop) {
  int sw = gdk_pixbuf_get_width(src), sh = gdk_pixbuf_get_height(src);
  double f = MAX((double)w / sw, (double)h / sh);
  if (f >= 1 && !crop)
    return g_object_ref(src);
  int cw = MAX(1, (int)(sw * f + 0.5)), ch = MAX(1, (int)(sh * f + 0.5));
  GdkPixbuf *scaled = gdk_pixbuf_scale_simple(src, cw, ch, GDK_INTERP_BILINEAR);
  if (!crop)
    return scaled;
  GdkPixbuf *cut = gdk_pixbuf_new_subpixbuf(scaled, (cw - w) / 2, (ch - h) / 2,
                                            MIN(w, cw), MIN(h, ch));
  GdkPixbuf *out = gdk_pixbuf_copy(cut);
  g_object_unref(cut);
  g_object_unref(scaled);
  return out;
}

// Next to it first, as two of them may write it at once
static void save(GdkPixbuf *pixbuf, const char *path) {
  char *tmp = g_strdup_printf("%s.%p.tmp", path, (void *)g_thread_self());
  if (gdk_pixbuf_save(pixbuf, tmp, "png", NULL, "compression", "1", NULL))
    rename(tmp, path);
  else
    unlink(tmp);
  g_free(tmp);
}

static gboolean on_done(gpointer data);

// In a thread of the pool: what is not in the cache is decoded into it
static void work(gpointer data, gpointer user_data) {
  Job *j = data;
  gboolean has_full = g_file_test(j->full, G_FILE_TEST_EXISTS);
  j->pixbuf = has_full ? gdk_pixbuf_new_from_file(j->thumb, NULL) : NULL;
  if (!j->pixbuf) {
    GdkPixbuf *src = gdk_pixbuf_new_from_file(j->path, NULL);
    if (src) {
      GdkPixbuf *turned = gdk_pixbuf_apply_embedded_orientation(src);
      GdkPixbuf *full = cover(turned, j->p->full_w, j->p->full_h, FALSE);
      j->pixbuf = cover(full, THUMB_W, THUMB_H, TRUE);
      save(full, j->full);
      save(j->pixbuf, j->thumb);
      g_object_unref(full);
      g_object_unref(turned);
      g_object_unref(src);
    }
  }
  g_idle_add(on_done, j);
}

static void push(Picker *p, Item *it, gboolean apply) {
  Job *j = g_new0(Job, 1);
  *j = (Job){.p = p,
             .path = g_strdup(it->path),
             .thumb = g_strdup(it->thumb),
             .full = g_strdup(it->full),
             .apply = apply};
  g_thread_pool_push(apply ? p->urgent : p->pool, j, NULL);
}

// swaybg processes on this display but the one it started last,
// sway's own among them
static GList *other_swaybgs(Picker *p) {
  GList *pids = NULL;
  const char *display = g_getenv("WAYLAND_DISPLAY");
  char *want = g_strdup_printf("WAYLAND_DISPLAY=%s", display ? display : "");
  DIR *proc = opendir("/proc");
  struct dirent *e;
  while (proc && (e = readdir(proc))) {
    int pid = atoi(e->d_name);
    if (pid <= 0 || pid == p->swaybg)
      continue;
    char path[64], *comm = NULL, *env = NULL;
    gsize len = 0;
    snprintf(path, sizeof(path), "/proc/%d/comm", pid);
    if (g_file_get_contents(path, &comm, NULL, NULL) &&
        !strcmp(g_strstrip(comm), "swaybg")) {
      snprintf(path, sizeof(path), "/proc/%d/environ", pid);
      if (g_file_get_contents(path, &env, &len, NULL))
        for (gsize i = 0; i < len; i += strlen(env + i) + 1)
          if (!strcmp(env + i, want)) {
            pids = g_list_prepend(pids, GINT_TO_POINTER(pid));
            break;
          }
    }
    g_free(comm);
    g_free(env);
  }
  if (proc)
    closedir(proc);
  g_free(want);
  return pids;
}

static gboolean on_swap(gpointer data) {
  Picker *p = data;
  p->swap = 0;
  GList *pids = other_swaybgs(p);
  for (GList *l = pids; l; l = l->next)
    kill(GPOINTER_TO_INT(l->data), SIGTERM);
  g_list_free(pids);
  return G_SOURCE_REMOVE;
}

static void on_swaybg_exit(GPid pid, gint status, gpointer data) {
  Picker *p = data;
  if (p->swaybg == pid)
    p->swaybg = 0;
  g_spawn_close_pid(pid);
}

// A new swaybg goes over the old one, which ends once it drew
static void draw(Picker *p, const char *image) {
  const char *argv[] = {"swaybg", "-o", "*", "-i", image, "-m", "fill", NULL};
  GPid pid;
  if (!g_spawn_async(NULL, (char **)argv, NULL,
                     G_SPAWN_SEARCH_PATH | G_SPAWN_DO_NOT_REAP_CHILD |
                         G_SPAWN_STDOUT_TO_DEV_NULL |
                         G_SPAWN_STDERR_TO_DEV_NULL,
                     NULL, NULL, &pid, NULL))
    return;
  p->swaybg = pid;
  g_child_watch_add(pid, on_swaybg_exit, p);
  if (p->swap)
    g_source_remove(p->swap);
  p->swap = g_timeout_add(SWAP_MS, on_swap, p);
}

static void add_class(GtkWidget *w, const char *class) {
  gtk_style_context_add_class(gtk_widget_get_style_context(w), class);
}

static void set_class(GtkWidget *w, const char *class, gboolean on) {
  GtkStyleContext *ctx = gtk_widget_get_style_context(w);
  if (on)
    gtk_style_context_add_class(ctx, class);
  else
    gtk_style_context_remove_class(ctx, class);
}

static GtkWidget *label(const char *text, const char *class) {
  GtkWidget *l = gtk_label_new(text);
  add_class(l, class);
  return l;
}

static Item *item(Picker *p, int i) {
  return &g_array_index(p->items, Item, i);
}

static void show_current(Picker *p) {
  char *base = p->current_path ? g_path_get_basename(p->current_path) : NULL;
  gtk_label_set_text(GTK_LABEL(p->subtitle), base ? base : "brak");
  g_free(base);
}

static void set_current(Picker *p, const char *path) {
  g_free(p->current_path);
  p->current_path = g_strdup(path);
  p->current = -1;
  for (guint i = 0; i < p->items->len; i++) {
    Item *it = item(p, i);
    gboolean on = path && !strcmp(it->path, path);
    if (on)
      p->current = i;
    set_class(it->frame, "current", on);
  }
  show_current(p);
}

static void on_done_apply(Picker *p, Job *j) {
  if (!p->pending || strcmp(p->pending, j->path))
    return;
  g_clear_pointer(&p->pending, g_free);
  if (g_file_test(j->full, G_FILE_TEST_EXISTS))
    draw(p, j->full);
}

static gboolean on_done(gpointer data) {
  Job *j = data;
  Picker *p = j->p;
  if (j->pixbuf) {
    g_hash_table_insert(p->thumbs, g_strdup(j->path), j->pixbuf);
    for (guint i = 0; i < p->items->len; i++)
      if (!strcmp(item(p, i)->path, j->path))
        gtk_image_set_from_pixbuf(GTK_IMAGE(item(p, i)->image), j->pixbuf);
  }
  if (j->apply)
    on_done_apply(p, j);
  g_free(j->path);
  g_free(j->thumb);
  g_free(j->full);
  g_free(j);
  return G_SOURCE_REMOVE;
}

// The wallpaper of path, from the cache when it is there already
static void apply_path(Picker *p, Item *it) {
  const char *path = it->path;
  set_current(p, path);
  char *state = state_path();
  char *dir = g_path_get_dirname(state);
  g_mkdir_with_parents(dir, 0755);
  g_file_set_contents(state, path, -1, NULL);
  g_free(dir);
  g_free(state);

  g_clear_pointer(&p->pending, g_free);
  if (g_file_test(it->full, G_FILE_TEST_EXISTS)) {
    draw(p, it->full);
    return;
  }
  p->pending = g_strdup(path);
  push(p, it, TRUE);
}

static void apply(Picker *p) {
  apply_path(p, item(p, p->selected));
  modal_hide(&p->modal);
}

// Scrolled no further than it takes to show the selected one whole
static void scroll_to_selected(Picker *p) {
  if (p->items->len == 0)
    return;
  GtkAdjustment *adj =
      gtk_scrolled_window_get_vadjustment(GTK_SCROLLED_WINDOW(p->scroll));
  GtkAllocation a;
  gtk_widget_get_allocation(item(p, p->selected)->cell, &a);
  if (a.height <= 1)
    return;
  double value = gtk_adjustment_get_value(adj);
  double page = gtk_adjustment_get_page_size(adj);
  if (a.y < value)
    gtk_adjustment_set_value(adj, a.y);
  else if (a.y + a.height > value + page)
    gtk_adjustment_set_value(adj, a.y + a.height - page);
}

static void select_item(Picker *p, int i) {
  if (p->items->len == 0)
    return;
  set_class(item(p, p->selected)->frame, "selected", FALSE);
  p->selected = CLAMP(i, 0, (int)p->items->len - 1);
  Item *it = item(p, p->selected);
  set_class(it->frame, "selected", TRUE);
  char *base = g_path_get_basename(it->path);
  gtk_label_set_text(GTK_LABEL(p->name), base);
  g_free(base);
  scroll_to_selected(p);
}

static gboolean on_click(GtkWidget *w, GdkEventButton *ev, gpointer data) {
  Picker *p = data;
  if (ev->button != GDK_BUTTON_PRIMARY)
    return FALSE;
  select_item(p, GPOINTER_TO_INT(g_object_get_data(G_OBJECT(w), "index")));
  apply(p);
  return TRUE;
}

// Its cache names, from what the file is and the size of the outputs
static void name_cache(Picker *p, Item *it, struct stat *st) {
  char *key = g_strdup_printf("%s\n%lld\n%lld", it->path,
                              (long long)st->st_size, (long long)st->st_mtime);
  char *sum = g_compute_checksum_for_string(G_CHECKSUM_SHA1, key, -1);
  char *dir =
      g_build_filename(g_get_user_cache_dir(), "sway", "wallpapers", NULL);
  g_mkdir_with_parents(dir, 0755);
  it->thumb = g_strdup_printf("%s/%s-%dx%d.png", dir, sum, THUMB_W, THUMB_H);
  it->full = g_strdup_printf("%s/%s-%dx%d.png", dir, sum, p->full_w, p->full_h);
  g_free(dir);
  g_free(sum);
  g_free(key);
}

static void clear_items(Picker *p) {
  for (guint i = 0; i < p->items->len; i++) {
    Item *it = item(p, i);
    g_free(it->path);
    g_free(it->thumb);
    g_free(it->full);
    gtk_widget_destroy(it->cell);
  }
  g_array_set_size(p->items, 0);
  p->selected = 0;
}

static void add_item(Picker *p, const char *path) {
  struct stat st;
  if (stat(path, &st) || !S_ISREG(st.st_mode))
    return;
  Item it = {.path = g_strdup(path)};
  name_cache(p, &it, &st);

  int i = p->items->len;
  GdkPixbuf *thumb = g_hash_table_lookup(p->thumbs, path);
  it.image = thumb ? gtk_image_new_from_pixbuf(thumb) : gtk_image_new();
  gtk_widget_set_size_request(it.image, THUMB_W, THUMB_H);
  it.frame = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  add_class(it.frame, "thumb");
  gtk_box_pack_start(GTK_BOX(it.frame), it.image, FALSE, FALSE, 0);

  it.cell = gtk_event_box_new();
  g_object_set_data(G_OBJECT(it.cell), "index", GINT_TO_POINTER(i));
  g_signal_connect(it.cell, "button-press-event", G_CALLBACK(on_click), p);
  gtk_container_add(GTK_CONTAINER(it.cell), it.frame);
  gtk_grid_attach(GTK_GRID(p->grid), it.cell, i % COLUMNS, i / COLUMNS, 1, 1);
  g_array_append_val(p->items, it);
  if (!thumb || !g_file_test(it.full, G_FILE_TEST_EXISTS))
    push(p, &it, FALSE);
}

// One absolute path a line, ~/ for the home; read when it changed since
static void read_list(Picker *p) {
  char *path = list_path();
  struct stat st;
  time_t mtime = stat(path, &st) ? 0 : st.st_mtime;
  if (p->items->len && mtime == p->list_mtime) {
    g_free(path);
    return;
  }
  p->list_mtime = mtime;

  char *text = NULL;
  g_file_get_contents(path, &text, NULL, NULL);
  g_free(path);
  clear_items(p);
  char **lines = g_strsplit(text ? text : "", "\n", -1);
  for (char **l = lines; *l; l++) {
    char *line = g_strstrip(*l);
    if (!*line || *line == '#')
      continue;
    char *file = g_str_has_prefix(line, "~/")
                     ? g_build_filename(g_get_home_dir(), line + 2, NULL)
                     : g_strdup(line);
    if (g_path_is_absolute(file))
      add_item(p, file);
    g_free(file);
  }
  g_strfreev(lines);
  g_free(text);
  set_current(p, p->current_path);
}

// The size each wallpaper is kept at: what covers every output
static void read_outputs(Picker *p) {
  GdkDisplay *display = gdk_display_get_default();
  p->full_w = p->full_h = 0;
  for (int i = 0; i < gdk_display_get_n_monitors(display); i++) {
    GdkMonitor *m = gdk_display_get_monitor(display, i);
    GdkRectangle r;
    gdk_monitor_get_geometry(m, &r);
    int scale = gdk_monitor_get_scale_factor(m);
    p->full_w = MAX(p->full_w, r.width * scale);
    p->full_h = MAX(p->full_h, r.height * scale);
  }
  if (!p->full_w || !p->full_h)
    p->full_w = 1920, p->full_h = 1080;
}

static gboolean on_key(GtkWidget *w, GdkEventKey *ev, gpointer data) {
  Picker *p = data;
  switch (ev->keyval) {
  case GDK_KEY_Escape:
  case GDK_KEY_q:
    modal_hide(&p->modal);
    return TRUE;
  }
  if (p->items->len == 0)
    return TRUE;

  int n = p->items->len;
  switch (ev->keyval) {
  case GDK_KEY_l:
  case GDK_KEY_Right:
  case GDK_KEY_Tab:
    select_item(p, (p->selected + 1) % n);
    break;
  case GDK_KEY_h:
  case GDK_KEY_Left:
  case GDK_KEY_ISO_Left_Tab:
    select_item(p, (p->selected + n - 1) % n);
    break;
  case GDK_KEY_j:
  case GDK_KEY_Down:
    if (p->selected + COLUMNS < n)
      select_item(p, p->selected + COLUMNS);
    break;
  case GDK_KEY_k:
  case GDK_KEY_Up:
    if (p->selected >= COLUMNS)
      select_item(p, p->selected - COLUMNS);
    break;
  case GDK_KEY_g:
  case GDK_KEY_Home:
    select_item(p, 0);
    break;
  case GDK_KEY_G:
  case GDK_KEY_End:
    select_item(p, n - 1);
    break;
  case GDK_KEY_Return:
  case GDK_KEY_KP_Enter:
  case GDK_KEY_space:
    apply(p);
    break;
  }
  return TRUE;
}

// Its height only once its children have theirs
static void on_size(GtkWidget *w, GdkRectangle *a, gpointer data) {
  scroll_to_selected(data);
}

// From the current wallpaper on each show
static void on_show(gpointer data) {
  Picker *p = data;
  read_list(p);
  gtk_widget_set_visible(p->name, p->items->len > 0);
  if (p->items->len)
    select_item(p, p->current >= 0 ? p->current : 0);
}

// At the start of sway the wallpaper last picked, over the swaybg sway starts
// with no wallpaper set; so too when started anew, as that takes no time
static void restore(Picker *p) {
  char *state = state_path(), *path = NULL;
  if (g_file_get_contents(state, &path, NULL, NULL))
    g_strstrip(path);
  g_free(state);
  if (!path && p->items->len)
    path = g_strdup(item(p, 0)->path);

  struct stat st;
  if (path && !stat(path, &st)) {
    Item it = {.path = path};
    name_cache(p, &it, &st);
    apply_path(p, &it);
    g_free(it.thumb);
    g_free(it.full);
  }
  g_free(path);
}

int main(int argc, char *argv[]) {
  modal_init(&argc, &argv, "sway-wallpaper");

  static Picker p;
  p.modal = (Modal){.on_show = on_show, .data = &p};
  p.items = g_array_new(FALSE, TRUE, sizeof(Item));
  p.thumbs =
      g_hash_table_new_full(g_str_hash, g_str_equal, g_free, g_object_unref);
  p.current = -1;
  p.pool = g_thread_pool_new(work, NULL, 3, FALSE, NULL);
  p.urgent = g_thread_pool_new(work, NULL, 1, FALSE, NULL);
  read_outputs(&p);
  GtkWidget *window = modal_window(&p.modal, "Tapeta");

  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  add_class(box, "modal");

  GtkWidget *section = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  add_class(section, "section");
  GtkWidget *heading = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 10);
  add_class(heading, "heading");
  gtk_box_pack_start(GTK_BOX(heading), label("Tapeta", "title"), FALSE, FALSE,
                     0);
  p.subtitle = label("", "subtitle");
  gtk_label_set_ellipsize(GTK_LABEL(p.subtitle), PANGO_ELLIPSIZE_END);
  gtk_box_pack_start(GTK_BOX(heading), p.subtitle, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(section), heading, FALSE, FALSE, 0);

  p.grid = gtk_grid_new();
  add_class(p.grid, "thumbs");
  gtk_grid_set_row_spacing(GTK_GRID(p.grid), 10);
  gtk_grid_set_column_spacing(GTK_GRID(p.grid), 10);
  p.scroll = gtk_scrolled_window_new(NULL, NULL);
  add_class(p.scroll, "rows");
  gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(p.scroll),
                                 GTK_POLICY_NEVER, GTK_POLICY_EXTERNAL);
  gtk_scrolled_window_set_propagate_natural_width(GTK_SCROLLED_WINDOW(p.scroll),
                                                  TRUE);
  // Room for the frames of ROWS rows: 2px of border and 2px of padding a side
  gtk_widget_set_size_request(p.scroll, -1,
                              ROWS * (THUMB_H + 8) + (ROWS - 1) * 10);
  gtk_container_add(GTK_CONTAINER(p.scroll), p.grid);
  g_signal_connect(p.grid, "size-allocate", G_CALLBACK(on_size), &p);
  gtk_box_pack_start(GTK_BOX(section), p.scroll, FALSE, FALSE, 0);

  p.name = label("", "note");
  add_class(p.name, "thumb-name");
  gtk_label_set_xalign(GTK_LABEL(p.name), 0);
  gtk_label_set_ellipsize(GTK_LABEL(p.name), PANGO_ELLIPSIZE_MIDDLE);
  gtk_widget_set_no_show_all(p.name, TRUE);
  gtk_box_pack_start(GTK_BOX(section), p.name, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box), section, FALSE, FALSE, 0);

  gtk_container_add(GTK_CONTAINER(window), box);
  g_signal_connect(window, "key-press-event", G_CALLBACK(on_key), &p);

  read_list(&p);
  restore(&p);
  modal_run(&p.modal, "wallpaper", argc, argv);
  return 0;
}
