;;; My ascii banners

(use-package dashboard
  :ensure t
  :config

  ;; Layout & Alignment
  (setq dashboard-startup-banner nil
        dashboard-banner-logo-title nil
        dashboard-set-init-info nil
        dashboard-set-footer nil
        dashboard-items nil
        dashboard-center-content t
        dashboard-vertically-center-content t)

  ;; Random banner loader from banners/ dir
  (defun my/get-random-banner ()
    (let* ((banner-dir (expand-file-name "banners/" user-emacs-directory))
           (banners (when (file-directory-p banner-dir)
                      (directory-files banner-dir t "^[^.]"))))
      (when banners (nth (random (length banners)) banners))))

  ;; Parse tags
  (defun my/parse-dashboard-banner (file)
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (let ((tag-alist '(("[R]" . error)
                         ("[G]" . font-lock-string-face)
                         ("[L]" . font-lock-builtin-face)
                         ("[Y]" . warning)
                         ("[O]" . font-lock-constant-face)
                         ("[P]" . font-lock-keyword-face)
                         ("[C]" . font-lock-function-name-face)
                         ("[A]" . font-lock-comment-face)
                         ("[B]" . font-lock-type-face)
                         ("[W]" . default))))
        (while (not (eobp))
          (let ((current-face 'default)
                (start-pos (point)))
            (while (re-search-forward "\\[[RGLYOPCABW]\\]" (line-end-position) t)
              (let* ((tag (match-string 0))
                     (face (cdr (assoc tag tag-alist)))
                     (tag-start (match-beginning 0)))
                (when (> tag-start start-pos)
                  (put-text-property start-pos tag-start 'face current-face))
                (delete-region tag-start (point))
                (when face (setq current-face face))
                (setq start-pos (point))))
            (when (> (line-end-position) start-pos)
              (put-text-property start-pos (line-end-position) 'face current-face)))
          (forward-line 1)))
      (buffer-string)))

  ;; Dashboard Header
  (defun my/dashboard-insert-custom-header (&rest _)
    (let ((banner-file (my/get-random-banner)))
      (when banner-file
        (let* ((parsed-string (my/parse-dashboard-banner banner-file))
               (lines (split-string parsed-string "\n"))
               (max-width (apply #'max 0 (mapcar #'string-width lines)))
               (pad (max 0 (/ (- (window-width) max-width) 2))))
          (mapc (lambda (line)
                  (insert (make-string pad ?\s) line "\n"))
                lines)))))

  (advice-add 'dashboard-insert-banner :override #'my/dashboard-insert-custom-header)
  (advice-add 'dashboard-insert-init-info :override #'ignore)
  (advice-add 'dashboard-insert-footer :override #'ignore)

  ;; Startup handling
  (defun my/create-startup-dashboard ()
    (let ((buf (get-buffer-create dashboard-buffer-name)))
      (with-current-buffer buf
        (dashboard-mode)
        (dashboard-insert-startupify-lists))
      buf))

  (setq initial-buffer-choice #'my/create-startup-dashboard)

  ;; Clear initial-buffer-choice so dashboard is NEVER recreated during the session
  (add-hook 'emacs-startup-hook
            (lambda ()
              (setq initial-buffer-choice nil)
              (when (get-buffer "*scratch*")
                (kill-buffer "*scratch*"))))

  (add-hook 'server-after-make-frame-hook
            (lambda ()
              (setq initial-buffer-choice nil)
              (run-at-time 0.02 nil
                           (lambda ()
                             (when-let ((buf (get-buffer dashboard-buffer-name)))
                               (with-current-buffer buf
                                 (dashboard-refresh-buffer))))))))

(provide 'dashboard-mod)
