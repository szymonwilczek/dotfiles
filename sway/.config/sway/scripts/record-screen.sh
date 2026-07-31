#!/bin/bash
RECORDER="$HOME/.cargo/bin/wl-screenrec"
if [ ! -x "$RECORDER" ]; then
    RECORDER="wl-screenrec"
fi

if pgrep -x wl-screenrec >/dev/null; then
    pkill -SIGINT -x wl-screenrec
    pkill -RTMIN+8 waybar 2>/dev/null || true
    exit 0
fi

VIDEOS_DIR="$HOME/Wideo"
mkdir -p "$VIDEOS_DIR"

GEOM=$(slurp)
if [ -z "$GEOM" ]; then
    exit 0
fi

OUTPUT_FILE="$VIDEOS_DIR/Nagranie_$(date +'%Y-%m-%d_%H-%M-%S').mp4"

"$RECORDER" -g "$GEOM" -f "$OUTPUT_FILE" >/dev/null 2>&1 &
pkill -RTMIN+8 waybar 2>/dev/null || true
