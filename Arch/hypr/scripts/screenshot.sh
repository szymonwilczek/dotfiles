#!/bin/bash

# Domyślna akcja: wybierz obszar i skopiuj do schowka
ACTION=${1:-area_copy} # Użyj pierwszego argumentu lub domyślnej akcji

case "$ACTION" in
    area_copy)
        # Użyj slurp do wybrania obszaru
        GEOMETRY=$(slurp -d -b "#45858820" -c "#45858880" -w 2) # Możesz dostosować kolory/grubość
        if [ -z "$GEOMETRY" ]; then
            notify-send -u low -i "dialog-error" "Anulowano robienie zrzutu ekranu"
            exit 0
        fi
        # Zrób zrzut wybranego obszaru i skopiuj do schowka
        grim -g "$GEOMETRY" - | wl-copy
        notify-send -u low -i "camera-photo" "Zrzut ekranu" "Zaznaczony obszar skopiowano do schowka"
        ;;
    full_screen_copy)
        # Zrzut całego ekranu i skopiowanie do schowka
        grim - | wl-copy
        notify-send -u low -i "camera-photo" "Zrzut ekranu (pełny)" "Pełny ekran skopiowano do schowka"
        ;;
    active_window_copy)
        # Zrzut aktywnego okna i skopiowanie do schowka
        FOCUSED_WINDOW_GEOMETRY=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        if [ -z "$FOCUSED_WINDOW_GEOMETRY" ] || [ "$FOCUSED_WINDOW_GEOMETRY" == "null,null nullxnull" ]; then
            notify-send -u low -i "dialog-error" "Nie można pobrać geometrii aktywnego okna"
            exit 1
        fi
        grim -g "$FOCUSED_WINDOW_GEOMETRY" - | wl-copy
        notify-send -u low -i "camera-photo" "Zrzut ekranu (aktywne okno)" "Aktywne okno skopiowano do schowka"
        ;;
    *)
        notify-send -u critical "Błąd skryptu zrzutu ekranu" "Nieznana akcja: $ACTION"
        exit 1
        ;;
esac

exit 0
