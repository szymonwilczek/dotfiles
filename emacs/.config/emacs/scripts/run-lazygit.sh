#!/bin/sh
USER_CFG="$HOME/.config/lazygit/config.yml"
OVERRIDE_CFG="$HOME/.config/emacs/.cache/lazygit-emacs.yml"

if [ -f "$USER_CFG" ]; then
    exec lazygit --use-config-file "$USER_CFG,$OVERRIDE_CFG" "$@"
else
    exec lazygit --use-config-file "$OVERRIDE_CFG" "$@"
fi
