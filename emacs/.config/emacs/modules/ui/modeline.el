;;; Statusline

(defun my/modeline-evil-mode-info ()
  "Render current Evil mode tag with highlight face."
  (let* ((state (and (bound-and-true-p evil-mode) evil-state))
         (mode-name (pcase state
                      ('normal "NORMAL")
                      ('insert "INSERT")
                      ('visual "VISUAL")
                      ('replace "REPLACE")
                      ('motion "MOTION")
                      ('emacs "EMACS")
                      (_ "NORMAL")))
         (face (pcase state
                 ('normal '(:inherit font-lock-keyword-face :weight bold))
                 ('insert '(:inherit font-lock-string-face :weight bold))
                 ('visual '(:inherit font-lock-type-face :weight bold))
                 ('replace '(:inherit error :weight bold))
                 (_ '(:inherit font-lock-constant-face :weight bold)))))
    (propertize (format " %s " mode-name) 'face face)))

(defun my/modeline-filename ()
  "Render relative filename with modified and readonly markers."
  (let* ((file (buffer-file-name))
         (buf-name (buffer-name))
         (name (if file
                   (let* ((proj (and (fboundp 'projectile-project-root)
                                     (projectile-project-p)
                                     (projectile-project-root)))
                          (rel (if proj (file-relative-name file proj)
                                 (abbreviate-file-name file))))
                     rel)
                 (if (string-prefix-p "*" buf-name)
                     buf-name
                   (format "[No Name]%s" (if (buffer-modified-p) "[+]" "")))))
         (mod (if (and file (buffer-modified-p)) "[+]" ""))
         (ro (if buffer-read-only "[RO]" "")))
    (format " %s%s%s " name mod ro)))

(defun my/modeline-location ()
  "Render line and column location matching %2l:%-2v."
  (let* ((state (and (bound-and-true-p evil-mode) evil-state))
         (face (pcase state
                 ('normal '(:inherit font-lock-keyword-face :weight bold))
                 ('insert '(:inherit font-lock-string-face :weight bold))
                 ('visual '(:inherit font-lock-type-face :weight bold))
                 ('replace '(:inherit error :weight bold))
                 (_ '(:inherit font-lock-constant-face :weight bold))))
         (loc (format " %2d:%-2d " (line-number-at-pos) (1+ (current-column)))))
    (propertize loc 'face face)))

(defun my/modeline-filetype ()
  "Render simplified major mode filetype."
  (let ((mode-str (symbol-name major-mode)))
    (setq mode-str (replace-regexp-in-string "-ts-mode\\|-mode\\'" "" mode-str))
    (format " %s " mode-str)))

(defun my/modeline-diagnostics ()
  "Render Flymake error and warning counts [E W]."
  (if (bound-and-true-p flymake-mode)
      (let* ((known-diags (flymake-diagnostics))
             (errs 0)
             (warns 0))
        (dolist (d known-diags)
          (pcase (flymake-diagnostic-type d)
            (:error (cl-incf errs))
            (:warning (cl-incf warns))))
        (concat " ["
                (propertize (format "%d" errs) 'face 'error)
                " "
                (propertize (format "%d" warns) 'face 'warning)
                "] "))
    ""))

(defun my/modeline-filesize ()
  "Format current buffer file size in B, KiB or MiB."
  (let ((size (buffer-size)))
    (cond
     ((<= size 0) "")
     ((< size 1024) (format "%dB" size))
     ((< size (* 1024 1024)) (format "%.2fKiB" (/ (float size) 1024.0)))
     (t (format "%.2fMiB" (/ (float size) (* 1024.0 1024.0)))))))

(defun my/modeline-fileinfo ()
  "Render encoding and filesize."
  (let* ((enc (symbol-name (or buffer-file-coding-system 'utf-8)))
         (enc-clean (car (split-string enc "-unix\\|-dos\\|-mac\\|\\'")))
         (size (my/modeline-filesize)))
    (if (string-empty-p size)
        ""
      (format " %s %s " enc-clean size))))

(defun my/modeline-git-branch ()
  "Render current git branch name in brackets."
  (let ((branch (or (and (boundp 'vc-mode) vc-mode
                         (string-trim (substring-no-properties vc-mode 5)))
                    (and (fboundp 'magit-get-current-branch)
                         (magit-get-current-branch)))))
    (if (and branch (not (string-empty-p branch)))
        (concat " [" (propertize branch 'face 'font-lock-constant-face) "] ")
      "")))

(defun my/render-modeline ()
  "Assemble active or inactive statusline."
  (if (not (mode-line-window-selected-p))
      ;; Inactive window
      (concat " " (my/modeline-filename))
    ;; Active window
    (let* ((lhs (concat (my/modeline-evil-mode-info)
                        (my/modeline-filename)))
           (rhs (concat (my/modeline-location)
                        (my/modeline-filetype)
                        (my/modeline-diagnostics)
                        (my/modeline-fileinfo)
                        (my/modeline-git-branch)))
           (rhs-width (string-width (format-mode-line rhs))))
      (concat lhs
              (propertize " " 'display `(space :align-to (- right ,rhs-width)))
              rhs))))

(setq-default mode-line-format '(:eval (my/render-modeline)))

;; Disable modeline Dashboard
(add-hook 'dashboard-mode-hook (lambda () (setq-local mode-line-format nil)))

(provide 'modeline)
