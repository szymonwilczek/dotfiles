#!/bin/bash

if [ -f "$HOME/.cache/wal/colors.sh" ]; then
    . "$HOME/.cache/wal/colors.sh"
else
    echo "UWAGA: Nie znaleziono pliku kolorów pywal. Używam wartości domyślnych."
    color4="#f9e2af"  # Yellow
    color6="#89b4fa"  # Blue
    color1="#f38ba8"  # Red
    color7="#a6adc8"  # Subtext0
fi

YELLOW="${color3:-#f9e2af}"
BLUE="${color4:-#89b4fa}"
RED="${color1:-#f38ba8}"
SUBTEXT0="${color7:-#a6adc8}"
# MAUVE="${color5:-#cba6f7}"

ICON_LOGOUT="󰍃"
ICON_REBOOT=""
ICON_SHUTDOWN="󰐥"
ICON_CANCEL="󰜺"
# ICON_LOCK="󰌾"

# Opcje menu (bez zmian, używają już zmiennych)
LOGOUT_OPTION="<span color='${color7}'><b>${ICON_LOGOUT}  Logout</b></span>"
REBOOT_OPTION="<span color='${color7}'><b>${ICON_REBOOT}  Reboot</b></span>"
SHUTDOWN_OPTION="<span color='${color7}'><b>${ICON_SHUTDOWN}  Shutdown</b></span>"
CANCEL_OPTION="<span color='${color5}'><b>${ICON_CANCEL}  Anuluj</b></span>"
# LOCK_OPTION="<span color='${MAUVE}'><b>${ICON_LOCK} Zablokuj ekran</b></span>"

# Komenda Rofi (bez zmian)
ROFI_ARGS=(
    -dmenu
    -i
    -p "System"
    -markup-rows
    -theme "$HOME/.config/rofi/themes/powermenu-pywal.rasi"
    -theme-str "inputbar {enabled: false;}"
)

# Generowanie opcji dla rofi (bez zmian)
options="${LOGOUT_OPTION}\n${REBOOT_OPTION}\n${SHUTDOWN_OPTION}\n${CANCEL_OPTION}"
# Jeśli dodałeś LOCK_OPTION:
# options="${LOCK_OPTION}\n${LOGOUT_OPTION}\n${REBOOT_OPTION}\n${SHUTDOWN_OPTION}\n${CANCEL_OPTION}"

chosen_raw=$(echo -e "$options" | rofi "${ROFI_ARGS[@]}")
chosen_text_only=$(echo "$chosen_raw" | sed -e 's/<[^>]*>//g' -e 's/^[ \t]*[^ ]* //')

echo "DEBUG: chosen_text_only='${chosen_text_only}'"

# Wykonaj akcję na podstawie wyboru (bez zmian)
case "$chosen_text_only" in
    " Logout")
        hyprctl dispatch exit ""
        ;;
    " Reboot")
        systemctl reboot
        ;;
    " Shutdown")
        systemctl poweroff
        ;;
    # "Zablokuj ekran")
    #     ~/.config/hypr/scripts/lock_screen.sh
    #     ;;
    " Anuluj")
        exit 0
        ;;
esac

exit 0
