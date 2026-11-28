;;; Talos 7 Companion host bridge integration -*- lexical-binding: t; -*-

(let ((talos-el (expand-file-name
                 "~/Dokumenty/GitHub/talos-7/emacs/talos-companion.el")))
  (when (file-exists-p talos-el)
    (add-to-list 'load-path (file-name-directory talos-el))
    (require 'talos-companion)
    (talos-companion-mode 1)))

(provide 'talos-mod)
