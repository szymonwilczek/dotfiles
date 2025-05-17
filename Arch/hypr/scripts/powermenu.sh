#!/bin/bash

YELLOW="#f9e2af"
BLUE="#89b4fa"
RED="#f38ba8"
SUBTEXT0="#a6adc8"

# Ikony Nerd Fonts
ICON_LOGOUT="󰍃"       # nf-mdi-logout
ICON_REBOOT=""       # nf-fa-refresh (zmieniliśmy z emoji)
ICON_SHUTDOWN="⏻"     # nf-mdi-power
ICON_CANCEL="󰅙"       # nf-mdi-close_circle_outline
# ICON_LOCK="󰌾"        # nf-mdi-lock (opcjonalnie, jeśli dodasz tę opcję)

LOGOUT_OPTION="<span color='${YELLOW}'><b>${ICON_LOGOUT}  Wyloguj</b></span>"
REBOOT_OPTION="<span color='${BLUE}'><b>${ICON_REBOOT}  Uruchom ponownie</b></span>"
SHUTDOWN_OPTION="<span color='${RED}'><b>${ICON_SHUTDOWN}  Zamknij system</b></span>"
CANCEL_OPTION="<span color='${SUBTEXT0}'><b>${ICON_CANCEL}  Anuluj</b></span>"
# LOCK_OPTION="<span color='${MAUVE}'><b>${ICON_LOCK} Zablokuj ekran</b></span>"

ROFI_ARGS=(
    -dmenu
    -i
    -p "System" # Prompt, który będzie tytułem
    -markup-rows # Włącz interpretację Pango Markup
    -theme "$HOME/.config/rofi/themes/powermenu-catppuccin.rasi" # Twój dedykowany motyw dla powermenu
    -theme-str "inputbar {enabled: false;}" # Wyłącz pasek wprowadzania
)

# Generowanie opcji dla rofi
options="${LOGOUT_OPTION}\n${REBOOT_OPTION}\n${SHUTDOWN_OPTION}\n${CANCEL_OPTION}"
# options="${LOCK_OPTION}\n${LOGOUT_OPTION}\n${REBOOT_OPTION}\n${SHUTDOWN_OPTION}\n${CANCEL_OPTION}"

chosen_raw=$(echo -e "$options" | rofi "${ROFI_ARGS[@]}")
# Usuń znaczniki Pango ORAZ ikonę z tekstem przed nią dla porównania w case
chosen_text_only=$(echo "$chosen_raw" | sed -e 's/<[^>]*>//g' -e 's/^[ \t]*[^ ]* //')

echo "DEBUG: chosen_text_only='${chosen_text_only}'"

# Wykonaj akcję na podstawie wyboru
case "$chosen_text_only" in
    " Wyloguj")
        hyprctl dispatch exit ""
        ;;
    " Uruchom ponownie")
        systemctl reboot
        ;;
    " Zamknij system")
        systemctl poweroff
        ;;
    # " Zablokuj ekran")
    #     ~/.config/hypr/scripts/lock_screen.sh # Twój skrypt do blokowania
    #     ;;
    "Anuluj")
        exit 0
        ;;
esac

exit 0
