;;; -*- lexical-binding: t; -*-

(use-package jot
  :load-path "~/Dokumenty/GitHub/jot.el"
  :demand t
  :custom
  (jot-extension "md")
  (jot-default-mode markdown-mode)
  (jot-session-backend auto)
  (jot-popup-x right)
  (jot-popup-y 0)
  (jot-popup-width 0.40)
  (jot-popup-height 0.50)
  :config
  (setq jot-dir (expand-file-name "~/.local/share/tmux-jot"))
  (jot-mode 1))

(require 'jot-keys)

(provide 'jot-mod)
