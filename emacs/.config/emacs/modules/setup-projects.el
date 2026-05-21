(use-package projectile
  :init 
  (projectile-mode +1)
  :config
  (setq projectile-project-search-path '("~/projects" "~/src"))
  
  (defun my/projectile-smart-action ()
    (let* ((name (projectile-project-name))
           (root (projectile-acquire-root))
           (has-files (my/persp-has-file-buffers-p)))

      ;; 1. Odpalanie sesji lub pustego projektu
      (cond
       (has-files
        (message "[Session] Projekt %s żyje w pamięci." name))
       ((my/session-load name root)
        (message "[Session] Odtworzono pliki i układ okien z dysku: %s" name))
       (t
        (call-interactively #'projectile-find-file)))

      ;; 2. Niezawodne odpalanie Treemacsa
      (when (featurep 'treemacs)
        (my/cancel-treemacs-annotation-timers)
        (unless (treemacs-get-local-window)
          (treemacs-select-window)
          (other-window 1))
        (treemacs-display-current-project-exclusively))))

  (setq projectile-switch-project-action #'my/projectile-smart-action))

(provide 'setup-projects)
