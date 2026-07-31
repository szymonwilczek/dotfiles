#!/bin/bash
if swaymsg -t get_tree | grep -q '"title": "Mikser dźwięku"'; then
    pkill -f pipewire-mixer
else
    ~/.config/sway/scripts/pipewire-mixer &
fi
