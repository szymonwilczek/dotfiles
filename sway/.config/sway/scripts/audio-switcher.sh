#!/bin/bash
selected=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -E '[0-9]+\.' | sed 's/^[│ ]*//g' | fuzzel -d -p "󰓃  : " -w 65)

if [ -n "$selected" ]; then
    id=$(echo "$selected" | sed -n 's/*\?[ ]*\([0-9]\+\)\..*/\1/p')
    if [ -n "$id" ]; then
        wpctl set-default "$id"
    fi
fi
