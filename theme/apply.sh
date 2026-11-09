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

# convert '#RRGGBB' to 'rgb(r, g, b)'
hex_to_rgb() {
    local hex="${1#"#"}"
                    printf "rgb(%d, %d, %d)" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
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

# Sway modals GTK colors: sway/.config/sway/modal/colors.css
mkdir -p "${DOTFILES_DIR}/sway/.config/sway/modal"
cat <<EOF >"${DOTFILES_DIR}/sway/.config/sway/modal/colors.css"
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
cat <<EOF >"${DOTFILES_DIR}/sway/.config/sway/scripts/sh/powermenu.sh"
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
chmod +x "${DOTFILES_DIR}/sway/.config/sway/scripts/sh/powermenu.sh"

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

# Firefox theme 'simple': theme/firefox/{userChrome,userContent}.css
FF_DIR="${DOTFILES_DIR}/theme/firefox"
mkdir -p "$FF_DIR"

# Theme API key -> palette
FF_FRAME="${COLOR_BG_DARK}"                          # frame
FF_FRAME_INACTIVE="${COLOR_BG_DARK}"                 # frame_inactive
FF_TAB_BG_TEXT="${COLOR_TEXT_MAIN}"                  # tab_background_text
FF_TAB_SELECTED="${COLOR_BG_ACTIVE}"                 # tab_selected
FF_TAB_TEXT="${COLOR_TEXT_FOCUSED}"                  # tab_text
FF_TAB_LINE="${COLOR_BORDER_FOCUSED}"                # tab_line
FF_TAB_LOADING="${COLOR_TEXT_FOCUSED}"               # tab_loading
FF_TAB_SEPARATOR="${COLOR_BORDER_INACTIVE}"          # tab_background_separator
FF_TAB_HOVER="${COLOR_BORDER_UNFOCUSED}"
FF_TOOLBAR="${COLOR_BG_SURFACE}"                     # toolbar
FF_TOOLBAR_TEXT="${COLOR_TEXT_FOCUSED}"              # toolbar_text
FF_ICONS="${COLOR_TEXT_FOCUSED}"                     # icons
FF_ICONS_ATTENTION="${COLOR_ACCENT_URGENT}"          # icons_attention
FF_BUTTON_HOVER="${COLOR_BG_ACTIVE}"                 # button_background_hover
FF_BUTTON_ACTIVE="${COLOR_BORDER_INACTIVE}"          # button_background_active
FF_FIELD="${COLOR_BG_DARK}"                          # toolbar_field
FF_FIELD_TEXT="${COLOR_TEXT_FOCUSED}"                # toolbar_field_text
FF_FIELD_BORDER="${COLOR_BG_DARK}"                   # toolbar_field_border (= field: no seam)
FF_FIELD_FOCUS="${COLOR_BG_DARK}"                    # toolbar_field_focus
FF_FIELD_TEXT_FOCUS="${COLOR_TEXT_FOCUSED}"          # toolbar_field_text_focus
FF_FIELD_BORDER_FOCUS="${COLOR_BORDER_FOCUSED}"      # toolbar_field_border_focus
FF_FIELD_HIGHLIGHT="${COLOR_BORDER_FOCUSED}"         # toolbar_field_highlight
FF_FIELD_HIGHLIGHT_TEXT="${COLOR_BG_DARK}"           # toolbar_field_highlight_text
FF_FIELD_SEPARATOR="${COLOR_BORDER_INACTIVE}"        # toolbar_field_separator
FF_TOP_SEPARATOR="transparent"                       # toolbar_top_separator
FF_BOTTOM_SEPARATOR="transparent"                    # toolbar_bottom_separator
FF_VERTICAL_SEPARATOR="${COLOR_BORDER_INACTIVE}"     # toolbar_vertical_separator
FF_POPUP="${COLOR_BG_SURFACE}"                       # popup
FF_POPUP_TEXT="${COLOR_TEXT_FOCUSED}"                # popup_text
FF_POPUP_BORDER="${COLOR_BORDER_INACTIVE}"           # popup_border
FF_POPUP_HIGHLIGHT="${COLOR_BG_ACTIVE}"              # popup_highlight
FF_POPUP_HIGHLIGHT_TEXT="${COLOR_TEXT_FOCUSED}"      # popup_highlight_text
FF_SIDEBAR="${COLOR_BG_SURFACE}"                     # sidebar
FF_SIDEBAR_TEXT="${COLOR_TEXT_FOCUSED}"              # sidebar_text
FF_SIDEBAR_BORDER="${COLOR_BORDER_SUBTLE}"           # sidebar_border
FF_SIDEBAR_HIGHLIGHT="${COLOR_BG_ACTIVE}"            # sidebar_highlight
FF_SIDEBAR_HIGHLIGHT_TEXT="${COLOR_TEXT_FOCUSED}"    # sidebar_highlight_text
FF_NTP="${COLOR_BG_DARK}"                            # ntp_background
FF_NTP_CARD="${COLOR_BG_SURFACE}"                    # ntp_card_background
FF_NTP_TEXT="${COLOR_TEXT_FOCUSED}"                  # ntp_text
FF_ACCENT="${COLOR_BORDER_FOCUSED}"                  # focus rings, primary buttons, links

cat <<EOF >"${FF_DIR}/userChrome.css"
/* Generated automatically by dotfiles/theme/apply.sh - DO NOT EDIT MANUALLY */
/* Edit dotfiles/theme/colors.sh instead! */
/* Firefox theme 'simple': colors only, stock Proton geometry and fonts. */

:root {
  /* frame, frame_inactive, tab_background_text */
  --lwt-accent-color: ${FF_FRAME} !important;
  --lwt-accent-color-inactive: ${FF_FRAME_INACTIVE} !important;
  --lwt-text-color: ${FF_TAB_BG_TEXT} !important;
  --toolbox-background-color: ${FF_FRAME} !important;
  --toolbox-background-color-inactive: ${FF_FRAME_INACTIVE} !important;
  --toolbox-text-color: ${FF_TAB_BG_TEXT} !important;
  --toolbox-text-color-inactive: ${FF_TAB_BG_TEXT} !important;
  --lwt-header-image: none !important;
  --lwt-additional-images: none !important;

  /* tab_selected, tab_text, tab_line, tab_loading, tab_background_separator */
  --tab-background-color-selected: ${FF_TAB_SELECTED} !important;
  --tab-text-color: ${FF_TAB_BG_TEXT} !important;
  --tab-text-color-hover: ${FF_TAB_TEXT} !important;
  --tab-text-color-selected: ${FF_TAB_TEXT} !important;
  --tab-background-color-hover: ${FF_TAB_HOVER} !important;
  --lwt-tab-line-color: ${FF_TAB_LINE} !important;
  --tab-border-color-selected: ${FF_TAB_LINE} !important;
  --tab-icon-fill-loading: ${FF_TAB_LOADING} !important;
  --lwt-background-tab-separator-color: ${FF_TAB_SEPARATOR} !important;

  /* toolbar, toolbar_text, icons, icons_attention */
  --toolbar-background-color: ${FF_TOOLBAR} !important;
  --toolbar-text-color: ${FF_TOOLBAR_TEXT} !important;
  --toolbar-color: ${FF_TOOLBAR_TEXT} !important;
  --toolbarbutton-icon-fill: ${FF_ICONS} !important;
  --toolbarbutton-icon-fill-attention: ${FF_ICONS_ATTENTION} !important;
  --toolbarbutton-icon-fill-attention-text: ${FF_FRAME} !important;

  /* button_background_hover, button_background_active */
  --toolbarbutton-background-color-hover: ${FF_BUTTON_HOVER} !important;
  --toolbarbutton-background-color-active: ${FF_BUTTON_ACTIVE} !important;

  /* toolbar_field*, toolbar_field_focus, toolbar_field_highlight* */
  --toolbar-field-background-color: ${FF_FIELD} !important;
  --toolbar-field-text-color: ${FF_FIELD_TEXT} !important;
  --toolbar-field-border-color: ${FF_FIELD_BORDER} !important;
  --toolbar-field-background-color-focus: ${FF_FIELD_FOCUS} !important;
  --toolbar-field-text-color-focus: ${FF_FIELD_TEXT_FOCUS} !important;
  --toolbar-field-border-color-focus: ${FF_FIELD_BORDER_FOCUS} !important;
  --lwt-toolbar-field-highlight: ${FF_FIELD_HIGHLIGHT} !important;
  --lwt-toolbar-field-highlight-text: ${FF_FIELD_HIGHLIGHT_TEXT} !important;
  /* toolbar_field_separator: Firefox >= 89 draws no separator in the urlbar,
     the legacy variable is kept so the key stays covered if it comes back */
  --urlbar-separator-color: ${FF_FIELD_SEPARATOR} !important;

  /* toolbar_top_separator, toolbar_bottom_separator, toolbar_vertical_separator */
  --tabs-navbar-separator-color: ${FF_TOP_SEPARATOR} !important;
  --tabs-navbar-separator-style: none !important;
  --chrome-content-separator-color: ${FF_BOTTOM_SEPARATOR} !important;
  --toolbarseparator-color: ${FF_VERTICAL_SEPARATOR} !important;

  /* popup, popup_text, popup_border, popup_highlight, popup_highlight_text */
  --panel-background-color: ${FF_POPUP} !important;
  --panel-text-color: ${FF_POPUP_TEXT} !important;
  --panel-border-color: ${FF_POPUP_BORDER} !important;
  --urlbarview-background-color-selected: ${FF_POPUP_HIGHLIGHT} !important;
  --urlbarview-text-color-selected: ${FF_POPUP_HIGHLIGHT_TEXT} !important;

  /* sidebar, sidebar_text, sidebar_border, sidebar_highlight, sidebar_highlight_text */
  --sidebar-background-color: ${FF_SIDEBAR} !important;
  --sidebar-text-color: ${FF_SIDEBAR_TEXT} !important;
  --sidebar-border-color: ${FF_SIDEBAR_BORDER} !important;
  --lwt-sidebar-highlight-background-color: ${FF_SIDEBAR_HIGHLIGHT} !important;
  --lwt-sidebar-highlight-text-color: ${FF_SIDEBAR_HIGHLIGHT_TEXT} !important;

  /* ntp_background, ntp_card_background, ntp_text (popups over the new tab page) */
  --tabpanel-background-color: ${FF_NTP} !important;
  --newtab-background-color: ${FF_NTP} !important;
  --newtab-background-color-secondary: ${FF_NTP_CARD} !important;
  --newtab-text-primary-color: ${FF_NTP_TEXT} !important;

  /* Proton grays */
  --color-gray-100: ${COLOR_BG_DARK} !important;
  --color-gray-90: ${COLOR_BG_SURFACE} !important;
  --color-gray-80: ${COLOR_BORDER_UNFOCUSED} !important;
  --color-gray-70: ${COLOR_TEXT_MUTED} !important;
  --color-gray-60: ${COLOR_TEXT_MAIN} !important;
  --color-gray-50: ${COLOR_TEXT_FOCUSED} !important;

  /* Kill whathever Firefox forces */
  --focus-outline-color: ${FF_ACCENT} !important;
  --color-accent-primary: ${FF_ACCENT} !important;
  --color-accent-primary-hover: ${FF_TAB_TEXT} !important;
  --color-accent-primary-active: ${FF_TAB_TEXT} !important;
  --color-accent-attention: ${FF_ICONS_ATTENTION} !important;
  --button-background-color-primary: ${FF_ACCENT} !important;
  --button-background-color-primary-hover: ${FF_TAB_TEXT} !important;
  --button-background-color-primary-active: ${FF_TAB_TEXT} !important;
  --button-text-color-primary: ${FF_FRAME} !important;
  --link-color: ${FF_TAB_TEXT} !important;
  --link-color-hover: ${FF_TAB_TEXT} !important;
  --link-color-active: ${FF_TAB_TEXT} !important;
}

:root, #urlbar, .urlbar {
  --background-color-canvas: ${COLOR_BG_DARK} !important;
  --background-color-box: ${COLOR_BG_SURFACE} !important;
  --input-background-color: ${FF_FIELD} !important;
  --input-text-color: ${FF_FIELD_TEXT} !important;
  --button-background-color: ${COLOR_BG_ACTIVE} !important;
  --button-background-color-hover: ${COLOR_BORDER_INACTIVE} !important;
  --button-background-color-active: ${COLOR_BORDER_INACTIVE} !important;
  --button-text-color: ${COLOR_TEXT_FOCUSED} !important;
  --urlbar-box-background-color: ${COLOR_BG_ACTIVE} !important;
  --urlbar-box-background-color-hover: ${COLOR_BORDER_INACTIVE} !important;
  --urlbar-box-background-color-active: ${COLOR_BORDER_INACTIVE} !important;
  --urlbar-box-background-color-focus: ${COLOR_BG_ACTIVE} !important;
  --urlbar-box-text-color: ${COLOR_TEXT_FOCUSED} !important;
}

