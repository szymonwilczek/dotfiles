#!/bin/bash
raw_sinks=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -E '[0-9]+\.')

sinks_data=""
clean_names=""

while IFS= read -r line; do
    is_active=0
    if echo "$line" | grep -q '\*'; then
        is_active=1
    fi
    id=$(echo "$line" | grep -oE '[0-9]+\.' | head -1 | tr -d '.')
    name=$(echo "$line" | sed -E 's/^[│ *]*[0-9]+\.\s*//; s/\[vol:.*\]//; s/\s+$//')

    if [ -n "$id" ] && [ -n "$name" ]; then
        if [ $is_active -eq 1 ]; then
            display_name="● ${name}"
        else
            display_name="  ${name}"
        fi
        sinks_data="${sinks_data}${display_name}	${id}\n"
        clean_names="${clean_names}${display_name}\n"
    fi
done <<<"$raw_sinks"

selected_line=$(printf "%b" "$clean_names" | grep -v '^$' | fuzzel -d -p "󰓃  : " -w 55)

if [ -n "$selected_line" ]; then
    selected_id=$(printf "%b" "$sinks_data" | grep "^${selected_line}	" | cut -f2)
    if [ -n "$selected_id" ]; then
        wpctl set-default "$selected_id"
    fi
fi
