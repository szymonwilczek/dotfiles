;;; Dired file management -*- lexical-binding: t; -*-

(use-package dired
  :ensure nil
  :custom
  (dired-listing-switches "-al --group-directories-first -h -v")
  (dired-dwim-target t)
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'top)
  (dired-auto-revert-buffer t)
  (delete-by-moving-to-trash t)
  (dired-kill-when-opening-new-dired-buffer t)
  :hook
  ((dired-mode . dired-hide-details-mode)
   (dired-mode . hl-line-mode))
  :config
  (require 'dired-x)
  ;; omit mode only hides dotfiles, shown or hidden in every dired at once
  (setq dired-omit-files "\\`[.][^.]"
        dired-omit-extensions nil
        dired-omit-verbose nil))

(defvar my/dired-show-hidden t
  "Non-nil when dired lists dotfiles.")

(defun my/dired-apply-hidden ()
  "Show or hide dotfiles in the current dired buffer per `my/dired-show-hidden'."
  (when (derived-mode-p 'dired-mode)
    (dired-omit-mode (if my/dired-show-hidden -1 1))))

(add-hook 'dired-mode-hook #'my/dired-apply-hidden)

(defun my/dired-toggle-hidden ()
  "Toggle dotfiles in all dired buffers."
  (interactive)
  (setq my/dired-show-hidden (not my/dired-show-hidden))
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (my/dired-apply-hidden)))
  (message "Hidden files %s" (if my/dired-show-hidden "shown" "hidden")))

(use-package wdired
  :ensure nil
  :after dired
  :custom
  (wdired-allow-to-change-permissions t)
  (wdired-create-parent-directories t))

(use-package nerd-icons-dired
  :ensure t
  :after (dired nerd-icons)
  :hook (dired-mode . nerd-icons-dired-mode))

(require 'dired-keys)

(provide 'dired-mod)
