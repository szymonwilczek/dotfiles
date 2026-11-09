#!/bin/sh
if swaymsg -t get_tree | jq -e '.. | select(.focused? == true) | .floating == "user_on" or .floating == "auto_on"' >/dev/null; then
    swaymsg "floating disable; border pixel 2"
else
    swaymsg "floating enable; border normal 2"
fi
