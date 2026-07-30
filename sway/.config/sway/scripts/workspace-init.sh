#!/bin/bash
# Initialize per-monitor independent workspaces
# Renames default numbered workspaces (1, 2, 3...) to per-monitor format (DP-2:1, etc)

sleep 0.3

for OUTPUT in $(swaymsg -t get_outputs | jq -r '.[].name'); do
    # get the current workspace on this output (if any)
    CURRENT_WS=$(swaymsg -t get_workspaces | jq -r ".[] | select(.output == \"$OUTPUT\") | .name")

    if [ -n "$CURRENT_WS" ] && [[ "$CURRENT_WS" != *:* ]]; then
        # workspace exists but has a plain name (e.g "1") - rename it
        swaymsg "rename workspace \"$CURRENT_WS\" to \"${OUTPUT}:1\""
    elif [ -z "$CURRENT_WS" ]; then
        # no workspace on this output yet - create one
        swaymsg "focus output $OUTPUT"
        swaymsg "workspace \"${OUTPUT}:1\""
    fi
done

# focus back to the main monitor
swaymsg "focus output DP-2"
