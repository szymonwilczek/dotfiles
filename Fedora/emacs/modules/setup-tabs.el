(require 'color)

(use-package emacs
  :config
  (global-tab-line-mode 1)

  (setq tab-line-separator ""
    tab-line-new-button-show nil
    tab-line-close-button-show nil
    tab-line-auto-hscroll t
    tab-line-tabs-scroll-offset 1
    tab-line-tabs-function #'tab-line-tabs-window-buffers)

  (defun my/get-safe-color (color fallback)
    (if (or (null color)
          (eq color 'unspecified)
          (equal color "unspecified")
          (equal color "unspecified-bg")
          (equal color "unspecified-fg"))
      fallback
      color))

  (defun my/tab-line-apply-theme (&optional frame)
    (with-selected-frame (or frame (selected-frame))
      (let* ((bg-raw (face-background 'default nil t))
              (bg (my/get-safe-color bg-raw "#1e1e2e"))
              (rgb (color-name-to-rgb bg))
              (bg-dark (apply 'color-rgb-to-hex (mapcar (lambda (x) (* x 0.90)) rgb))))

        (set-face-attribute 'tab-line nil :background bg-dark :height 1.0 :box nil)
        (set-face-attribute 'tab-line-tab nil :background bg-dark :box `(:line-width 4 :color ,bg-dark))
        (set-face-attribute 'tab-line-tab-inactive nil :background bg-dark :box `(:line-width 4 :color ,bg-dark))
        (set-face-attribute 'tab-line-tab-current nil :background bg :box `(:line-width 4 :color ,bg)))))

  (my/tab-line-apply-theme)
  (add-hook 'after-make-frame-functions #'my/tab-line-apply-theme)

  (defun my/get-icon-hex (icon-str fallback)
    (let* ((face (or (get-text-property 0 'face icon-str)
                   (get-text-property 0 'font-lock-face icon-str)))
            (hex (cond
                   ((symbolp face) (face-foreground face nil t))
                   ((listp face)
                     (let ((fg (plist-get face :foreground))
                            (inh (plist-get face :inherit)))
                       (cond
			 (fg (cond ((stringp fg) fg)
                               ((symbolp fg) (face-foreground fg nil t))
                               (t nil)))
			 (inh (let ((inh-face (if (listp inh) (car inh) inh)))
				(if (symbolp inh-face)
                                  (face-foreground inh-face nil t)
				  nil)))
			 (t nil))))
                   (t nil))))
      (my/get-safe-color hex fallback)))

  (defun my/tab-line-tab-name-format (tab tabs)
    (let* ((buffer (if (bufferp tab) tab (cdr (assq 'buffer tab))))
            (active (if (bufferp tab)
                      (eq tab (current-buffer))
                      (cdr (assq 'selected tab))))

            (bg-face (if active 'tab-line-tab-current 'tab-line-tab-inactive))
            (bg-color (my/get-safe-color (face-background bg-face nil t) "#1e1e2e"))

            (fg-comment (my/get-safe-color (face-foreground 'font-lock-comment-face nil t) "#888888"))
            (fg-active (or (ignore-errors (color-lighten-name fg-comment 25)) "#ffffff"))
            (sep-color (my/get-safe-color (face-foreground 'font-lock-bracket-face nil t) "#ff966c"))

            (sep (propertize "┃" 'face `(:foreground ,sep-color :background ,bg-color :weight bold)))

            (file-or-name (or (buffer-file-name buffer) (buffer-name buffer)))
            (icon-raw (let ((nerd-icons-color-icons t))
			(nerd-icons-icon-for-file file-or-name :v-adjust -0.05 :height 0.85)))
            
            (icon-hex (my/get-icon-hex icon-raw (if active fg-active fg-comment)))
            (icon-str (substring-no-properties icon-raw))
            (icon (propertize icon-str 'face `(:foreground ,icon-hex :background ,bg-color)))

            (text-face (if active
                         `(:foreground ,fg-active :weight bold :slant italic :background ,bg-color)
                         `(:foreground ,fg-comment :weight normal :slant normal :background ,bg-color)))
            (name (propertize (buffer-name buffer) 'face text-face))

            (pad (propertize "  " 'face `(:background ,bg-color)))
            (mid-pad (propertize "  " 'face `(:background ,bg-color)))

            (str (concat
                   (if active sep "")
                   pad icon mid-pad name pad)))

      (propertize str
        'tab tab
        'help-echo nil
        'mouse-face nil
        'keymap tab-line-tab-map)))

  (setq tab-line-tab-name-format-function #'my/tab-line-tab-name-format)
  (setq tab-line-exclude-modes '(treemacs-mode which-key-mode dashboard-mode))

  (defun my/tab-line-follow-active (&rest _)
    (force-mode-line-update t))
  
  (advice-add 'tab-line-switch-to-next-tab :after #'my/tab-line-follow-active)
  (advice-add 'tab-line-switch-to-prev-tab :after #'my/tab-line-follow-active)
  (add-hook 'buffer-list-update-hook 'force-mode-line-update))

(provide 'setup-tabs)
