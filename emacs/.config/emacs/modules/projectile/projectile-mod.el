;;; Project management and Perspective session integration -*- lexical-binding: t; -*-

(use-package perspective
  :ensure t
  :custom
  (persp-mode-prefix-key (kbd "C-c M-p"))
  (persp-kill-foreign-buffer t)
  (persp-state-default-file nil)
  (persp-auto-save-persps-to-file-p nil)
  (persp-auto-resume-time -1)
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
        projectile-enable-caching t
        projectile-auto-discover t)
  (projectile-discover-projects-in-search-path)

  (defun my/projectile-auto-discover-advice (&rest _args)
    "Re-discover projects in search path before switching."
    (when projectile-project-search-path
      (let ((inhibit-message t))
        (projectile-discover-projects-in-search-path))))

  (advice-add 'projectile-switch-project :before #'my/projectile-auto-discover-advice)
  (advice-add 'projectile-persp-switch-project :before #'my/projectile-auto-discover-advice))

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
