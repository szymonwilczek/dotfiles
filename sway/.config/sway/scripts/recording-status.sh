#!/bin/bash
if pgrep -x wl-screenrec >/dev/null; then
    echo '{"text": "🔴", "class": "recording"}'
else
    echo '{"text": "", "class": "idle"}'
fi
