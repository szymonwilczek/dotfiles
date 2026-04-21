#!/bin/bash

export PATH="$PATH:$HOME/.local/bin:/usr/local/bin:/usr/bin"

DIR="/home/wolfie/Pulpit/Personalne/Tapety"
CACHE="$HOME/.cache/current_wallpaper"
WAL_FILE="$HOME/.cache/wal/colors-hyprland.conf"

list_wallpapers() {
    for file in "$DIR"/*; do
        [[ -f "$file" ]] && echo -en "$file\0icon\x1f$file\n"
    done
}

selected=$(list_wallpapers | rofi -dmenu -i -theme ~/.config/rofi/wallpaper.rasi)

if [ -z "$selected" ]; then exit 0; fi

echo "$selected" > "$CACHE"
swww img "$selected" --transition-type grow --transition-duration 0.5 --transition-fps 144

wal -i "$selected" --backend colorthief -n -q -s -t || wal -i "$selected" -n -q -s -t

source "$HOME/.cache/wal/colors.sh" || true

# fallback
color1=${color1:-"#33ccff"}
color2=${color2:-"#00ff99"}

C1="rgba(${color1:1}ee)"
C2="rgba(${color2:1}ee)"

echo "\$color1 = $C1" > "$WAL_FILE"
echo "\$color2 = $C2" >> "$WAL_FILE"

hyprctl reload
pkill -USR2 waybar

bash ~/.config/hypr/scripts/gtk4-pywal.sh

notify-send -a "Menedżer Tapet" "🎨 Nowa tapeta" "Tapeta została zmieniona!"
