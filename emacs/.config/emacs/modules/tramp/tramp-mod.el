;;; TRAMP remote access and SSH configuration -*- lexical-binding: t; -*-

(use-package tramp
  :ensure nil
  :custom
  (tramp-default-method "ssh")
  (tramp-use-ssh-controlmaster-options nil)
  (tramp-use-scp-direct-remote-copying t)
  (tramp-copy-size-limit (* 1024 1024))
  (tramp-connection-timeout 10)
  (tramp-terminal-type "tramp")
  (tramp-verbose 1)

  ;; Caching and performance
  (remote-file-name-inhibit-cache nil)
  (tramp-completion-reread-directory-timeout 120)
  (password-cache-expiry 3600)

  ;; Lockfiles and autosave
  (remote-file-name-inhibit-locks t)
  (remote-file-name-inhibit-auto-save t)
  (remote-file-name-inhibit-auto-save-visited t)
  (tramp-auto-save-directory (expand-file-name "tramp-autosave" user-emacs-directory))

  :config
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path)

  ;; Disable VC on remote files
  (setq vc-ignore-dir-regexp
        (format "\\(%s\\)\\|\\(%s\\)"
                vc-ignore-dir-regexp
                tramp-file-name-regexp))

  (defun my/tramp-optimize-remote-buffer ()
    "Disable heavy background hooks on remote files to prevent UI freezes."
    (when (file-remote-p (or buffer-file-name default-directory))
      (setq-local vc-handled-backends nil)
      (when (bound-and-true-p git-gutter-mode)
        (git-gutter-mode -1))))

  (add-hook 'find-file-hook #'my/tramp-optimize-remote-buffer)
  (add-hook 'dired-mode-hook #'my/tramp-optimize-remote-buffer)

  (with-eval-after-load 'projectile
    (setq projectile-enable-caching t)))

(require 'tramp-keys)

(provide 'tramp-mod)
