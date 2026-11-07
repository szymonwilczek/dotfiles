#!/bin/sh
PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

expr=$(fuzzel --dmenu --prompt-only="󰃬  " --placeholder="Wpisz działanie...") || exit 0
[ -z "$expr" ] && exit 0

result=$(qalc -t "$expr" 2>/dev/null)
if [ -n "$result" ]; then
    printf "%s" "$result" | wl-copy
    notify-send -a "Kalkulator" -i accessories-calculator "Kalkulator" "$expr = $result"
else
    notify-send -a "Kalkulator" -i dialog-error "Kalkulator" "Niepoprawne wyrażenie: $expr"
fi
