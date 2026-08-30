;;; -*- lexical-binding: t; -*-
(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-undo-system 'undo-redo)
  :config
  (evil-mode 1)

  ;; Highlight on yank
  (defun my/evil-highlight-yank (orig-fn beg end &rest args)
    (let ((res (apply orig-fn beg end args)))
      (when (and (number-or-marker-p beg) (number-or-marker-p end))
        (let ((ov (make-overlay beg end)))
          (overlay-put ov 'face 'highlight)
          (overlay-put ov 'priority 1000)
          (run-at-time 0.2 nil
                       (lambda (overlay)
                         (when (overlay-buffer overlay)
                           (delete-overlay overlay)))
                       ov)))
      res))
  (advice-add 'evil-yank :around #'my/evil-highlight-yank))

(use-package evil-collection
  :after evil
  :demand t
  :config
  (setq evil-collection-mode-list (delq 'org (delq 'org-agenda evil-collection-mode-list)))
  (evil-collection-init))

(use-package evil-nerd-commenter
  :after evil
  :ensure t
  :config
  (evilnc-default-hotkeys t t))

(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1))

(use-package vundo
  :ensure t
  :custom
  (vundo-glyph-alist vundo-unicode-symbols)
  (vundo-compact-display t))

(require 'evil-keys)

(provide 'evil-mod)
