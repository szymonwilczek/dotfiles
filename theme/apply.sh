#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source master colors
source "${SCRIPT_DIR}/colors.sh"

# strip '#' for formats needing raw hex
hex_raw() {
    echo "$1" | tr -d '#'
}

HEX_BG_DARK_RAW="$(hex_raw "$COLOR_BG_DARK")"
HEX_BG_ACTIVE_RAW="$(hex_raw "$COLOR_BG_ACTIVE")"
HEX_BORDER_FOCUSED_RAW="$(hex_raw "$COLOR_BORDER_FOCUSED")"
HEX_TEXT_MUTED_RAW="$(hex_raw "$COLOR_TEXT_MUTED")"
HEX_TEXT_FOCUSED_RAW="$(hex_raw "$COLOR_TEXT_FOCUSED")"

# Sway colors: sway/.config/sway/colors.conf
cat <<EOF >"${DOTFILES_DIR}/sway/.config/sway/colors.conf"
# Generated automatically by dotfiles/theme/apply.sh - DO NOT EDIT MANUALLY
# Edit dotfiles/theme/colors.sh instead!

# Class                 border                  background              text                    indicator               child_border
client.focused          ${COLOR_BORDER_FOCUSED} ${COLOR_BG_ACTIVE}      ${COLOR_TEXT_FOCUSED}   ${COLOR_BORDER_FOCUSED} ${COLOR_BORDER_FOCUSED}
client.focused_inactive ${COLOR_BORDER_INACTIVE} ${COLOR_BG_SURFACE}    ${COLOR_TEXT_MUTED}     ${COLOR_BORDER_INACTIVE} ${COLOR_BORDER_INACTIVE}
client.unfocused        ${COLOR_BORDER_UNFOCUSED} ${COLOR_BG_DARK}      ${COLOR_TEXT_MUTED}     ${COLOR_BORDER_UNFOCUSED} ${COLOR_BORDER_UNFOCUSED}
client.urgent           ${COLOR_ACCENT_URGENT}  #301616                 #ffffff                 ${COLOR_ACCENT_URGENT}  ${COLOR_ACCENT_URGENT}
EOF

# Waybar GTK colors: waybar/.config/waybar/colors.css
cat <<EOF >"${DOTFILES_DIR}/waybar/.config/waybar/colors.css"
/* Generated automatically by dotfiles/theme/apply.sh - DO NOT EDIT MANUALLY */
/* Edit dotfiles/theme/colors.sh instead! */

@define-color bg_dark ${COLOR_BG_DARK};
@define-color bg_surface ${COLOR_BG_SURFACE};
@define-color bg_active ${COLOR_BG_ACTIVE};
@define-color border_focused ${COLOR_BORDER_FOCUSED};
@define-color border_inactive ${COLOR_BORDER_INACTIVE};
@define-color border_subtle ${COLOR_BORDER_SUBTLE};
@define-color text_main ${COLOR_TEXT_MAIN};
@define-color text_muted ${COLOR_TEXT_MUTED};
@define-color text_focused ${COLOR_TEXT_FOCUSED};
@define-color accent_urgent ${COLOR_ACCENT_URGENT};
EOF

# SwayNC GTK colors: swaync/.config/swaync/colors.css
cat <<EOF >"${DOTFILES_DIR}/swaync/.config/swaync/colors.css"
/* Generated automatically by dotfiles/theme/apply.sh - DO NOT EDIT MANUALLY */
/* Edit dotfiles/theme/colors.sh instead! */

@define-color bg_dark ${COLOR_BG_DARK};
@define-color bg_surface ${COLOR_BG_SURFACE};
@define-color bg_active ${COLOR_BG_ACTIVE};
@define-color border_focused ${COLOR_BORDER_FOCUSED};
@define-color border_inactive ${COLOR_BORDER_INACTIVE};
@define-color border_subtle ${COLOR_BORDER_SUBTLE};
@define-color text_main ${COLOR_TEXT_MAIN};
@define-color text_muted ${COLOR_TEXT_MUTED};
@define-color text_focused ${COLOR_TEXT_FOCUSED};
@define-color accent_urgent ${COLOR_ACCENT_URGENT};
EOF

