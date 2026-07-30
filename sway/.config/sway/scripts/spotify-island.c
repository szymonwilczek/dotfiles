#include <dbus/dbus.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define SAMPLE_RATE 11025
#define SAMPLES_PER_FRAME 441 // ~40ms audio frame
#define PI 3.14159265358979323846

static const char *BARS[] = {" ", "▂", "▃", "▄", "▅", "▆", "▇", "█"};

typedef struct {
  char status[32];
  char artist[128];
  char title[128];
  char album[128];
  char art_url[256];
  long long length_us;
  long long position_us;
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

static void escape_json(const char *src, char *dst, size_t max_len) {
  size_t j = 0;
  for (size_t i = 0; src[i] != '\0' && j + 6 < max_len; i++) {
    if (src[i] == '"') {
      dst[j++] = '\\';
      dst[j++] = '"';
    } else if (src[i] == '\\') {
      dst[j++] = '\\';
      dst[j++] = '\\';
    } else if (src[i] == '\n') {
      dst[j++] = '\\';
      dst[j++] = 'n';
    } else if (src[i] == '\r') {
      // skip
    } else if (src[i] == '\t') {
      dst[j++] = '\\';
      dst[j++] = 't';
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
  info->album[0] = '\0';
  info->art_url[0] = '\0';
  info->length_us = 0;
  info->position_us = 0;

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
      } else if (strcmp(key, "Position") == 0 &&
                 dbus_message_iter_get_arg_type(&val_iter) == DBUS_TYPE_INT64) {
        dbus_message_iter_get_basic(&val_iter, &info->position_us);
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
          } else if (strcmp(m_key, "xesam:album") == 0 &&
                     dbus_message_iter_get_arg_type(&m_val) ==
                         DBUS_TYPE_STRING) {
            char *al;
            dbus_message_iter_get_basic(&m_val, &al);
            snprintf(info->album, sizeof(info->album), "%s", al);
          } else if (strcmp(m_key, "mpris:artUrl") == 0 &&
                     dbus_message_iter_get_arg_type(&m_val) ==
                         DBUS_TYPE_STRING) {
            char *au;
            dbus_message_iter_get_basic(&m_val, &au);
            snprintf(info->art_url, sizeof(info->art_url), "%s", au);
          } else if (strcmp(m_key, "mpris:length") == 0 &&
                     dbus_message_iter_get_arg_type(&m_val) ==
                         DBUS_TYPE_INT64) {
            dbus_message_iter_get_basic(&m_val, &info->length_us);
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

static char cached_art_url[256] = "";
static char cover_lines[6][1024];

static void update_ascii_cover_c(const char *art_url) {
  if (strcmp(cached_art_url, art_url) == 0)
    return;

  snprintf(cached_art_url, sizeof(cached_art_url), "%s", art_url);
  for (int i = 0; i < 6; i++) {
    strcpy(cover_lines[i], "                ");
  }

  if (art_url[0] == '\0')
    return;

  char fetch_cmd[512];
  snprintf(fetch_cmd, sizeof(fetch_cmd),
           "curl -s '%s' -o /tmp/spotify_island_c_cover.jpg 2>/dev/null",
           art_url);
  system(fetch_cmd);

  int w, h, channels;
  unsigned char *img =
      stbi_load("/tmp/spotify_island_c_cover.jpg", &w, &h, &channels, 3);
  if (!img)
    return;

  for (int row = 0; row < 6; row++) {
    char line_buf[1024] = "";
    int y1 = (row * 2) * h / 12;
    int y2 = (row * 2 + 1) * h / 12;

    for (int col = 0; col < 16; col++) {
      int x = col * w / 16;

      int idx1 = (y1 * w + x) * 3;
      int idx2 = (y2 * w + x) * 3;

      unsigned char r1 = img[idx1], g1 = img[idx1 + 1], b1 = img[idx1 + 2];
      unsigned char r2 = img[idx2], g2 = img[idx2 + 1], b2 = img[idx2 + 2];

      char span[128];
      snprintf(span, sizeof(span),
               "<span foreground='#%02x%02x%02x' "
               "background='#%02x%02x%02x'>▀</span>",
               r1, g1, b1, r2, g2, b2);
      strcat(line_buf, span);
    }
    snprintf(cover_lines[row], sizeof(cover_lines[row]), "%s", line_buf);
  }

  stbi_image_free(img);
}

int main() {
  DBusError err;
  dbus_error_init(&err);
  DBusConnection *conn = dbus_bus_get(DBUS_BUS_SESSION, &err);
  if (dbus_error_is_set(&err) || !conn) {
    dbus_error_free(&err);
    return 1;
  }

  FILE *parec = NULL;
  short pcm[SAMPLES_PER_FRAME];
  float peaks[4] = {0.05f, 0.05f, 0.05f, 0.05f};

  static char last_printed[8192] = "";

  // Bass, Mid-Low, Mid-High, Treble
  int b_min[4] = {40, 250, 1000, 3000};
  int b_max[4] = {250, 1000, 3000, 5500};

  while (1) {
    SpotifyInfo info;
    int active = get_spotify_info(conn, &info);

    if (!active || strcmp(info.status, "Stopped") == 0 ||
        info.title[0] == '\0') {
      if (parec) {
        pclose(parec);
        parec = NULL;
      }
      if (strcmp(last_printed, "EMPTY") != 0) {
        printf("{\"text\": \"\", \"class\": \"stopped\", \"tooltip\": \"\"}\n");
        fflush(stdout);
        strcpy(last_printed, "EMPTY");
      }
      usleep(250000);
      continue;
    }

    char s_title[256], s_artist[256], s_album[256];
    sanitize_pango(info.title, s_title, sizeof(s_title));
    sanitize_pango(info.artist, s_artist, sizeof(s_artist));
    sanitize_pango(info.album, s_album, sizeof(s_album));

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

    if (strcmp(info.status, "Paused") == 0) {
      if (parec) {
        pclose(parec);
        parec = NULL;
      }

      update_ascii_cover_c(info.art_url);

      long pos_sec = info.position_us / 1000000;
      long len_sec = info.length_us / 1000000;

      char time_str[128];
      snprintf(time_str, sizeof(time_str), "%02ld:%02ld / %02ld:%02ld",
               pos_sec / 60, pos_sec % 60, len_sec / 60, len_sec % 60);

      char progress_bar[128] = "";
      int bar_len = 16;
      int pos_idx =
          (len_sec > 0) ? (int)(((double)pos_sec / len_sec) * bar_len) : 0;
      if (pos_idx > bar_len)
        pos_idx = bar_len;

      for (int b = 0; b < bar_len; b++) {
        if (b < pos_idx)
          strcat(progress_bar, "━");
        else if (b == pos_idx)
          strcat(progress_bar, "╸");
        else
          strcat(progress_bar, "─");
      }

      char raw_tooltip[6144];
      snprintf(
          raw_tooltip, sizeof(raw_tooltip),
          "<tt>%s</tt>  <b><span size='12000'>%s</span></b>\n"
          "<tt>%s</tt>  <span size='10000' color='#cccccc'>%s</span>\n"
          "<tt>%s</tt>  <span size='9000' color='#888888'><i>%s</i></span>\n"
          "<tt>%s</tt>\n"
          "<tt>%s</tt>  <span color='#1ed760'>%s</span>  <span "
          "color='#aaaaaa'>%s</span>\n"
          "<tt>%s</tt>",
          cover_lines[0], s_title[0] ? s_title : "Nieznany utwór",
          cover_lines[1], s_artist[0] ? s_artist : "", cover_lines[2],
          s_album[0] ? s_album : "", cover_lines[3], cover_lines[4],
          progress_bar, time_str, cover_lines[5]);

      char escaped_tooltip[8192];
      escape_json(raw_tooltip, escaped_tooltip, sizeof(escaped_tooltip));

      char out_str[8192];
      snprintf(out_str, sizeof(out_str),
               "{\"text\": \"<span foreground='#888888'>󰏤</span>  %s\", "
               "\"class\": \"paused\", \"tooltip\": \"%s\"}",
               track, escaped_tooltip);
      if (strcmp(last_printed, out_str) != 0) {
        printf("%s\n", out_str);
        fflush(stdout);
        strcpy(last_printed, out_str);
      }
      usleep(150000);
      continue;
    }

    // when playing
    if (!parec) {
      parec = popen("parec --device=@DEFAULT_SINK@.monitor --channels=1 "
                    "--format=s16le --rate=11025 --latency-msec=20 2>/dev/null",
                    "r");
    }

    char eq_str[16] = "";
    if (parec && fread(pcm, sizeof(short), SAMPLES_PER_FRAME, parec) ==
                     SAMPLES_PER_FRAME) {
      for (int i = 0; i < 4; i++) {
        int k1 = (int)(b_min[i] * SAMPLES_PER_FRAME / (float)SAMPLE_RATE);
        int k2 = (int)(b_max[i] * SAMPLES_PER_FRAME / (float)SAMPLE_RATE);
        if (k1 < 1)
          k1 = 1;
        if (k2 > SAMPLES_PER_FRAME / 2)
          k2 = SAMPLES_PER_FRAME / 2;

        float energy = 0.0f;
        int count = 0;
        int step = (k2 - k1) / 3;
        if (step < 1)
          step = 1;

        for (int k = k1; k <= k2; k += step) {
          float w = 2.0f * PI * k / SAMPLES_PER_FRAME;
          float real = 0.0f, imag = 0.0f;
          for (int n = 0; n < SAMPLES_PER_FRAME; n += 4) {
            float s = pcm[n] / 32768.0f;
            real += s * cosf(n * w);
            imag += s * sinf(n * w);
          }
          energy += sqrtf(real * real + imag * imag);
          count++;
        }

        float avg_e = energy / (count > 0 ? count : 1);

        // AGC with smooth decay
        if (avg_e > peaks[i]) {
          peaks[i] = avg_e;
        } else {
          peaks[i] *= 0.94f;
          if (peaks[i] < 0.02f)
            peaks[i] = 0.02f;
        }

        float norm = avg_e / peaks[i];
        int b_idx = (int)(norm * 7.99f);
        if (b_idx < 0)
          b_idx = 0;
        if (b_idx > 7)
          b_idx = 7;

        strcat(eq_str, BARS[b_idx]);
      }
    } else {
      strcpy(eq_str, " ▂▃▂");
    }

    char out_str[8192];
    snprintf(out_str, sizeof(out_str),
             "{\"text\": \"<span foreground='#1ed760'><b>%s</b></span>  %s\", "
             "\"class\": \"playing\", \"tooltip\": \"\"}",
             eq_str, track);

    printf("%s\n", out_str);
    fflush(stdout);

    usleep(25000); // 40 FPS
  }

  if (parec)
    pclose(parec);
  return 0;
}
