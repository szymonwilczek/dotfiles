;;; Project management and Perspective session integration

(use-package perspective
  :ensure t
  :custom
  (persp-mode-prefix-key (kbd "C-c M-p"))
  (persp-kill-foreign-buffer t)
  :init
  (persp-mode 1))

(use-package projectile
  :ensure t
  :init
  (projectile-mode 1)
  :config
  (setq projectile-project-search-path
        (cl-remove-if-not #'file-directory-p '("~/Dokumenty/GitHub" "~/workspace" "~/projects")))
  (setq projectile-switch-project-action #'projectile-find-file
        projectile-indexing-method 'alien
        projectile-enable-caching t))

(use-package persp-projectile
  :ensure t
  :after (perspective projectile))

(use-package treemacs-perspective
  :ensure t
  :after (treemacs perspective)
  :config
  (treemacs-set-scope-type 'Perspectives))

(use-package treemacs-projectile
  :ensure t
  :after (treemacs projectile))

(require 'projectile-keys)

(provide 'projectile-mod)
