#!/bin/bash
if pgrep -i gromit-mpx >/dev/null; then
    gromit-mpx --quit 2>/dev/null || pkill -i gromit-mpx
else
    gromit-mpx &
fi
pkill -RTMIN+8 waybar 2>/dev/null || true
