#!/bin/bash

# Kolory i ikony (dostosuj do swoich potrzeb i czcionki)
SAPPHIRE="#74c7ec"       # Kolor dla logo Arch (Catppuccin Sapphire)
TEXT_COLOR="#cdd6f4"     # Główny tekst (Catppuccin Text)
SUBTEXT_COLOR="#a6adc8"  # Podtekst (Catppuccin Subtext0)
CAVA_COLOR="#a6e3a1"     # Kolor dla wizualizacji Cava (Catppuccin Green)

ARCH_ICON=""
# Znaki Unicode dla słupków Cava (9 poziomów, indeksy 0-8)
CAVA_BARS=( " " " " "▂" "▃" "▄" "▅" "▆" "▇" "█" )

# Domyślny format (tylko logo Arch)
DEFAULT_TEXT_FORMAT="<span color='${SAPPHIRE}' font_weight='bold' size='large'>${ARCH_ICON}</span>"
DEFAULT_CLASS="arch-logo-only"
DEFAULT_TOOLTIP="Centrum Multimediów"

# Inicjalizacja
TEXT_OUTPUT="$DEFAULT_TEXT_FORMAT"
CURRENT_CLASS="$DEFAULT_CLASS"
TOOLTIP_TEXT="$DEFAULT_TOOLTIP"

PLAYER_STATUS=$(playerctl status 2>/dev/null)

if [ "$PLAYER_STATUS" = "Playing" ]; then
    TITLE_RAW=$(playerctl metadata title 2>/dev/null)
    TITLE=${TITLE_RAW:-""} # Pusty, jeśli nie ma tytułu
    DISPLAY_TITLE=$(echo "$TITLE" | cut -c1-20); [[ ${#TITLE} -gt 20 ]] && DISPLAY_TITLE="$DISPLAY_TITLE..."

    # Pobierz output z cava, upewnij się, że zwraca tylko cyfry 0-8
    CAVA_RAW_OUTPUT=$(stdbuf -o0 timeout 0.2s cava -p "$HOME/.config/cava/config" 2>/dev/null | head -n 1 | tr -cd '0-8')
    
    VISUALIZATION=""
    if [ -n "$CAVA_RAW_OUTPUT" ] && [[ "$CAVA_RAW_OUTPUT" =~ ^[0-8]+$ ]]; then
        for (( i=0; i<${#CAVA_RAW_OUTPUT}; i++ )); do
            HEIGHT_INDEX=${CAVA_RAW_OUTPUT:$i:1}
            if [ "$HEIGHT_INDEX" -ge 0 ] && [ "$HEIGHT_INDEX" -lt ${#CAVA_BARS[@]} ]; then
                VISUALIZATION+="${CAVA_BARS[$HEIGHT_INDEX]}"
            else
                VISUALIZATION+="${CAVA_BARS[0]}" 
            fi
        done
    else
        VISUALIZATION="~🎶~" # Fallback, jeśli cava nie da dobrego outputu
    fi
    
    # Format: Wizualizacja Cava | Tytuł Utworu (Logo Arch jest teraz tłem/częścią wyspy)
    # Możesz zdecydować, czy logo Arch ma być nadal widoczne obok Cavy, czy Cava ma je zastępować.
    # Poniżej przykład, gdzie Cava i tytuł są główną treścią, a logo jest implikowane przez samą "wyspę".
    TEXT_OUTPUT="<span font_family='Hack Nerd Font Mono' color='${CAVA_COLOR}' size='medium'>${VISUALIZATION}</span> <span color='${SUBTEXT_COLOR}' size='small'>${DISPLAY_TITLE}</span>"
    CURRENT_CLASS="media-playing" # Zmieniamy klasę na ogólną "media-playing"
    TOOLTIP_TEXT="Gra: ${TITLE} (Kliknij po kontrolki)"

elif [ "$PLAYER_STATUS" = "Paused" ]; then
    TITLE_RAW=$(playerctl metadata title 2>/dev/null)
    TITLE=${TITLE_RAW:-"Wstrzymano"}
    DISPLAY_TITLE=$(echo "$TITLE" | cut -c1-20); [[ ${#TITLE} -gt 20 ]] && DISPLAY_TITLE="$DISPLAY_TITLE..."
    # Kiedy spauzowane, pokaż logo Arch i ikonę pauzy oraz tytuł
    TEXT_OUTPUT="<span color='${SAPPHIRE}' font_weight='bold' size='large'>${ARCH_ICON}</span> <span color='${TEXT_COLOR}' size='small'> ${DISPLAY_TITLE}</span>"
    CURRENT_CLASS="media-paused"
    TOOLTIP_TEXT="$TITLE (Pauza)"
fi

# Escapowanie cudzysłowów dla JSON
TOOLTIP_TEXT_ESCAPED=$(echo "$TOOLTIP_TEXT" | sed 's/"/\\"/g' | tr -d '\n\r')

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$TEXT_OUTPUT" "$TOOLTIP_TEXT_ESCAPED" "$CURRENT_CLASS"
