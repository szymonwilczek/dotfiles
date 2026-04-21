(use-package projectile
  :init (projectile-mode +1)
  :config
  (setq projectile-project-search-path '("~/projects" "~/src"))
  (setq projectile-switch-project-action 
    (lambda ()
      (when (featurep 'treemacs)
        (treemacs-display-current-project-exclusively)
        (treemacs-select-window)))))

(with-eval-after-load 'general
  (my-leader-def
    "p"  '(:ignore t :which-key "Projects")
    "po" '(projectile-switch-project :which-key "Open Project")))

(provide 'setup-projects)
