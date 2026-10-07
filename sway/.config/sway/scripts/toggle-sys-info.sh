#!/bin/bash
# Toggles the system information modal, built anew when its source changed
dir=~/.config/sway/scripts
bin=$dir/sys-info

if pkill -x sys-info; then
    exit 0
fi

if [ ! -x "$bin" ] || [ "$dir/sys-info.c" -nt "$bin" ]; then
    cc -O2 -Wall -Wextra -Wno-unused-parameter -o "$bin" "$dir/sys-info.c" \
        $(pkg-config --cflags --libs gtk+-3.0) || exit 1
fi

exec "$bin"
