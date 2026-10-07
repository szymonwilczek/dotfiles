#!/bin/bash
# Toggles the picker of the default audio output, built anew when its
# source changed
dir=~/.config/sway/scripts
bin=$dir/audio-switcher

if pkill -x audio-switcher; then
    exit 0
fi

if [ ! -x "$bin" ] || [ "$dir/audio-switcher.c" -nt "$bin" ]; then
    cc -O2 -Wall -Wextra -Wno-unused-parameter -o "$bin" \
        "$dir/audio-switcher.c" $(pkg-config --cflags --libs gtk+-3.0 json-c) ||
        exit 1
fi

exec "$bin"
