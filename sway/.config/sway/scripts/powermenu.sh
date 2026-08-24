#!/bin/sh

SELECTION=$(echo -e "󰍃  Wyloguj\n󰜉  Uruchom ponownie\n  Wyłącz" | fuzzel \
	--dmenu \
	--prompt="Zasilanie: " \
	--width=25 \
	--lines=3 \
	--font="Typus Mono:size=12,JetBrainsMono Nerd Font:size=12" \
	--background-color=121212f0 \
	--text-color=707070ff \
	--match-color=f5f5f5ff \
	--selection-color=2c2c2cff \
	--selection-text-color=f5f5f5ff \
	--border-color=abababff \
	--border-width=2 \
	--border-radius=0)

case "$SELECTION" in
*"Wyloguj"*) swaymsg exit ;;
*"Uruchom ponownie"*) systemctl reboot ;;
*"Wyłącz"*) systemctl poweroff ;;
esac
