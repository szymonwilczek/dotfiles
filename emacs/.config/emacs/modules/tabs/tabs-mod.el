;;; -*- lexical-binding: t; -*-
(use-package bufferline
  :load-path "~/Dokumenty/GitHub/bufferline.el"
  :demand t
  :custom
  (bufferline-separator-style 'vertical)
  :config
  (global-bufferline-mode 1))

(require 'tabs-keys)

(provide 'tabs-mod)
