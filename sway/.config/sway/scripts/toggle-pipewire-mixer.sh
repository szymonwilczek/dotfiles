#!/bin/bash
# Toggles the mixer of playing streams, built anew when its source changed
dir=~/.config/sway/scripts
bin=$dir/pipewire-mixer

if pkill -x pipewire-mixer; then
    exit 0
fi

if [ ! -x "$bin" ] || [ "$dir/pipewire-mixer.c" -nt "$bin" ]; then
    cc -O2 -Wall -Wextra -Wno-unused-parameter -o "$bin" \
        "$dir/pipewire-mixer.c" $(pkg-config --cflags --libs gtk+-3.0 json-c) ||
        exit 1
fi

exec "$bin"
