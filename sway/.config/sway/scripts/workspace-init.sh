#!/bin/bash
# Initialize per-monitor independent workspaces
# Cleans up Sway's default plain-numbered workspaces (1, 2, 3...)
# and migrates any windows on them to proper OUTPUT:1 workspaces

sleep 0.3

OUTPUTS=$(swaymsg -t get_outputs | jq -r '.[].name')

# ensure each output has its :1 workspace
for OUTPUT in $OUTPUTS; do
    swaymsg "focus output $OUTPUT"
    swaymsg "workspace \"${OUTPUT}:1\""
done

# clean up any plain-numbered workspaces left by sway's defaults
PLAIN_WS=$(swaymsg -t get_workspaces | jq -r '.[] | select(.name | test("^[0-9]+$")) | .name + "|" + .output')

for ENTRY in $PLAIN_WS; do
    WS_NAME="${ENTRY%%|*}"
    WS_OUTPUT="${ENTRY##*|}"
    swaymsg "[workspace=\"$WS_NAME\"]" move container to workspace "${WS_OUTPUT}:1" 2>/dev/null || true
    swaymsg "focus output $WS_OUTPUT"
    swaymsg "workspace \"${WS_OUTPUT}:1\""
done

# focus back to the main monitor
swaymsg "focus output DP-2"
swaymsg "workspace \"DP-2:1\""
