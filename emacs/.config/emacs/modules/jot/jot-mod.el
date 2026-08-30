;;; -*- lexical-binding: t; -*-

(use-package jot
  :load-path "~/Dokumenty/GitHub/jot.el"
  :demand t
  :custom
  (jot-dir (expand-file-name "~/.local/share/tmux-jot"))
  (jot-extension "md")
  (jot-default-mode 'markdown-mode)
  (jot-session-backend 'auto)
  (jot-popup-x 'right)
  (jot-popup-y 0)
  (jot-popup-width 0.40)
  (jot-popup-height 0.50)
  :config
  (jot-mode 1))

(require 'jot-keys)

(provide 'jot-mod)
