;;; Project management and Perspective session integration -*- lexical-binding: t; -*-

(defvar projectile-project-name-function)

(defvar my/persp-directories nil
  "Alist of perspective names to directories opened by `my/open-directory-anywhere'.")

(use-package perspective
  :ensure t
  :custom
  (persp-mode-prefix-key (kbd "C-c M-p"))
  (persp-state-default-file nil)
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
          (let* ((names (with-selected-frame frame (persp-names)))
                 (fallback (or (car names) "main")))
            (set-frame-parameter frame 'persp--curr (gethash fallback (perspectives-hash frame))))))))

  (advice-add 'persp-kill :after #'my/persp-cleanup-killed-frame-refs)

  (add-hook 'persp-killed-hook
            (lambda ()
              (setq my/persp-directories
                    (assoc-delete-all (persp-current-name) my/persp-directories)))))

(defun my/persp-directory (name)
  "Return the directory behind perspective NAME.
A directory opened with `my/open-directory-anywhere' wins over a
Projectile known project of the same name."
  (or (cdr (assoc name (bound-and-true-p my/persp-directories)))
      (when (fboundp 'projectile-relevant-known-projects)
        (cl-find-if (lambda (p)
                      (string= (funcall projectile-project-name-function p) name))
                    (projectile-relevant-known-projects)))))

(defun my/open-directory-anywhere (dir)
  "Switch to a perspective named after DIR, starting the prompt in home.
DIR need not be a Projectile project and is not added to the known
projects; treemacs shows it as the perspective's only root.  A new
perspective opens DIR in dired, an existing one is just switched to."
  (interactive
   (list (read-directory-name "Open directory: " (expand-file-name "~/") nil t)))
  (let* ((dir (file-name-as-directory (expand-file-name dir)))
         (name (file-name-nondirectory (directory-file-name dir)))
         (existing (gethash name (perspectives-hash))))
    (unless existing
      (setf (alist-get name my/persp-directories nil nil #'string=) dir))
    (persp-switch name)
    (unless existing
      (dired dir))))

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
        projectile-auto-discover-projects t)
  (run-with-idle-timer 4.0 nil #'projectile-discover-projects-in-search-path))

(use-package persp-projectile
  :ensure t
  :after (perspective projectile))

(use-package treemacs-perspective
  :ensure t
  :after (treemacs perspective)
  :config
  (treemacs-set-scope-type 'Perspectives)

  (defun my/treemacs-perspective-project-root ()
    "Derive project root for current perspective from Projectile known projects."
    (when (and (bound-and-true-p persp-mode) (persp-curr))
      (let ((name (persp-current-name)))
        (when-let* ((proj (or (my/persp-directory name)
                              (projectile-project-root))))
          (treemacs-canonical-path (expand-file-name proj))))))

  (add-to-list 'treemacs--find-user-project-functions #'my/treemacs-perspective-project-root)

  (defun my/treemacs-ensure-perspective-project (&rest _)
    "Ensure the active perspective workspace contains its project or directory."
    (when (and (featurep 'treemacs) (bound-and-true-p persp-mode) (persp-curr))
      (when-let* ((name (persp-current-name))
                  (proj (my/persp-directory name))
                  (canonical (treemacs-canonical-path (expand-file-name proj)))
                  (ws-name (treemacs-perspective--format-workspace-name name))
                  (ws (or (treemacs--find-workspace-by-name ws-name)
                          (cadr (treemacs-do-create-workspace ws-name)))))
        (let ((current-projects (mapcar #'treemacs-project->path (treemacs-workspace->projects ws))))
          (unless (member canonical current-projects)
            (setf (treemacs-workspace->projects ws)
                  (list (treemacs-project->create!
                         :name name
                         :path canonical
                         :path-status (treemacs--get-path-status canonical))))))
        (setf (treemacs-current-workspace) ws)
        (treemacs--invalidate-buffer-project-cache)
        (when (treemacs-get-local-window)
          (treemacs--change-buffer-on-scope-change)
          (treemacs--rerender-after-workspace-change)))))

  (add-hook 'persp-switch-hook #'my/treemacs-ensure-perspective-project 90))

(use-package treemacs-projectile
  :ensure t
  :after (treemacs projectile))

(require 'projectile-keys)

(provide 'projectile-mod)
