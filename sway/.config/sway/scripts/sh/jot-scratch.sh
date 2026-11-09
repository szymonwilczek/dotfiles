#!/bin/sh
# Toggles the SCRATCH jot note, the one tmux-jot and jot.el open in
# a SCRATCH session, in an Emacs frame kept in the sway scratchpad.
# swaymsg fails when no window has the mark, then the frame is made.

swaymsg -q '[con_mark="jot_scratch"] scratchpad show' 2>/dev/null ||
    exec emacsclient -n -c -a '' -F '((title . "jot-scratch"))' \
        -e '(my/jot-scratch-open)' >/dev/null
