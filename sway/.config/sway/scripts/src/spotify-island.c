#include <dbus/dbus.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef struct {
  char status[32];
  char artist[128];
  char title[128];
} SpotifyInfo;

static void sanitize_pango(const char *src, char *dst, size_t max_len) {
  size_t j = 0;
  for (size_t i = 0; src[i] != '\0' && j + 6 < max_len; i++) {
    if (src[i] == '&') {
      strcpy(&dst[j], "&amp;");
      j += 5;
    } else if (src[i] == '<') {
      strcpy(&dst[j], "&lt;");
      j += 4;
    } else if (src[i] == '>') {
      strcpy(&dst[j], "&gt;");
      j += 4;
    } else {
      dst[j++] = src[i];
    }
  }
  dst[j] = '\0';
}

static int get_spotify_info(DBusConnection *conn, SpotifyInfo *info) {
  info->status[0] = '\0';
  info->artist[0] = '\0';
  info->title[0] = '\0';

  DBusMessage *msg = dbus_message_new_method_call(
      "org.mpris.MediaPlayer2.spotify", "/org/mpris/MediaPlayer2",
      "org.freedesktop.DBus.Properties", "GetAll");
  if (!msg)
    return 0;

  const char *iface = "org.mpris.MediaPlayer2.Player";
  dbus_message_append_args(msg, DBUS_TYPE_STRING, &iface, DBUS_TYPE_INVALID);

  DBusError err;
  dbus_error_init(&err);
  DBusMessage *reply =
      dbus_connection_send_with_reply_and_block(conn, msg, 80, &err);
  dbus_message_unref(msg);

  if (dbus_error_is_set(&err) || !reply) {
    dbus_error_free(&err);
    return 0;
  }

  DBusMessageIter iter, dict;
  if (dbus_message_iter_init(reply, &iter) &&
      dbus_message_iter_get_arg_type(&iter) == DBUS_TYPE_ARRAY) {
    dbus_message_iter_recurse(&iter, &dict);
    while (dbus_message_iter_get_arg_type(&dict) == DBUS_TYPE_DICT_ENTRY) {
      DBusMessageIter entry, val_iter;
      char *key;
      dbus_message_iter_recurse(&dict, &entry);
      dbus_message_iter_get_basic(&entry, &key);
      dbus_message_iter_next(&entry);
      dbus_message_iter_recurse(&entry, &val_iter);

      if (strcmp(key, "PlaybackStatus") == 0 &&
          dbus_message_iter_get_arg_type(&val_iter) == DBUS_TYPE_STRING) {
        char *s;
        dbus_message_iter_get_basic(&val_iter, &s);
        snprintf(info->status, sizeof(info->status), "%s", s);
      } else if (strcmp(key, "Metadata") == 0 &&
                 dbus_message_iter_get_arg_type(&val_iter) == DBUS_TYPE_ARRAY) {
        DBusMessageIter meta_dict;
        dbus_message_iter_recurse(&val_iter, &meta_dict);
        while (dbus_message_iter_get_arg_type(&meta_dict) ==
               DBUS_TYPE_DICT_ENTRY) {
          DBusMessageIter m_entry, m_val;
          char *m_key;
          dbus_message_iter_recurse(&meta_dict, &m_entry);
          dbus_message_iter_get_basic(&m_entry, &m_key);
          dbus_message_iter_next(&m_entry);
          dbus_message_iter_recurse(&m_entry, &m_val);

          if (strcmp(m_key, "xesam:title") == 0 &&
              dbus_message_iter_get_arg_type(&m_val) == DBUS_TYPE_STRING) {
            char *t;
            dbus_message_iter_get_basic(&m_val, &t);
            snprintf(info->title, sizeof(info->title), "%s", t);
          } else if (strcmp(m_key, "xesam:artist") == 0 &&
                     dbus_message_iter_get_arg_type(&m_val) ==
                         DBUS_TYPE_ARRAY) {
            DBusMessageIter arr_iter;
            dbus_message_iter_recurse(&m_val, &arr_iter);
            if (dbus_message_iter_get_arg_type(&arr_iter) == DBUS_TYPE_STRING) {
              char *a;
              dbus_message_iter_get_basic(&arr_iter, &a);
              snprintf(info->artist, sizeof(info->artist), "%s", a);
            }
          }
          dbus_message_iter_next(&meta_dict);
        }
      }
      dbus_message_iter_next(&dict);
    }
  }

  dbus_message_unref(reply);
  return (info->status[0] != '\0');
}

int main() {
  DBusError err;
  dbus_error_init(&err);
  DBusConnection *conn = dbus_bus_get(DBUS_BUS_SESSION, &err);
  if (dbus_error_is_set(&err) || !conn) {
    dbus_error_free(&err);
    return 1;
  }

  static char last_printed[1024] = "";

  while (1) {
    SpotifyInfo info;
    int active = get_spotify_info(conn, &info);

    if (!active || strcmp(info.status, "Stopped") == 0 ||
        info.title[0] == '\0') {
      if (strcmp(last_printed, "EMPTY") != 0) {
        printf("{\"text\": \"\", \"class\": \"stopped\", \"tooltip\": \"\"}\n");
        fflush(stdout);
        strcpy(last_printed, "EMPTY");
      }
      usleep(250000);
      continue;
    }

    char s_title[256], s_artist[256];
    sanitize_pango(info.title, s_title, sizeof(s_title));
    sanitize_pango(info.artist, s_artist, sizeof(s_artist));

    char track[128];
    if (s_artist[0] != '\0') {
      snprintf(track, sizeof(track), "%s - %s", s_artist, s_title);
    } else {
      snprintf(track, sizeof(track), "%s", s_title);
    }

    if (strlen(track) > 35) {
      track[32] = '.';
      track[33] = '.';
      track[34] = '.';
      track[35] = '\0';
    }

    char out_str[1024];

    if (strcmp(info.status, "Paused") == 0) {
      snprintf(out_str, sizeof(out_str),
               "{\"text\": \"<span foreground='#888888'>󰏤</span>  %s\", "
               "\"class\": \"paused\", \"tooltip\": \"\"}",
               track);
    } else {
      snprintf(out_str, sizeof(out_str),
               "{\"text\": \"%s\", "
               "\"class\": \"playing\", \"tooltip\": \"\"}",
               track);
    }

    if (strcmp(last_printed, out_str) != 0) {
      printf("%s\n", out_str);
      fflush(stdout);
      strcpy(last_printed, out_str);
    }

    usleep(250000);
  }

  return 0;
}
