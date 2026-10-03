#!/bin/bash
# (Re)starts autotiling, built anew when its source changed
dir=~/.config/sway/scripts
bin=$dir/autotiling

pkill -x autotiling

if [ ! -x "$bin" ] || [ "$dir/autotiling.c" -nt "$bin" ]; then
    cc -O2 -Wall -Wextra -o "$bin" "$dir/autotiling.c" \
        $(pkg-config --cflags --libs json-c) || exit 1
fi

exec "$bin"
