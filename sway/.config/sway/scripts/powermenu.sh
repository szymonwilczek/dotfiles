#!/bin/sh

SELECTION=$(echo -e "󰍃  Wyloguj\n󰜉  Uruchom ponownie\n  Wyłącz" | fuzzel \
	--dmenu \
	--prompt="Zasilanie: " \
	--width=25 \
	--lines=3 \
	--font="JetBrainsMono Nerd Font:size=12" \
	--background-color=222222ff \
	--text-color=ffffffff \
	--match-color=4c7899ff \
	--selection-color=4c7899ff \
	--selection-text-color=ffffffff \
	--border-color=4c7899ff \
	--border-width=2 \
	--border-radius=0)

case "$SELECTION" in
*"Wyloguj"*) swaymsg exit ;;
*"Uruchom ponownie"*) systemctl reboot ;;
*"Wyłącz"*) systemctl poweroff ;;
esac
