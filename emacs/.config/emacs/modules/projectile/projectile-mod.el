;;; Project management configuration

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

(use-package treemacs-projectile
  :ensure t
  :after (treemacs projectile))

(require 'projectile-keys)

(provide 'projectile-mod)
