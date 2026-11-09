#!/bin/bash
# Toggles the system information modal, built by make
dir=~/.config/sway/scripts
src=$dir/src
bin=$dir/bin/sys-info

if pkill -x sys-info; then
    exit 0
fi

make -s -C "$src" RESTART= sys-info || exit 1

exec "$bin"
