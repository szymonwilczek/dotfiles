#!/bin/bash

POS=$(slurp -p 2>/dev/null)
[ -z "$POS" ] && exit 0

COLOR=$(grim -g "$POS" -t ppm - 2>/dev/null | magick - -format "#%[hex:p{0,0}]" info: 2>/dev/null | tr '[:upper:]' '[:lower:]')

if [ -n "$COLOR" ]; then
    printf "%s" "$COLOR" | wl-copy
    notify-send -a "Pipeta" -i color-select "Skopiowano kolor" "$COLOR"
fi
