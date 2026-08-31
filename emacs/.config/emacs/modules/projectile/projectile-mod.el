;;; Project management and Perspective session integration -*- lexical-binding: t; -*-

(use-package perspective
  :ensure t
  :custom
  (persp-mode-prefix-key (kbd "C-c M-p"))
  (persp-state-default-file nil)
  (persp-auto-save-persps-to-file-p nil)
  (persp-auto-resume-time -1)
  (persp-suppress-no-prefix-key-warning t)
  (persp-initial-frame-name "main")
  :init
  (persp-mode 1)
  :config

  (defun my/persp-safe-check-persp (orig-fn persp)
    "Prevent fatal errors on killed/nil perspectives by self-healing frame state."
    (if (or (null persp) (persp-killed-p persp))
        (let* ((names (persp-names))
               (fallback (or (car names) persp-initial-frame-name "main")))
          (when (and (persp-last) (persp-killed-p (persp-last)))
            (set-frame-parameter nil 'persp--last nil))
          (when (and (persp-curr) (persp-killed-p (persp-curr)))
            (set-frame-parameter nil 'persp--curr (gethash fallback (perspectives-hash)))))
      (funcall orig-fn persp)))

  (advice-add 'check-persp :around #'my/persp-safe-check-persp)

  (defun my/persp-safe-activate (orig-fn persp &rest args)
    "Ensure PERSP is live and registered before activating.
If killed or missing, seamlessly fall back to an active perspective."
    (let ((target-persp
           (cond
            ((and persp
                  (not (persp-killed-p persp))
                  (gethash (persp-name persp) (perspectives-hash)))
             persp)
            (t
             (let* ((names (persp-names))
                    (fallback-name (or (car names) persp-initial-frame-name "main"))
                    (fallback-persp (gethash fallback-name (perspectives-hash))))
               (or fallback-persp (persp-new fallback-name)))))))
      (apply orig-fn target-persp args)))

  (advice-add 'persp-activate :around #'my/persp-safe-activate)

  (defun my/persp-cleanup-killed-frame-refs (&rest _args)
    "Purge references to killed perspectives from all frame parameters."
    (dolist (frame (frame-list))
      (let ((last (frame-parameter frame 'persp--last))
            (curr (frame-parameter frame 'persp--curr)))
        (when (and last (persp-killed-p last))
          (set-frame-parameter frame 'persp--last nil))
        (when (and curr (persp-killed-p curr))
          (let* ((names (persp-names frame))
                 (fallback (or (car names) "main")))
            (set-frame-parameter frame 'persp--curr (gethash fallback (perspectives-hash frame))))))))

  (advice-add 'persp-kill :after #'my/persp-cleanup-killed-frame-refs))

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
  (run-with-idle-timer 4.0 nil #'projectile-discover-projects-in-search-path)

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
