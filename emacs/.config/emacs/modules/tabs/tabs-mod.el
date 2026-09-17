;;; -*- lexical-binding: t; -*-
(use-package bufferline
  :load-path "~/Dokumenty/GitHub/bufferline.el"
  :demand t
  :custom
  (bufferline-separator-style 'vertical)
  (bufferline-show-special-buffers nil)
  :config
  (setq bufferline-show-special-buffers nil)
  (global-bufferline-mode 1))

(require 'tabs-keys)

(provide 'tabs-mod)
