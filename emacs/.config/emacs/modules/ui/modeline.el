;;; Statusline -*- lexical-binding: t; -*-

(require 'timeout)
(require 'agents-modeline)

(defvar-local my/modeline--cached-base-name nil)
(defvar-local my/modeline--cached-filetype nil)
(defvar-local my/modeline--cached-git-branch "")
(defvar-local my/modeline--cached-diagnostics "")
(defvar-local my/modeline--cached-fileinfo "")

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

(defun my/modeline--compute-base-name ()
  "Compute base filename relative to projectile root."
  (let* ((file (buffer-file-name))
         (buf-name (buffer-name)))
    (if file
        (let* ((proj (and (fboundp 'projectile-project-root)
                          (projectile-project-p)
                          (projectile-project-root))))
          (if proj (file-relative-name file proj)
            (abbreviate-file-name file)))
      (if (string-prefix-p "*" buf-name)
          buf-name
        "[No Name]"))))

(defun my/modeline-filename ()
  "Render relative filename with modified and readonly markers."
  (unless my/modeline--cached-base-name
    (setq my/modeline--cached-base-name (my/modeline--compute-base-name)))
  (let ((mod (if (buffer-modified-p) "[+]" ""))
        (ro (if buffer-read-only "[RO]" "")))
    (format " %s%s%s " my/modeline--cached-base-name mod ro)))

(defun my/modeline-location ()
  "Render line and column location matching %2l:%-2v."
  (let* ((state (and (bound-and-true-p evil-mode) evil-state))
         (face (pcase state
                 ('normal '(:inherit font-lock-keyword-face :weight bold))
                 ('insert '(:inherit font-lock-string-face :weight bold))
                 ('visual '(:inherit font-lock-type-face :weight bold))
                 ('replace '(:inherit error :weight bold))
                 (_ '(:inherit font-lock-constant-face :weight bold))))
         (loc (propertize " %2l:%C " 'face face)))
    loc))

(defun my/modeline-filetype ()
  "Render simplified major mode filetype."
  (or my/modeline--cached-filetype
      (setq my/modeline--cached-filetype
            (format " %s " (replace-regexp-in-string "-ts-mode\\|-mode\\'" "" (symbol-name major-mode))))))

(defun my/modeline-update-diagnostics ()
  "Compute Flymake error and warning counts [E W]."
  (setq my/modeline--cached-diagnostics
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
          "")))

(timeout-throttle #'my/modeline-update-diagnostics 0.25)

(defun my/modeline-diagnostics ()
  "Return cached Flymake diagnostics string."
  (my/modeline-update-diagnostics)
  my/modeline--cached-diagnostics)

(defun my/modeline-filesize ()
  "Format current buffer file size in B, KiB or MiB."
  (let ((size (buffer-size)))
    (cond
     ((<= size 0) "")
     ((< size 1024) (format "%dB" size))
     ((< size (* 1024 1024)) (format "%.2fKiB" (/ (float size) 1024.0)))
     (t (format "%.2fMiB" (/ (float size) (* 1024.0 1024.0)))))))

(defun my/modeline-update-fileinfo ()
  "Compute encoding and filesize."
  (let* ((enc (symbol-name (or buffer-file-coding-system 'utf-8)))
         (enc-clean (car (split-string enc "-unix\\|-dos\\|-mac\\|\\'")))
         (size (my/modeline-filesize)))
    (setq my/modeline--cached-fileinfo
          (if (string-empty-p size)
              ""
            (format " %s %s " enc-clean size)))))

(timeout-throttle #'my/modeline-update-fileinfo 0.5)

(defun my/modeline-fileinfo ()
  "Return cached fileinfo string."
  (my/modeline-update-fileinfo)
  my/modeline--cached-fileinfo)

(defun my/modeline-update-git-branch ()
  "Compute current git branch name in brackets."
  (setq my/modeline--cached-git-branch
        (let ((branch (or (and (boundp 'vc-mode) vc-mode
                               (string-trim (substring-no-properties vc-mode 5)))
                          (and (fboundp 'magit-get-current-branch)
                               (magit-get-current-branch)))))
          (if (and branch (not (string-empty-p branch)))
              (concat " [" (propertize branch 'face 'font-lock-constant-face) "] ")
            ""))))

(timeout-throttle #'my/modeline-update-git-branch 0.3)

(defun my/modeline-git-branch ()
  "Return cached git branch string."
  (my/modeline-update-git-branch)
  my/modeline--cached-git-branch)

(defun my/render-modeline ()
  "Assemble active or inactive statusline."
  (if (and (fboundp 'my/agents-modeline-buffer-p)
           (my/agents-modeline-buffer-p))
      (my/agents-modeline-render)
    (if (not (mode-line-window-selected-p))
        ;; inactive standard window
        (concat " " (my/modeline-filename))
      ;; active standard window
      (let* ((lhs (concat (my/modeline-evil-mode-info)
                          (my/modeline-filename)))
             (rhs (concat (my/modeline-location)
                          (my/modeline-filetype)
                          (my/modeline-diagnostics)
                          (my/modeline-fileinfo)
                          (my/modeline-git-branch)))
             (rhs-w (string-width (format-mode-line rhs))))
        (concat lhs
                (propertize " " 'display `(space :align-to (- right ,rhs-w)))
                rhs)))))

(setq-default mode-line-format '(:eval (my/render-modeline)))

;; Refresh caches on relevant buffer changes
(defun my/modeline-reset-buffer-caches ()
  (setq my/modeline--cached-base-name nil
        my/modeline--cached-filetype nil
        my/modeline--cached-git-branch ""
        my/modeline--cached-diagnostics ""
        my/modeline--cached-fileinfo ""))

(add-hook 'after-change-major-mode-hook #'my/modeline-reset-buffer-caches)
(add-hook 'after-save-hook #'my/modeline-reset-buffer-caches)
(add-hook 'magit-post-refresh-hook (lambda ()
                                     (dolist (buf (buffer-list))
                                       (with-current-buffer buf
                                         (setq my/modeline--cached-git-branch "")))))

(line-number-mode 1)
(column-number-mode 1)

(provide 'modeline)
