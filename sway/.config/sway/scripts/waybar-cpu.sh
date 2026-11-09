#!/bin/bash

STATE=/tmp/waybar-cpu-prev

# read /proc/stat
while IFS=' ' read -r name user nice sys idle iowait irq softirq steal _rest; do
    [[ $name == cpu ]] && {
        curr_idle=$((idle + iowait))
        curr_total=$((user + nice + sys + idle + iowait + irq + softirq + steal))
        break
    }
done < /proc/stat

pct=0
if [[ -f $STATE ]]; then
    read -r prev_idle prev_total < "$STATE"
    d_idle=$((curr_idle - prev_idle))
    d_total=$((curr_total - prev_total))
    [[ $d_total -gt 0 ]] && pct=$(( (d_total - d_idle) * 100 / d_total ))
fi

printf '%s %s\n' "$curr_idle" "$curr_total" > "$STATE"

read -r la1 la5 la15 _ < /proc/loadavg

tooltip="load avg\\n 1m  $la1\\n 5m  $la5\\n15m  $la15"
printf '{"text": "CPU %d%%", "tooltip": "%s"}\n' "$pct" "$tooltip"
