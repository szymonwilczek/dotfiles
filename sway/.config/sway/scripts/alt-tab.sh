#!/bin/bash
DIR="${1:-next}"

WINDOW_IDS=($(swaymsg -t get_tree | jq -r '
  .. | select(.type? == "workspace" and .name != "__i3_scratch")? |
  .. | select(.pid? != null and .name? != null)? |
  .id
'))

COUNT=${#WINDOW_IDS[@]}
if [ $COUNT -le 1 ]; then
    exit 0
fi

FOCUSED_ID=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true)? | .id' | head -1)

CURRENT_INDEX=-1
for i in "${!WINDOW_IDS[@]}"; do
    if [ "${WINDOW_IDS[$i]}" -eq "$FOCUSED_ID" ] 2>/dev/null; then
        CURRENT_INDEX=$i
        break
    fi
done

if [ $CURRENT_INDEX -eq -1 ]; then
    CURRENT_INDEX=0
fi

if [ "$DIR" = "prev" ]; then
    TARGET_INDEX=$(((CURRENT_INDEX - 1 + COUNT) % COUNT))
else
    TARGET_INDEX=$(((CURRENT_INDEX + 1) % COUNT))
fi

TARGET_ID=${WINDOW_IDS[$TARGET_INDEX]}

swaymsg "[con_id=${TARGET_ID}] focus" >/dev/null 2>&1
