#!/bin/bash
if swaymsg -t get_tree | grep -q '"title": "Informacje"'; then
    pkill -f sys-info
else
    ~/.config/sway/scripts/sys-info &
fi
