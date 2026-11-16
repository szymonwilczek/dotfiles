;;; Project management and Perspective session integration -*- lexical-binding: t; -*-

(require 'project)
(require 'cl-lib)

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
                    (assoc-delete-all (persp-current-name) my/persp-directories))))

  ;; do not associate AI agent terminal buffers with perspectives
  (add-to-list 'ido-ignore-buffers "\\`\\*agent-")

  (defun my/persp-filter-added-buffers (orig-fn buffer-or-name)
    "Prevent AI agent buffers from being adopted as project perspective buffers."
    (let ((buf (get-buffer buffer-or-name)))
      (unless (and buf (fboundp 'my/agent-related-buffer-p) (my/agent-related-buffer-p buf))
        (funcall orig-fn buffer-or-name))))

  (advice-add 'persp-add-buffer :around #'my/persp-filter-added-buffers)

  (defun my/persp-sync-scratch-directory (&rest _)
    "Ensure the scratch buffer of the current perspective has `default-directory'
set to the project root directory."
    (when (bound-and-true-p persp-mode)
      (let* ((name (persp-current-name))
             (dir (or (alist-get name my/persp-directories nil nil #'string=)
                      (cl-find-if (lambda (p)
                                    (string= (file-name-nondirectory (directory-file-name p))
                                             name))
                                  (project-known-project-roots)))))
        (when dir
          (setf (alist-get name my/persp-directories nil nil #'string=) dir)
          (let ((scratch (persp-get-scratch-buffer name)))
            (when (buffer-live-p scratch)
              (with-current-buffer scratch
                (setq default-directory (file-name-as-directory (expand-file-name dir))))))))))

  (add-hook 'persp-created-hook #'my/persp-sync-scratch-directory)
  (add-hook 'persp-activated-hook #'my/persp-sync-scratch-directory))

(defun my/open-directory-anywhere (dir)
  "Switch to a perspective named after DIR, starting the prompt in home.
DIR need not be a git project and is not added to known projects.
A new perspective opens DIR in dired, an existing one is just switched to."
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

(defvar my/project-search-paths
  (cl-remove-if-not #'file-directory-p '("~/Dokumenty/GitHub" "~/workspace" "~/projects"))
  "Directories to automatically scan for projects.")

(defun my/project-discover ()
  "Index all projects found under `my/project-search-paths'."
  (interactive)
  (dolist (dir my/project-search-paths)
    (let ((expanded (expand-file-name dir)))
      (when (file-directory-p expanded)
        (project-remember-projects-under expanded nil))))
  (when (called-interactively-p 'interactive)
    (message "Projects indexed: %d known project(s)"
             (length (project-known-project-roots)))))

(run-with-idle-timer 4.0 nil #'my/project-discover)

(defun my/project-relevant-roots ()
  "Return known project roots excluding the current perspective and project."
  (let* ((persp (and (bound-and-true-p persp-mode) (persp-current-name)))
         (persp-dir (and persp (alist-get persp my/persp-directories nil nil #'string=)))
         (curr-pr-root (when-let* ((pr (project-current))) (project-root pr))))
    (cl-remove-if
     (lambda (p)
       (or (and persp (string= (file-name-nondirectory (directory-file-name p)) persp))
           (and persp-dir (file-equal-p p persp-dir))
           (and curr-pr-root (file-equal-p p curr-pr-root))))
     (project-known-project-roots))))

(defun my/project-switch-persp ()
  "Prompt for a known project and switch to its perspective."
  (interactive)
  (let* ((projects (my/project-relevant-roots))
         (dir (completing-read "Open project: " projects nil t))
         (dir (file-name-as-directory (expand-file-name dir)))
         (name (file-name-nondirectory (directory-file-name dir)))
         (existing (gethash name (perspectives-hash))))
    (project-remember-project (project-current nil dir))
    (setf (alist-get name my/persp-directories nil nil #'string=) dir)
    (persp-switch name)
    (unless existing
      (let ((scratch (persp-get-scratch-buffer name)))
        (with-current-buffer scratch
          (setq default-directory dir))
        (set-window-buffer (selected-window) scratch)
        (let ((default-directory dir))
          (with-local-quit
            (call-interactively #'project-find-file)))))))

(defun my/new-frame-switch-project (frame)
  "Prompt for a project in FRAME while it still shows scratch."
  (when (and (frame-live-p frame)
             (string-match-p "\\`\\*scratch\\*"
                             (buffer-name (window-buffer (frame-selected-window frame)))))
    (select-frame-set-input-focus frame)
    (with-local-quit
      (call-interactively #'my/project-switch-persp))))

(add-hook 'server-after-make-frame-hook
          (lambda ()
            (run-at-time 0 nil #'my/new-frame-switch-project (selected-frame))))

(require 'project-keys)

(provide 'project-mod)
