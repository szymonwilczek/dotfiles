;;; Treemacs file explorer configuration

(use-package treemacs
  :ensure t
  :config
  (setq treemacs-no-png-images t
        treemacs-width 35
        treemacs-indentation 2
        treemacs-show-cursor nil
        treemacs-space-between-root-nodes nil
        treemacs-is-never-other-window nil)

  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-fringe-indicator-mode nil)

  (add-hook 'treemacs-mode-hook (lambda () (display-line-numbers-mode -1))))

(use-package treemacs-evil
  :ensure t
  :after (treemacs evil))

(use-package treemacs-nerd-icons
  :ensure t
  :after (treemacs nerd-icons)
  :config
  (treemacs-load-theme "nerd-icons"))

(require 'treemacs-keys)

(provide 'treemacs-mod)
