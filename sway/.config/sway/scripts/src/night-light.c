// Filters the screen the stronger the later it gets.
//
// Unlike the usual black body warming, which turns white orange, the filter
// keeps white close to neutral, like the hardware low blue light of laptop
// panels: it trims some blue and dims the screen as a whole, so less blue
// light reaches the eyes without the color cast.
//
// The day level applies while the sun is up, dusk raises it to the evening
// level, and the hours before bedtime raise it further to the night one.
//
// Sunset follows the date and the location, so winter evenings start earlier.
// SIGTERM fades back to neutral and exits.
//
// Built by toggle-night-light.sh;
//      -p prints the current level in percent and
//      -t <percent> holds a fixed one, to try out values.

#define _GNU_SOURCE
#include <math.h>
#include <poll.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>
#include <wayland-client.h>

#include "wlr-gamma-control-unstable-v1-client-protocol.h"

// Center of Poland
#define LATITUDE 52.0
#define LONGITUDE 19.0

// Levels of the filter, from 0 for none to 100 for the full night one
#define DAY_LEVEL 10
#define EVENING_LEVEL 60
#define NIGHT_LEVEL 100

// The full filter dims white by this much and trims blue by this much more
#define DIM 0.10
#define BLUE_CUT 0.06

#define DUSK_START 3.0
#define DUSK_END -6.0

// Local bedtime in minutes after midnight;
// the night level is reached two hours before it, after a two hour ramp,
// and holds until it
#define BEDTIME (4 * 60 + 30)
#define WIND_DOWN 120
#define NIGHT_HOLD 120
#define WAKE_UP 60

#define UPDATE_INTERVAL_MS 60000
#define FADE_STEPS 20
#define FADE_STEP_MS 50

typedef struct Output {
  struct wl_output *wl_output;
  struct zwlr_gamma_control_v1 *control;
  uint32_t name;
  uint32_t ramp_size;
  struct Output *next;
} Output;

static struct zwlr_gamma_control_manager_v1 *manager;
static Output *outputs;
static int dirty;
static volatile sig_atomic_t stop;
static double fixed_level = -1;

static double to_rad(double deg) { return deg * M_PI / 180.0; }

static double to_deg(double rad) { return rad * 180.0 / M_PI; }

static double lerp(double a, double b, double t) {
  t = t < 0 ? 0 : t > 1 ? 1 : t;
  return a + (b - a) * t;
}

static double sun_elevation(time_t now) {
  double n = now / 86400.0 + 2440587.5 - 2451545.0;
  double mean_long = fmod(280.460 + 0.9856474 * n, 360.0);
  double anomaly = to_rad(357.528 + 0.9856003 * n);
  double ecl_long =
      to_rad(mean_long + 1.915 * sin(anomaly) + 0.020 * sin(2 * anomaly));
  double obliquity = to_rad(23.439 - 0.0000004 * n);
  double ra = atan2(cos(obliquity) * sin(ecl_long), cos(ecl_long));
  double dec = asin(sin(obliquity) * sin(ecl_long));
  double sidereal = to_rad(fmod(280.46061837 + 360.98564736629 * n, 360.0));
  double hour_angle = sidereal + to_rad(LONGITUDE) - ra;
  double lat = to_rad(LATITUDE);
  return to_deg(
      asin(sin(lat) * sin(dec) + cos(lat) * cos(dec) * cos(hour_angle)));
}

static double level(time_t now) {
  if (fixed_level >= 0)
    return fixed_level;
  double elevation = sun_elevation(now);
  double day = lerp(EVENING_LEVEL, DAY_LEVEL,
                    (elevation - DUSK_END) / (DUSK_START - DUSK_END));

  struct tm local;
  localtime_r(&now, &local);
  // minutes to bedtime, negative before it, wrapped to half a day
  int minutes = local.tm_hour * 60 + local.tm_min - BEDTIME;
  minutes = ((minutes + 720) % 1440 + 1440) % 1440 - 720;

  double bed = 0;
  if (minutes >= -WIND_DOWN - NIGHT_HOLD && minutes < -NIGHT_HOLD)
    bed = lerp(EVENING_LEVEL, NIGHT_LEVEL,
               (minutes + WIND_DOWN + NIGHT_HOLD) / (double)WIND_DOWN);
  else if (minutes >= -NIGHT_HOLD && minutes < 0)
    bed = NIGHT_LEVEL;
  else if (minutes >= 0 && minutes < WAKE_UP)
    bed = lerp(NIGHT_LEVEL, DAY_LEVEL, minutes / (double)WAKE_UP);
  return fmax(day, bed);
}

// Channel gains of the filter at the given level: white dims evenly,
// and blue a little more, so it stays near neutral instead of turning orange
static void white_point(double level, double rgb[3]) {
  double strength = level / 100.0;
  double white = 1.0 - DIM * strength;
  rgb[0] = white;
  rgb[1] = white;
  rgb[2] = white * (1.0 - BLUE_CUT * strength);
}

