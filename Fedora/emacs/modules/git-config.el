(use-package magit
  :ensure t
  :commands (magit-status magit-dispatch magit-file-dispatch))

(setq epa-pinentry-mode 'loopback)

(use-package diff-hl
  :ensure t
  :config
  (global-diff-hl-mode)
  (diff-hl-flydiff-mode)
  (unless (display-graphic-p)
    (diff-hl-margin-mode))
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh))

(provide 'git-config)
