#!/bin/bash

if ! swaymsg -t get_tree | grep -q '"scratchpad_ghostty"'; then
    ghostty --title="Scratchpad Ghostty" &
    exit 0
fi

IS_VISIBLE=$(swaymsg -t get_tree | jq '.. | select(.type?=="con" and .marks?!=null) | select(.marks[]=="scratchpad_ghostty") | .visible')

if [ "$IS_VISIBLE" = "true" ]; then
    swaymsg '[con_mark="scratchpad_ghostty"] move scratchpad'
else
    swaymsg '[con_mark="scratchpad_ghostty"] scratchpad show'
    swaymsg '[con_mark="scratchpad_ghostty"] resize set 1000px 700px'
    swaymsg '[con_mark="scratchpad_ghostty"] move position center'
fi
