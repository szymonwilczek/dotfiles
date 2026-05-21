(require 'use-package)
(require 'cl-lib)

(defvar my/sessions-dir (expand-file-name "sessions/" user-emacs-directory))
(make-directory my/sessions-dir t)

;; ========================
;; PERSPECTIVE & PROJECTILE
;; ========================
(use-package perspective
  :ensure t
  :custom
  (persp-mode-prefix-key (kbd "C-c M-p"))
  (persp-kill-foreign-buffer t)
  :init
  (persp-mode 1))

(use-package persp-projectile
  :ensure t
  :after (perspective projectile))

;; ========================
;;         TREEMACS
;; ========================
(use-package treemacs
  :ensure t
  :config (setq treemacs-persist-file nil))

(use-package treemacs-perspective
  :ensure t
  :after (treemacs perspective)
  :config (treemacs-set-scope-type 'Perspectives))

(use-package treemacs-projectile
  :ensure t
  :after (treemacs projectile))

;; ========================
;;        .winstate
;; ========================
(defun my/session-file (name)
  (expand-file-name (concat (url-hexify-string name) ".winstate") my/sessions-dir))

(defun my/persp-has-file-buffers-p ()
  (cl-some (lambda (buf) (and (buffer-live-p buf) (buffer-file-name buf)))
           (persp-buffers (persp-curr))))

(defun my/cancel-treemacs-annotation-timers ()
  "Cancel pending treemacs annotation timers to prevent stale marker errors."
  (dolist (timer timer-list)
    (when (eq (timer--function timer) #'treemacs--apply-annotations-deferred)
      (cancel-timer timer))))

(add-hook 'persp-before-switch-hook #'my/cancel-treemacs-annotation-timers)
(add-hook 'persp-switch-hook #'my/cancel-treemacs-annotation-timers)

;; --- SAVE ---
(defun my/perspective-project-root (persp-name)
  "Derive project root from PERSP-NAME via projectile known projects."
  (car (cl-remove-if-not
        (lambda (p) (string= persp-name (funcall projectile-project-name-function p)))
        (projectile-relevant-known-projects))))

(defun my/session-save-current ()
  "Zapisuje bufory i układ okien przed wyjściem z perspektywy."
  (when (and (bound-and-true-p persp-mode) (persp-curr) (display-graphic-p))
    (let ((name (persp-name (persp-curr))))
      (unless (string= name "main")
        (condition-case err
            (let* ((wc (current-window-configuration))
                   (project-root (my/perspective-project-root name))
                   win-state files)

              ;; hide treemacs
              (when (and (featurep 'treemacs) (treemacs-get-local-window))
                (let ((ignore-window-parameters t))
                  (delete-window (treemacs-get-local-window))))

              ;; take a screenshot of windows state for .winstate
              (setq win-state (window-state-get (frame-root-window) t))

              ;; restore emacs
              (set-window-configuration wc)

              ;; gather files - only from this project
              (setq files (cl-loop for buf in (persp-buffers (persp-curr))
                                   for file = (and (buffer-live-p buf) (buffer-file-name buf))
                                   when (and file
                                             (or (null project-root)
                                                 (string-prefix-p project-root file)))
                                   collect (list file
                                                 (buffer-name buf)
                                                 (with-current-buffer buf (point)))))

              ;; save to disk only if we have valid project files
              (when files
                (with-temp-file (my/session-file name)
                  (let ((print-level nil) (print-length nil))
                    (prin1 (list :window-state win-state :files files) (current-buffer))))))
          (error (message "[Session] Błąd zapisu: %s" err)))))))

(add-hook 'persp-before-switch-hook #'my/session-save-current)

;; :qa handle
(add-hook 'delete-frame-functions
          (lambda (frame)
            (when (display-graphic-p frame)
              (with-selected-frame frame (my/session-save-current)))))

;; --- RESTORE ---
(defun my/session--remap-buffer-names (win-state name-map)
  "Replace buffer name references in WIN-STATE using NAME-MAP.
NAME-MAP is alist of (old-name . new-name).
Handles both (buffer NAME ...) and (prev-buffers (NAME ...) ...) forms."
  (cond
   ((and (consp win-state) (eq (car win-state) 'buffer) (stringp (cadr win-state)))
    (let ((replacement (assoc (cadr win-state) name-map)))
      (when replacement
        (setcar (cdr win-state) (cdr replacement))))
    win-state)
   ((and (consp win-state) (eq (car win-state) 'prev-buffers))
    (dolist (entry (cdr win-state))
      (when (and (consp entry) (stringp (car entry)))
        (let ((replacement (assoc (car entry) name-map)))
          (when replacement
            (setcar entry (cdr replacement))))))
    win-state)
   ((consp win-state)
    (my/session--remap-buffer-names (car win-state) name-map)
    (my/session--remap-buffer-names (cdr win-state) name-map)
    win-state)
   (t win-state)))

(defun my/session-load (name &optional project-root)
  "Loads files from disk and restores windows.
PROJECT-ROOT filters files to only those belonging to the project."
  (let ((file (my/session-file name)))
    (when (file-exists-p file)
      (condition-case err
          (let* ((data (with-temp-buffer
                         (insert-file-contents file)
                         (read (current-buffer))))
                 (saved-files (plist-get data :files))
                 (win-state (plist-get data :window-state))
                 (name-map nil)
                 (opened-bufs nil))

            ;; restore buffers, filtering to project-root
            (dolist (entry saved-files)
              (let* ((filepath (car entry))
                     (saved-bufname (when (listp (cdr entry)) (cadr entry)))
                     (pt (if (listp (cdr entry)) (caddr entry) (cdr entry))))
                (when (and (file-exists-p filepath)
                           (or (null project-root)
                               (string-prefix-p project-root filepath)))
                  (let* ((buf (find-file-noselect filepath))
                         (actual-name (buffer-name buf))
                         (expected-name (or saved-bufname (file-name-nondirectory filepath))))
                    (persp-add-buffer buf)
                    (push buf opened-bufs)
                    (with-current-buffer buf (goto-char (min pt (point-max))))
                    (unless (string= expected-name actual-name)
                      (push (cons expected-name actual-name) name-map))))))

            ;; restore windows with corrected buffer names
            (when (and win-state opened-bufs)
              (when name-map
                (my/session--remap-buffer-names win-state name-map))
              (let ((ignore-window-parameters t)) (delete-other-windows))
              (window-state-put win-state (frame-root-window) 'safe)

              ;; post-restore: verify windows show correct buffers
              (let ((valid-files (mapcar #'buffer-file-name opened-bufs)))
                (dolist (win (window-list))
                  (let ((buf-file (buffer-file-name (window-buffer win))))
                    (when (and buf-file (not (member buf-file valid-files)))
                      ;; wrong buffer in this window - replace with correct one
                      (let* ((wrong-name (file-name-nondirectory buf-file))
                             (correct (cl-find-if
                                       (lambda (b)
                                         (string= wrong-name
                                                  (file-name-nondirectory
                                                   (or (buffer-file-name b) ""))))
                                       opened-bufs)))
                        (set-window-buffer win (or correct (car opened-bufs))))))))
              (redisplay))
            (when opened-bufs t))
        (error
         (message "[Session] Błąd odczytu %s: %s" name err)
         nil)))))

(provide 'setup-sessions)
