#!/bin/bash
# Toggles the system information modal, built by make
dir=~/.config/sway/scripts
bin=$dir/sys-info

if pkill -x sys-info; then
    exit 0
fi

make -s -C "$dir" RESTART= sys-info || exit 1

exec "$bin"