# Fuzzel config: fuzzel.ini
FUZZEL_CONTENT="[main]
font=${FONT_MAIN}:size=12,${FONT_FALLBACK}:size=12
prompt=\"❯ \"
icon-theme=Adwaita
icons-enabled=yes
show-actions=no
terminal=ghostty

width=30
horizontal-pad=25
vertical-pad=10
inner-pad=10
line-height=24
fields=filename,name,generic,exec
lines=5

[colors]
background=${HEX_BG_DARK_RAW}f0
selection=${HEX_BG_ACTIVE_RAW}ff
selection-text=${HEX_TEXT_FOCUSED_RAW}ff
text=${HEX_TEXT_MUTED_RAW}ff
match=${HEX_TEXT_FOCUSED_RAW}ff
selection-match=${HEX_TEXT_FOCUSED_RAW}ff
prompt=${HEX_TEXT_MAIN_RAW:-d4d4d4ff}
border=${HEX_BORDER_FOCUSED_RAW}ff

[border]
width=2
radius=0"

mkdir -p "${DOTFILES_DIR}/fuzzel/.config/fuzzel"
mkdir -p "${HOME}/.config/fuzzel"
echo "$FUZZEL_CONTENT" >"${DOTFILES_DIR}/fuzzel/.config/fuzzel/fuzzel.ini"
echo "$FUZZEL_CONTENT" >"${HOME}/.config/fuzzel/fuzzel.ini"

# Powermenu: powermenu.sh
cat <<EOF >"${DOTFILES_DIR}/sway/.config/sway/scripts/powermenu.sh"
#!/bin/sh

SELECTION=\$(echo -e "󰍃  Wyloguj\n󰜉  Uruchom ponownie\n  Wyłącz" | fuzzel \\
	--dmenu \\
	--prompt="Zasilanie: " \\
	--width=25 \\
	--lines=3 \\
	--font="${FONT_MAIN}:size=12,${FONT_FALLBACK}:size=12" \\
	--background-color=${HEX_BG_DARK_RAW}f0 \\
	--text-color=${HEX_TEXT_MUTED_RAW}ff \\
	--match-color=${HEX_TEXT_FOCUSED_RAW}ff \\
	--selection-color=${HEX_BG_ACTIVE_RAW}ff \\
	--selection-text-color=${HEX_TEXT_FOCUSED_RAW}ff \\
	--border-color=${HEX_BORDER_FOCUSED_RAW}ff \\
	--border-width=2 \\
	--border-radius=0)

case "\$SELECTION" in
*"Wyloguj"*) swaymsg exit ;;
*"Uruchom ponownie"*) systemctl reboot ;;
*"Wyłącz"*) systemctl poweroff ;;
esac
EOF
chmod +x "${DOTFILES_DIR}/sway/.config/sway/scripts/powermenu.sh"

# Tmux theme: tmux/.tmux/theme.conf
mkdir -p "${DOTFILES_DIR}/tmux/.tmux"
cat <<EOF >"${DOTFILES_DIR}/tmux/.tmux/theme.conf"
# Generated automatically by dotfiles/theme/apply.sh - DO NOT EDIT MANUALLY
# Edit dotfiles/theme/colors.sh instead!

# Status bar layout
set-option -g status on
set-option -g status-position bottom
set-option -g status-justify left
set-option -g status-style "bg=default,fg=${COLOR_TEXT_MAIN}"

# Left status: Session name block with active border color
set-option -g status-left-length 50
set-option -g status-left "#[bg=${COLOR_BORDER_FOCUSED},fg=${COLOR_BG_DARK},bold] #S #[bg=default,fg=default] "

# Right status: Completely empty as requested
set-option -g status-right-length 0
set-option -g status-right ""

# Window status list
set-window-option -g window-status-separator " "

