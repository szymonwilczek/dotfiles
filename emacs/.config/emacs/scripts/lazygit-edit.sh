#!/bin/sh
FILE="$1"
LINE="${2:-1}"

emacsclient -e "(progn
  (when (get-buffer \"*lazygit*\")
    (kill-buffer \"*lazygit*\"))
  (let ((buf (find-file-noselect \"$FILE\")))
    (pop-to-buffer-same-window buf)
    (goto-char (point-min))
    (forward-line (1- $LINE))
    (recenter)
    (select-frame-set-input-focus (selected-frame))
    (when (fboundp 'global-hl-line-highlight)
      (global-hl-line-highlight))
    (when (fboundp 'hl-line-highlight)
      (hl-line-highlight))
    (run-hooks 'post-command-hook)
    t))"
