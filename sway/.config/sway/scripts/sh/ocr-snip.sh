#!/bin/bash

GEOM=$(slurp 2>/dev/null)
[ -z "$GEOM" ] && exit 0

TEXT=$(grim -g "$GEOM" - 2>/dev/null | tesseract stdin stdout -l pol+eng --psm 6 2>/dev/null | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

if [ -n "$TEXT" ]; then
    printf "%s" "$TEXT" | wl-copy
    notify-send -a "Sway OCR" -i edit-copy "Skopiowano tekst" "$TEXT"
else
    notify-send -a "Sway OCR" -i dialog-warning "Sway OCR" "Nie wykryto tekstu na zaznaczonym obszarze."
fi
