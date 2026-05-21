(require 'color)
(require 'ef-themes)

(use-package emacs
  :config
  (global-tab-line-mode 1)

  (defvar my/tab-line-exclude-modes
    '(treemacs-mode which-key-mode dashboard-mode help-mode messages-buffer-mode))

  (defvar my/tab-order-counter 0)
  (defvar-local my/tab-order-id nil)
  
  (defvar my/tab-line-theme-version 0
    "Theme version counter used for cheating Emacs cache.")

  (defun my/tab-line-tabs-function ()
    (let ((tabs (seq-filter
                 (lambda (buf)
                   (let ((name (buffer-name buf))
                         (mode (buffer-local-value 'major-mode buf)))
                     (and (buffer-live-p buf)
                          (not (string-prefix-p " " name))
                          (not (string-prefix-p "*" name))
                          (not (memq mode my/tab-line-exclude-modes)))))
                 (tab-line-tabs-window-buffers))))
      
      (dolist (buf tabs)
        (with-current-buffer buf
          (unless my/tab-order-id
            (setq my/tab-order-counter (1+ my/tab-order-counter))
            (setq my/tab-order-id my/tab-order-counter))))
      
      (seq-sort
       (lambda (a b)
         (< (buffer-local-value 'my/tab-order-id a)
            (buffer-local-value 'my/tab-order-id b)))
       tabs)))

  (setq tab-line-separator ""
        tab-line-new-button-show nil
        tab-line-close-button-show nil
        tab-line-left-button nil
        tab-line-right-button nil
        tab-line-auto-hscroll t
        tab-line-tabs-scroll-offset 1
        tab-line-tabs-function #'my/tab-line-tabs-function)

  (defun my/get-safe-color (color fallback)
    (if (or (null color)
            (eq color 'unspecified)
            (equal color "unspecified")
            (equal color "unspecified-bg")
            (equal color "unspecified-fg"))
        fallback
      color))

  (defun my/tab-line-apply-theme (&optional frame)
    "Updates colors from theme."
    (interactive)
    (setq my/tab-line-theme-version (1+ my/tab-line-theme-version))
    
    (with-selected-frame (or frame (selected-frame))
      (let* ((bg-raw (face-background 'default nil t))
             (bg (my/get-safe-color bg-raw "#111111")))

        (set-face-attribute 'tab-line nil :background bg :height 1.0 :box nil)
        (set-face-attribute 'tab-line-tab nil :background bg :box `(:line-width 6 :color ,bg))
        (set-face-attribute 'tab-line-tab-inactive nil :background bg :box `(:line-width 6 :color ,bg))
        (set-face-attribute 'tab-line-tab-current nil :background bg :box `(:line-width 6 :color ,bg))))

    (dolist (f (frame-list))
      (dolist (w (window-list f))
        (with-selected-window w
          (set-window-parameter w 'tab-line-cache nil)
          (force-mode-line-update t)))))

  (my/tab-line-apply-theme)
  (add-hook 'after-make-frame-functions #'my/tab-line-apply-theme)
  
  (advice-add 'load-theme :after 
              (lambda (&rest _) 
                (run-at-time 0 nil #'my/tab-line-apply-theme)))

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
           (active (if (bufferp tab) (eq tab (current-buffer)) (cdr (assq 'selected tab))))
           (bg-face (if active 'tab-line-tab-current 'tab-line-tab-inactive))
           (bg-color (my/get-safe-color (face-background bg-face nil t) "#111111"))
           
           (theme-comment (ignore-errors (ef-themes-with-colors comment)))
           (fg-main "#ffffff")
           (fg-comment (my/get-safe-color theme-comment (my/get-safe-color (face-foreground 'font-lock-comment-face nil t) "#888888")))
           (sep-color (my/get-safe-color (ignore-errors (ef-themes-with-colors preprocessor)) "#5dc0aa"))

           (raw-name (buffer-name buffer))
           (display-name (if (> (length raw-name) 18)
                             (concat (substring raw-name 0 17) "…")
                           raw-name))

           (sep (propertize "┃" 'face `(:foreground ,sep-color :background ,bg-color :weight semi-bold)))
           (empty-sep (propertize " " 'face `(:background ,bg-color)))
           (file-or-name (or (buffer-file-name buffer) (buffer-name buffer)))
           (icon-raw (let ((nerd-icons-color-icons t))
                       (nerd-icons-icon-for-file file-or-name :v-adjust -0.05 :height 0.85)))
           
           (icon-hex (my/get-icon-hex icon-raw (if active fg-main fg-comment)))
           (icon-str (substring-no-properties icon-raw))
           (icon (propertize icon-str 'face `(:foreground ,icon-hex :background ,bg-color)))

           (text-face (if active
                          `(:foreground ,fg-main :weight bold :slant italic :background ,bg-color)
                        `(:foreground ,fg-comment :weight normal :slant normal :background ,bg-color)))
           (name (propertize display-name 'face text-face))
           (pad (propertize "  " 'face `(:background ,bg-color)))
           (mid-pad (propertize " " 'face `(:background ,bg-color)))

           (str (concat (if active sep empty-sep) pad icon mid-pad name pad)))

      (propertize str
                  'tab tab
                  'theme-version my/tab-line-theme-version
                  'help-echo nil
                  'mouse-face nil
                  'keymap tab-line-tab-map)))

  (setq tab-line-tab-name-format-function #'my/tab-line-tab-name-format)

  (defun my/tab-line-next-tab ()
    (interactive)
    (let* ((tabs (my/tab-line-tabs-function))
           (pos (seq-position tabs (current-buffer))))
      (if pos
          (switch-to-buffer (nth (if (= pos (1- (length tabs))) 0 (1+ pos)) tabs))
        (when tabs (switch-to-buffer (car tabs))))))

  (defun my/tab-line-prev-tab ()
    (interactive)
    (let* ((tabs (my/tab-line-tabs-function))
           (pos (seq-position tabs (current-buffer))))
      (if pos
          (switch-to-buffer (nth (if (= pos 0) (1- (length tabs)) (1- pos)) tabs))
        (when tabs (switch-to-buffer (car (last tabs)))))))

  (advice-add 'tab-line-switch-to-next-tab :override #'my/tab-line-next-tab)
  (advice-add 'tab-line-switch-to-prev-tab :override #'my/tab-line-prev-tab)

  (defun my/tab-line-follow-active (&rest _)
    (let* ((win (selected-window))
           (tabs (my/tab-line-tabs-function))
           (pos (seq-position tabs (current-buffer)))
           (cur-hscroll (or (window-parameter win 'tab-line-hscroll) 0))
           (win-width (window-width win))
           (tab-fixed-width 23))
      
      (when (and win pos)
        (let* ((visible-capacity (/ win-width tab-fixed-width))
               (new-hscroll cur-hscroll))
          (cond
           ((< pos cur-hscroll)
            (setq new-hscroll pos))
           ((>= pos (+ cur-hscroll visible-capacity))
            (setq new-hscroll (1+ (- pos visible-capacity)))))
          
          (unless (= new-hscroll cur-hscroll)
            (set-window-parameter win 'tab-line-hscroll (max 0 new-hscroll))))
        (force-mode-line-update t))))
  
  (advice-add 'tab-line-switch-to-next-tab :after #'my/tab-line-follow-active)
  (advice-add 'tab-line-switch-to-prev-tab :after #'my/tab-line-follow-active)
  (add-hook 'buffer-list-update-hook #'my/tab-line-follow-active))

(provide 'setup-tabs)