static void set_gamma(Output *output, double level) {
  size_t size = output->ramp_size * 3 * sizeof(uint16_t);
  int fd = memfd_create("night-light", MFD_CLOEXEC);
  if (fd < 0 || ftruncate(fd, size) < 0) {
    perror("night-light: memfd");
    if (fd >= 0)
      close(fd);
    return;
  }
  uint16_t *ramp = mmap(NULL, size, PROT_WRITE, MAP_SHARED, fd, 0);
  if (ramp == MAP_FAILED) {
    perror("night-light: mmap");
    close(fd);
    return;
  }
  double rgb[3];
  white_point(level, rgb);
  for (uint32_t c = 0; c < 3; c++)
    for (uint32_t i = 0; i < output->ramp_size; i++)
      ramp[c * output->ramp_size + i] =
          (uint16_t)(65535.0 * rgb[c] * i / (output->ramp_size - 1));
  munmap(ramp, size);
  zwlr_gamma_control_v1_set_gamma(output->control, fd);
  close(fd);
}

static void set_all(struct wl_display *display, double level) {
  for (Output *o = outputs; o; o = o->next)
    if (o->control && o->ramp_size > 1)
      set_gamma(o, level);
  wl_display_flush(display);
}

static void fade(struct wl_display *display, double from, double to) {
  struct timespec step = {0, FADE_STEP_MS * 1000000L};
  for (int i = 1; i <= FADE_STEPS; i++) {
    set_all(display, lerp(from, to, (double)i / FADE_STEPS));
    nanosleep(&step, NULL);
  }
}

static void handle_gamma_size(void *data, struct zwlr_gamma_control_v1 *control,
                              uint32_t size) {
  ((Output *)data)->ramp_size = size;
  dirty = 1;
}

static void handle_failed(void *data, struct zwlr_gamma_control_v1 *control) {
  fprintf(stderr, "night-light: gamma control failed, is wlsunset running?\n");
  exit(1);
}

static const struct zwlr_gamma_control_v1_listener gamma_listener = {
    .gamma_size = handle_gamma_size,
    .failed = handle_failed,
};

static void add_control(Output *output) {
  if (!manager || output->control)
    return;
  output->control = zwlr_gamma_control_manager_v1_get_gamma_control(
      manager, output->wl_output);
  zwlr_gamma_control_v1_add_listener(output->control, &gamma_listener, output);
}

static void handle_global(void *data, struct wl_registry *registry,
                          uint32_t name, const char *interface,
                          uint32_t version) {
  if (strcmp(interface, wl_output_interface.name) == 0) {
    Output *output = calloc(1, sizeof(*output));
    output->name = name;
    output->wl_output =
        wl_registry_bind(registry, name, &wl_output_interface, 1);
    output->next = outputs;
    outputs = output;
    add_control(output);
  } else if (strcmp(interface, zwlr_gamma_control_manager_v1_interface.name) ==
             0) {
    manager = wl_registry_bind(registry, name,
                               &zwlr_gamma_control_manager_v1_interface, 1);
    for (Output *o = outputs; o; o = o->next)
      add_control(o);
  }
}

static void handle_global_remove(void *data, struct wl_registry *registry,
                                 uint32_t name) {
  for (Output **o = &outputs; *o; o = &(*o)->next) {
    if ((*o)->name != name)
      continue;
    Output *output = *o;
    *o = output->next;
    if (output->control)
      zwlr_gamma_control_v1_destroy(output->control);
    wl_output_destroy(output->wl_output);
    free(output);
    return;
  }
}

static const struct wl_registry_listener registry_listener = {
    .global = handle_global,
    .global_remove = handle_global_remove,
};

static void handle_signal(int sig) { stop = 1; }

int main(int argc, char **argv) {
  if (argc > 1 && strcmp(argv[1], "-p") == 0) {
    printf("%.0f\n", level(time(NULL)));
    return 0;
  }
  if (argc > 2 && strcmp(argv[1], "-t") == 0)
    fixed_level = atof(argv[2]);

  struct wl_display *display = wl_display_connect(NULL);
  if (!display) {
    fprintf(stderr, "night-light: cannot connect to Wayland\n");
    return 1;
  }
  struct wl_registry *registry = wl_display_get_registry(display);
  wl_registry_add_listener(registry, &registry_listener, NULL);
  wl_display_roundtrip(display);
  if (!manager) {
    fprintf(stderr, "night-light: compositor has no gamma control\n");
    return 1;
  }
  wl_display_roundtrip(display);

  // no SA_RESTART, so a signal wakes poll up at once
  struct sigaction action = {.sa_handler = handle_signal};
  sigaction(SIGTERM, &action, NULL);
  sigaction(SIGINT, &action, NULL);

  double current = level(time(NULL));
  fade(display, 0, current);
  dirty = 0;

  struct pollfd pfd = {.fd = wl_display_get_fd(display), .events = POLLIN};
  while (!stop) {
    while (wl_display_prepare_read(display) != 0)
      wl_display_dispatch_pending(display);
    wl_display_flush(display);
    if (poll(&pfd, 1, UPDATE_INTERVAL_MS) > 0) {
      if (wl_display_read_events(display) < 0)
        break;
    } else {
      wl_display_cancel_read(display);
    }
    if (wl_display_dispatch_pending(display) < 0)
      break;

    double next = level(time(NULL));
    if (dirty || fabs(next - current) >= 0.5) {
      current = next;
      dirty = 0;
      set_all(display, current);
    }
  }

  if (stop)
    fade(display, current, 0);
  wl_display_disconnect(display);
  return 0;
}
