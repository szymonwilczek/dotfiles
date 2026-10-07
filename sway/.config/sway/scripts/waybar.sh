#!/bin/bash
# Starts waybar, with its clock module and the calendar it shows built anew
# when their source changed; a module that fails to build or load leaves
# the rest of the bar working
dir=~/.config/sway/scripts
so=$dir/waybar-clock.so
calendar=$dir/calendar
flags="-O2 -Wall -Wextra -Wno-unused-parameter"

if [ ! -e "$so" ] || [ "$dir/waybar-clock.c" -nt "$so" ]; then
    cc $flags -fPIC -shared -o "$so" "$dir/waybar-clock.c" \
        $(pkg-config --cflags --libs gtk+-3.0)
fi

if [ ! -x "$calendar" ] || [ "$dir/calendar.c" -nt "$calendar" ]; then
    cc $flags -o "$calendar" "$dir/calendar.c" \
        $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0)
fi

# module_path of cffi/clock is relative to it
cd ~ || exit 1
LC_ALL=pl_PL.UTF-8 exec waybar
