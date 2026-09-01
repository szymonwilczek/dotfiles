;;; TRAMP remote access and SSH configuration -*- lexical-binding: t; -*-

(use-package tramp
  :ensure nil
  :custom
  (tramp-default-method "ssh")
  (tramp-use-ssh-controlmaster-options nil)
  (remote-file-name-inhibit-cache nil)
  (tramp-verbose 1)
  (tramp-auto-save-directory (expand-file-name "tramp-autosave" user-emacs-directory))
  :config
  (with-eval-after-load 'projectile
    (setq projectile-enable-caching t)))

(require 'tramp-keys)

(provide 'tramp-mod)
