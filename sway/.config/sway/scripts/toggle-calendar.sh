#!/bin/bash
# Toggles the calendar under the waybar clock, built anew when its source
# changed
dir=~/.config/sway/scripts
bin=$dir/calendar
bar_output=DP-2

if pkill -x calendar; then
    exit 0
fi

if [ ! -x "$bin" ] || [ "$dir/calendar.c" -nt "$bin" ]; then
    cc -O2 -Wall -Wextra -Wno-unused-parameter -o "$bin" "$dir/calendar.c" \
        $(pkg-config --cflags --libs gtk+-3.0) || exit 1
fi

"$bin" &

for _ in $(seq 100); do
    width=$(swaymsg -t get_tree |
        jq '.. | objects | select(.app_id? == "sway-calendar") | .rect.width')
    [ -n "$width" ] && break
    sleep 0.02
done
[ -n "$width" ] || exit 1

pos=$(swaymsg -t get_workspaces | jq -r --arg out "$bar_output" \
    --argjson w "$width" '.[] | select(.visible and .output == $out) |
    "\(.rect.x + ((.rect.width - $w) / 2 | floor)) \(.rect.y)"')
swaymsg -q "[app_id=sway-calendar] move absolute position $pos, opacity 1"