:root {
  background-color: ${FF_FRAME} !important;
}

richlistbox,
#fullscreen-exit-button,
tooltip,
#statuspanel-label,
#fullscreen-warning,
#pointerlock-warning {
  --tooltip-background: ${FF_POPUP} !important;
  --tooltip-foreground: ${FF_POPUP_TEXT} !important;
  --tooltip-border: ${FF_POPUP_BORDER} !important;
  background-color: ${FF_POPUP} !important;
  color: ${FF_POPUP_TEXT} !important;
  border-color: ${FF_POPUP_BORDER} !important;
}

.toolbarbutton-badge.feature-callout {
  filter: grayscale(1) !important;
}

/* Context menus and panels */
:is(menupopup, panel):not(#ctrlTab-panel) {
  --panel-background-color: ${FF_POPUP} !important;
  --panel-text-color: ${FF_POPUP_TEXT} !important;
  --panel-border-color: ${FF_POPUP_BORDER} !important;
}

:is(menupopup, panel) :is(menu, menuitem)[_moz-menuactive]:not([disabled]) {
  background-color: ${FF_POPUP_HIGHLIGHT} !important;
  color: ${FF_POPUP_HIGHLIGHT_TEXT} !important;
}

/* sidebar_highlight */
.sidebar-placesTreechildren::-moz-tree-row(selected) {
  background-color: ${FF_SIDEBAR_HIGHLIGHT} !important;
}

