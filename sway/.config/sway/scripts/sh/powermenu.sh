#!/bin/sh

SELECTION=$(echo -e "󰍃  Wyloguj\n󰜉  Uruchom ponownie\n  Wyłącz" | fuzzel \
	                                                               --dmenu \
	                                                               --prompt="Zasilanie: " \
	                                                               --width=25 \
	                                                               --lines=3 \
	                                                               --font="Typus Mono 95:size=12,JetBrainsMono Nerd Font:size=12" \
	                                                               --background-color=121212f0 \
	                                                               --text-color=6e6e6eff \
	                                                               --match-color=b2b2b2ff \
	                                                               --selection-color=2c2c2cff \
	                                                               --selection-text-color=b2b2b2ff \
	                                                               --border-color=707070ff \
	                                                               --border-width=2 \
	                                                               --border-radius=0)

case "$SELECTION" in
    *"Wyloguj"*) swaymsg exit ;;
    *"Uruchom ponownie"*) systemctl reboot ;;
    *"Wyłącz"*) systemctl poweroff ;;
esac
