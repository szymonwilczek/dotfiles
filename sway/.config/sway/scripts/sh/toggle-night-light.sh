#!/bin/bash
dir=~/.config/sway/scripts
src=$dir/src
bin=$dir/bin/night-light

if pkill -x night-light; then
    swayosd-client --custom-icon night-light-disabled-symbolic \
        --custom-message "Night light off"
    exit 0
fi

make -s -C "$src" RESTART= night-light || exit 1

"$bin" &
swayosd-client --custom-icon night-light-symbolic \
    --custom-message "Night light $("$bin" -p)%"