.sidebar-placesTreechildren::-moz-tree-cell-text(selected),
.sidebar-placesTreechildren::-moz-tree-image(selected),
.sidebar-placesTreechildren::-moz-tree-twisty(selected) {
  color: ${FF_SIDEBAR_HIGHLIGHT_TEXT} !important;
}

.item.selected > .item-title-container {
  background-color: ${FF_SIDEBAR_HIGHLIGHT} !important;
  color: ${FF_SIDEBAR_HIGHLIGHT_TEXT} !important;
}

/* toolbar_field_highlight */
#urlbar-input::selection,
.searchbar-textbox::selection {
  background-color: ${FF_FIELD_HIGHLIGHT} !important;
  color: ${FF_FIELD_HIGHLIGHT_TEXT} !important;
}
EOF

cat <<EOF >"${FF_DIR}/userContent.css"
/* Generated automatically by dotfiles/theme/apply.sh - DO NOT EDIT MANUALLY */
/* Edit dotfiles/theme/colors.sh instead! */
/* Firefox theme 'simple': ntp_background, ntp_card_background, ntp_text */

@-moz-document url-prefix("about:newtab"), url-prefix("about:home"), url-prefix("about:privatebrowsing") {
  :root {
    --newtab-background-color: ${FF_NTP} !important;
    --newtab-background-color-secondary: ${FF_NTP_CARD} !important;
    --newtab-background-card: ${FF_NTP_CARD} !important;
    --newtab-text-primary-color: ${FF_NTP_TEXT} !important;
    --newtab-primary-action-background: ${FF_ACCENT} !important;
    --focus-outline-color: ${FF_ACCENT} !important;
  }
}
EOF