# Inactive window format
set-window-option -g window-status-style "bg=${COLOR_BG_SURFACE},fg=${COLOR_TEXT_MUTED}"
set-window-option -g window-status-format "#[bg=${COLOR_BG_SURFACE},fg=${COLOR_TEXT_MUTED}] #I: #W "

# Active window format
set-window-option -g window-status-current-style "bg=${COLOR_BG_ACTIVE},fg=${COLOR_TEXT_FOCUSED},bold"
set-window-option -g window-status-current-format "#[bg=${COLOR_BG_ACTIVE},fg=${COLOR_TEXT_FOCUSED},bold] #I: #W "

# Pane borders
set-option -g pane-border-style "fg=${COLOR_BORDER_UNFOCUSED}"
set-option -g pane-active-border-style "fg=${COLOR_BORDER_FOCUSED}"

# Popup / floax / jot border colors
set -g @floax-border-color "${COLOR_BORDER_FOCUSED}"
set -g @jot-border-color "${COLOR_BORDER_FOCUSED}"

# Messages & command prompt
set-option -g message-style "bg=${COLOR_BG_SURFACE},fg=${COLOR_TEXT_FOCUSED}"
set-option -g message-command-style "bg=${COLOR_BG_SURFACE},fg=${COLOR_TEXT_FOCUSED}"
EOF

# Starship Prompt: starship.toml
STARSHIP_CONTENT="\"\$schema\" = 'https://starship.rs/config-schema.json'
format = \"\"\"
[](color_window_bg)\\
\$os\\
\$username\\
[](bg:color_session_bg fg:color_window_bg)\\
\$directory\\
[ ](fg:color_session_bg)\\
\$line_break\$character\"\"\"

palette = 'custom'

[palettes.custom]
color_session_bg = \"${COLOR_BORDER_FOCUSED}\"
color_session_fg = \"${COLOR_BG_DARK}\"
color_window_bg  = \"${COLOR_BG_ACTIVE}\"
color_window_fg  = \"${COLOR_TEXT_FOCUSED}\"
color_success    = \"${COLOR_BORDER_FOCUSED}\"
color_error      = \"${COLOR_ACCENT_URGENT}\"
color_vimcmd     = \"${COLOR_TEXT_MUTED}\"

[os]
disabled = false
style = \"bg:color_window_bg fg:color_window_fg\"

[os.symbols]
Fedora = \"󰣛\"

[username]
show_always = true
style_user = \"bg:color_window_bg fg:color_window_fg\"
style_root = \"bg:color_window_bg fg:color_window_fg\"
format = '[ \$user ](\$style)'

[directory]
style = \"fg:color_session_fg bg:color_session_bg\"
format = \"[ \$path ](\$style)\"
truncation_length = 3
truncation_symbol = \"…/\"

[line_break]
disabled = false

[character]
disabled = false
success_symbol = '[](bold fg:color_success)'
error_symbol = '[](bold fg:color_error)'
vimcmd_symbol = '[](bold fg:color_vimcmd)'
vimcmd_replace_one_symbol = '[](bold fg:color_error)'
vimcmd_replace_symbol = '[](bold fg:color_error)'
vimcmd_visual_symbol = '[](bold fg:color_success)'"

echo "$STARSHIP_CONTENT" >"${DOTFILES_DIR}/starship.toml"
echo "$STARSHIP_CONTENT" >"${HOME}/.config/starship.toml"

# Ghostty cursor theme: ghostty/.config/ghostty/theme.conf
mkdir -p "${DOTFILES_DIR}/ghostty/.config/ghostty"
cat <<EOF >"${DOTFILES_DIR}/ghostty/.config/ghostty/theme.conf"
# Generated automatically by dotfiles/theme/apply.sh - DO NOT EDIT MANUALLY
# Edit dotfiles/theme/colors.sh instead!

cursor-color = ${COLOR_BORDER_FOCUSED}
cursor-text = ${COLOR_BG_DARK}
EOF

# reload running tmux server if active
if pgrep tmux >/dev/null 2>&1; then
    tmux source-file "${DOTFILES_DIR}/tmux/.tmux.conf" 2>/dev/null || true
fi

echo "Theme applied successfully!"
