#!/bin/bash
RECORDER="$HOME/.cargo/bin/wl-screenrec"
if [ ! -x "$RECORDER" ]; then
    RECORDER="wl-screenrec"
fi

if pgrep -x wl-screenrec >/dev/null; then
    pkill -SIGINT -x wl-screenrec
    exit 0
fi

VIDEOS_DIR="$HOME/Wideo"
mkdir -p "$VIDEOS_DIR"

GEOM=$(slurp)
if [ -z "$GEOM" ]; then
    exit 0
fi

OUTPUT_FILE="$VIDEOS_DIR/Nagranie_$(date +'%Y-%m-%d_%H-%M-%S').mp4"

# waybar refreshes the indicator only on RTMIN+8, so signal it once
# the recorder runs and again once it exits, however it was stopped
(
    "$RECORDER" -g "$GEOM" -f "$OUTPUT_FILE" >/dev/null 2>&1
    pkill -RTMIN+8 waybar 2>/dev/null || true
) &
for _ in $(seq 20); do
    pgrep -x wl-screenrec >/dev/null && break
    sleep 0.05
done
pkill -RTMIN+8 waybar 2>/dev/null || true
