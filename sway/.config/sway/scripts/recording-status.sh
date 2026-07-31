#!/bin/bash
IS_REC=0
IS_DRAW=0

if pgrep -x wl-screenrec >/dev/null; then
    IS_REC=1
fi

if pgrep -i gromit-mpx >/dev/null; then
    IS_DRAW=1
fi

if [ $IS_REC -eq 1 ] && [ $IS_DRAW -eq 1 ]; then
    echo '{"text": "🔴 ✏️", "class": "active"}'
elif [ $IS_REC -eq 1 ]; then
    echo '{"text": "🔴", "class": "recording"}'
elif [ $IS_DRAW -eq 1 ]; then
    echo '{"text": "✏️", "class": "drawing"}'
else
    echo '{"text": "", "class": "idle"}'
fi
