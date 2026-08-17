(use-package projectile
  :init 
  (projectile-mode +1)
  :config
  (setq projectile-project-search-path '("~/Dokumenty/GitHub" "~/workspace" "~/projects"))
  (setq projectile-project-search-path
        (cl-remove-if-not #'file-directory-p projectile-project-search-path))
  (setq projectile-switch-project-action #'projectile-find-file))

(provide 'setup-projects)
