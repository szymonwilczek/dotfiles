#!/bin/bash

source ~/.cache/wal/colors.sh

mkdir -p ~/.config/gtk-4.0

cat > ~/.config/gtk-4.0/gtk.css << EOF
@define-color accent_color $color1;
@define-color accent_bg_color $color1;
@define-color accent_fg_color $foreground;

@define-color window_bg_color $color1;
@define-color window_fg_color $foreground;

@define-color headerbar_bg_color $color1;
@define-color headerbar_backdrop_color $color1;
@define-color headerbar_fg_color $foreground;

@define-color view_bg_color $color1;
@define-color view_fg_color $foreground;

@define-color sidebar_bg_color $color1;
@define-color sidebar_backdrop_color $color1;
@define-color sidebar_fg_color $foreground;

@define-color card_bg_color $color0;
@define-color dialog_bg_color $color0;
@define-color popover_bg_color $color0;

window.background {
    background-color: @window_bg_color;
}
.sidebar {
    background-color: @sidebar_bg_color;
}
EOF
