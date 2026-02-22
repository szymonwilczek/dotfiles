#!/bin/bash

opcja=$(echo -e "  Wyłącz\n  Uruchom ponownie\n󰍃  Wyloguj" | wofi --dmenu --width 250 --height 210 --prompt "Zasilanie" --cache-file /dev/null)

case $opcja in
    "  Wyłącz") systemctl poweroff ;;
    "  Uruchom ponownie") systemctl reboot ;;
    "󰍃  Wyloguj") hyprctl dispatch exit ;;
esac
