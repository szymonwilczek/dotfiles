;;; -*- lexical-binding: t; -*-
(use-package bufferline
  :load-path "~/Dokumenty/GitHub/bufferline.el"
  :demand t
  :custom
  (bufferline-separator-style 'vertical)
  :config
  (setq bufferline-show-special-buffers t)
  (global-bufferline-mode 1)

  (defun my/bufferline-persp-filter (tabs)
    "Keep only TABS belonging to the current perspective."
    (if (bound-and-true-p persp-mode)
        (seq-filter (lambda (buf) (persp-is-current-buffer buf)) tabs)
      tabs))

  (advice-add 'bufferline-buffers-all :filter-return #'my/bufferline-persp-filter))

(require 'tabs-keys)

(provide 'tabs-mod)
