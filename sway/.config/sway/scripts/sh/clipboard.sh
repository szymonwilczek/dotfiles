#!/bin/sh
# Picks an entry of the clipboard history kept by cliphist and copies
# it again, text or image alike.
# Nothing is copied when the picker is closed, so the clipboard stays as it was.

entry=$(cliphist list | fuzzel --dmenu --with-nth 2 --mesg "Schowek") || exit
[ -n "$entry" ] && printf '%s\n' "$entry" | cliphist decode | wl-copy
