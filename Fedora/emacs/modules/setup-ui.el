(use-package emacs
  :config
  (set-face-attribute 'default nil
    :family "JetBrainsMono Nerd Font"
    :height 120
    :weight 'semi-bold))

;; (setq-default line-spacing 1)

(global-display-line-numbers-mode 1)
(global-hl-line-mode 1)
(setq-default display-line-numbers-width 3)

(use-package ef-themes
  :config (load-theme 'ef-autumn t))

(use-package which-key
  :init (which-key-mode))

(use-package nerd-icons)

(use-package treemacs-nerd-icons
  :ensure t
  :after (treemacs nerd-icons)
  :config
  (treemacs-load-theme "nerd-icons"))

(use-package treemacs
  :ensure t
  :config
  (setq treemacs-no-png-images t
    treemacs-width 40
    treemacs-indentation 2
    treemacs-show-cursor nil
    treemacs-space-between-root-nodes nil
    treemacs-is-never-other-window nil)

  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-fringe-indicator-mode nil))
(add-to-list 'default-frame-alist '(internal-border-width . 6))
(fringe-mode 10)
(add-hook 'treemacs-mode-hook (lambda () (display-line-numbers-mode -1)))
(setq treemacs-indentation 2)
(add-hook 'treemacs-mode-hook 
  (lambda () 
    (setq header-line-format " ")
    (face-remap-add-relative 'header-line
      (list :background (face-background 'default nil t)
        :box nil
        :underline nil))))


(use-package treemacs-evil
  :after (treemacs evil)
  :ensure t)

(use-package treemacs-projectile
  :after (treemacs projectile)
  :ensure t)

(defun my/save-bg-to-cache ()
  (let ((bg (face-background 'default nil t)))
    (when (and bg (string-prefix-p "#" bg))
      (with-temp-file (expand-file-name ".bg-cache" user-emacs-directory)
        (insert bg)))))

(add-hook 'after-load-theme-hook #'my/save-bg-to-cache)
(add-hook 'kill-emacs-hook #'my/save-bg-to-cache)

(provide 'setup-ui)
