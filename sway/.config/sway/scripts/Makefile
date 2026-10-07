# Builds the C programs of sway/scripts and puts each new one in place of
# the one running:
#
#   make               all of them
#   make <program>     one, by its name or the short one below
#   make clean         removes what was built
#
# The scripts that start them build them too, with RESTART= as they start
# them themselves.

CC ?= cc
CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter
RESTART ?= 1

GTK = gtk+-3.0
PROTOCOL = wlr-gamma-control-unstable-v1

PROGRAMS = sys-info calendar pipewire-mixer audio-switcher autotiling \
	night-light spotify-island waybar-clock.so

all: $(PROGRAMS)

mixer: pipewire-mixer
switcher: audio-switcher
clock: waybar-clock.so
spotify: spotify-island
nightlight: night-light

.PHONY: all clean mixer switcher clock spotify nightlight

build = $(CC) $(CFLAGS) -o $@.new $(1) $$(pkg-config --cflags --libs $(2)) && \
	mv -f $@.new $@

restart = $(if $(RESTART),pgrep -x $(1) >/dev/null && { $(2); } || true)
sway = swaymsg -q exec "$(CURDIR)/$(1)"

sys-info: sys-info.c
	$(call build,$<,$(GTK))
	@$(call restart,sys-info,pkill -x sys-info)

calendar: calendar.c
	$(call build,$<,$(GTK) gtk-layer-shell-0)
	@$(call restart,calendar,pkill -x calendar)

pipewire-mixer audio-switcher: %: %.c modal.h pactl.h
	$(call build,$<,$(GTK) json-c)
	@$(call restart,$@,pkill -x $@; $(call sway,modal.sh $@ --hidden))

autotiling: autotiling.c
	$(call build,$<,json-c)
	@$(call restart,autotiling,$(call sway,autotiling.sh))

night-light: night-light.c build/$(PROTOCOL)-client-protocol.h \
		build/$(PROTOCOL)-protocol.c
	$(CC) $(CFLAGS) -Ibuild -o $@.new $< build/$(PROTOCOL)-protocol.c \
		-lwayland-client -lm && mv -f $@.new $@
	@$(call restart,night-light,pkill -x night-light; $(call sway,night-light))

build/$(PROTOCOL)-client-protocol.h: $(PROTOCOL).xml
	@mkdir -p build
	wayland-scanner client-header $< $@

build/$(PROTOCOL)-protocol.c: $(PROTOCOL).xml
	@mkdir -p build
	wayland-scanner private-code $< $@

# Its title is cut to its space on purpose
spotify-island: spotify-island.c
	$(call build,$< -Wno-format-truncation,dbus-1)
	@$(call restart,spotify-island,pkill -x spotify-island)

# Loaded into waybar, so waybar starts anew
waybar-clock.so: waybar-clock.c waybar_cffi_module.h
	$(call build,-fPIC -shared $<,$(GTK))
	@$(call restart,waybar,pkill -x waybar; $(call sway,waybar.sh))

clean:
	rm -rf build $(PROGRAMS)