ff_default_profile() {
    local base ini rel
    for base in "${HOME}/.config/mozilla/firefox" "${HOME}/.mozilla/firefox"; do
        ini="${base}/profiles.ini"
        [ -f "$ini" ] || continue
        rel=$(awk -F= '
            /^\[/ { inst = ($0 ~ /^\[Install/); prof = ($0 ~ /^\[Profile/); path = ""; p = 0; next }
            inst && $1 == "Default" && !i { i = $2 }
            prof && $1 == "Path" { path = $2 }
            prof && $1 == "Default" && $2 == "1" { p = 1 }
            prof && p && path != "" && !d { d = path }
            END { print (i != "" ? i : d) }' "$ini")
        if [ -n "$rel" ] && [ -d "${base}/${rel}" ]; then
            echo "${base}/${rel}"
            return 0
        fi
    done
    return 1
}

if FIREFOX_PROFILE="$(ff_default_profile)"; then
    mkdir -p "${FIREFOX_PROFILE}/chrome"
    ln -sfn "${FF_DIR}/userChrome.css" "${FIREFOX_PROFILE}/chrome/userChrome.css"
    ln -sfn "${FF_DIR}/userContent.css" "${FIREFOX_PROFILE}/chrome/userContent.css"

    # user.js: managed block, rewritten in place, other lines untouched
    USER_JS="${FIREFOX_PROFILE}/user.js"
    touch "$USER_JS"
    sed -i '/^\/\/ BEGIN dotfiles theme$/,/^\/\/ END dotfiles theme$/d' "$USER_JS"
    sed -i '/^user_pref("toolkit.legacyUserProfileCustomizations.stylesheets"/d' "$USER_JS"
    cat <<EOF >>"$USER_JS"
// BEGIN dotfiles theme
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");
user_pref("browser.theme.toolbar-theme", 0);
user_pref("browser.theme.content-theme", 0);
// END dotfiles theme
EOF
    echo "Firefox theme linked into ${FIREFOX_PROFILE}"
else
    echo "Firefox default profile not found, skipping" >&2
fi

# reload running waybar, its style does not watch colors.css
pkill -SIGUSR2 -x waybar 2>/dev/null || true

# reload running tmux server if active
if pgrep tmux >/dev/null 2>&1; then
    tmux source-file "${DOTFILES_DIR}/tmux/.tmux.conf" 2>/dev/null || true
fi

echo "Theme applied successfully!"
