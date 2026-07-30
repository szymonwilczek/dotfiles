#!/bin/bash
# Independent per-monitor workspaces for Sway
# Each monitor gets its own set of workspaces (1-10)
#
# Usage:
#   workspace.sh switch <N>   - switch to workspace N on focused monitor
#   workspace.sh move <N>     - move container to workspace N on focused monitor
#   workspace.sh next         - switch to next workspace on focused monitor
#   workspace.sh prev         - switch to previous workspace on focused monitor

ACTION="$1"
NUM="$2"

FOCUSED_OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')

case "$ACTION" in
switch)
    swaymsg workspace "${FOCUSED_OUTPUT}:${NUM}"
    ;;
move)
    swaymsg move container to workspace "${FOCUSED_OUTPUT}:${NUM}"
    ;;
next | prev)
    # get current workspace number from the focused workspace name
    CURRENT_WS=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .name')
    CURRENT_NUM="${CURRENT_WS##*:}"

    # fallback if workspace name doesnt have our format yet
    if ! [[ "$CURRENT_NUM" =~ ^[0-9]+$ ]]; then
        CURRENT_NUM=1
    fi

    if [ "$ACTION" = "next" ]; then
        NEW_NUM=$((CURRENT_NUM + 1))
        [ "$NEW_NUM" -gt 10 ] && NEW_NUM=1
    else
        NEW_NUM=$((CURRENT_NUM - 1))
        [ "$NEW_NUM" -lt 1 ] && NEW_NUM=10
    fi

    swaymsg workspace "${FOCUSED_OUTPUT}:${NEW_NUM}"
    ;;
*)
    echo "Usage: $0 [switch|move|next|prev] [number]" >&2
    exit 1
    ;;
esac
