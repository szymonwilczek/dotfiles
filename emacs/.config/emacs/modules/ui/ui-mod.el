;;; UI styling, themes and typography -*- lexical-binding: t; -*-

;; Typography & Frames
(add-to-list 'default-frame-alist '(font . "Typus Mono 92-13"))

(defun my/set-font-faces (&optional frame)
  "Applies default font to given frame or current frame."
  (with-selected-frame (or frame (selected-frame))
    (set-face-attribute 'default nil
                        :family "Typus Mono 92"
                        :height 130
                        :weight 'normal)))

(my/set-font-faces)
(add-hook 'server-after-make-frame-hook #'my/set-font-faces)

;; Cursor & Line indicators
(setq-default cursor-type 'box
              cursor-in-non-selected-windows nil)
(blink-cursor-mode -1)

(global-display-line-numbers-mode 1)
(global-hl-line-mode 1)
(setq-default display-line-numbers-width 3)

;; Disable line numbers in PDF, images, terminal and agent windows
(defun my/disable-line-numbers ()
  "Disable line numbers in special and terminal buffers."
  (setq-local display-line-numbers nil)
  (display-line-numbers-mode -1))

(dolist (hook '(doc-view-mode-hook
                image-mode-hook
                ghostel-mode-hook))
  (add-hook hook #'my/disable-line-numbers))

(add-hook 'display-line-numbers-mode-hook
          (lambda ()
            (when (or (bound-and-true-p my/agent-buffer-p)
                      (string-match-p "\\*agent-" (buffer-name)))
              (setq display-line-numbers nil))))

;; Themes & Theme Persistence
(defvar my/theme-cache-file
  (expand-file-name ".theme-cache" user-emacs-directory))

(defun my/get-cached-theme ()
  "Return saved theme symbol from `.theme-cache', or fallback to `ef-autumn'."
  (if (file-exists-p my/theme-cache-file)
      (intern (with-temp-buffer
                (insert-file-contents my/theme-cache-file)
                (string-trim (buffer-string))))
    'ef-autumn))

(defun my/apply-custom-face-overrides (&rest _)
  "Apply custom italic and weight overrides to active font-lock faces."
  (set-face-attribute 'font-lock-comment-face nil
                      :slant 'italic :weight 'extra-light)
  (set-face-attribute 'font-lock-comment-delimiter-face nil
                      :slant 'italic :weight 'extra-light)
  (set-face-attribute 'font-lock-keyword-face nil :weight 'demi-bold)
  (set-face-attribute 'font-lock-type-face nil :weight 'demi-bold)
  (set-face-attribute 'font-lock-preprocessor-face nil :weight 'demi-bold))

(advice-add 'load-theme :after #'my/apply-custom-face-overrides)

(advice-add 'load-theme :around
            (lambda (orig-fun theme &rest args)
              (mapc #'disable-theme custom-enabled-themes)
              (apply orig-fun theme args)
              (my/apply-custom-face-overrides)
              (with-temp-file my/theme-cache-file
                (insert (symbol-name theme)))))

(defcustom my/theme-toggle-pair '(ef-autumn ef-arcadia)
  "Two themes to switch between via `my/theme-toggle'."
  :type '(list symbol symbol)
  :group 'ui)

(defun my/theme-toggle ()
  "Toggle cleanly between dark and light themes in `my/theme-toggle-pair'."
  (interactive)
  (let* ((cur (or (car custom-enabled-themes) (my/get-cached-theme)))
         (next (if (eq cur (car my/theme-toggle-pair))
                   (cadr my/theme-toggle-pair)
                 (car my/theme-toggle-pair))))
    (load-theme next t)
    (message "Theme switched to %s" next)))

(use-package ef-themes
  :ensure t
  :config
  (setq ef-themes-to-toggle my/theme-toggle-pair))

;; Daemon and initial frame theme application
(defun my/setup-frame-theme (frame)
  "Ensure theme is applied once to the initial graphical frame in daemon mode."
  (when (and (display-graphic-p frame)
             (not (frame-parent frame))
             (null custom-enabled-themes))
    (remove-hook 'after-make-frame-functions #'my/setup-frame-theme)
    (with-selected-frame frame
      (load-theme (my/get-cached-theme) t))))

(if (daemonp)
    (add-hook 'after-make-frame-functions #'my/setup-frame-theme)
  (load-theme (my/get-cached-theme) t))

(use-package nerd-icons
  :ensure t
  :custom
  (nerd-icons-font-family "Typus Mono 92")
  :config
  (add-to-list 'nerd-icons-extension-icon-alist
               '("astro" nerd-icons-sucicon "nf-custom-astro" :face nerd-icons-orange))
  (add-to-list 'nerd-icons-mode-icon-alist
               '(astro-ts-mode nerd-icons-sucicon "nf-custom-astro" :face nerd-icons-orange)))

(use-package wakatime-mode
  :ensure t
  :init
  (setq wakatime-api-key nil
        wakatime-cli-path (expand-file-name "~/.wakatime/wakatime-cli"))
  :config
  (global-wakatime-mode 1))

(use-package olivetti
  :ensure t
  :custom
  (olivetti-body-width 74)
  (olivetti-minimum-body-width 60)
  (olivetti-recall-visual-line-mode-entry-state t))

(defvar-local my/zen--saved-line-numbers nil
  "Stores state of line numbers before entering zen mode.")

(defun my/zen-mode-toggle ()
  "Toggle distraction-free Zen mode with centered text and soft wrap."
  (interactive)
  (if (bound-and-true-p olivetti-mode)
      (progn
        (olivetti-mode -1)
        (when my/zen--saved-line-numbers
          (display-line-numbers-mode 1))
        (message "Zen Mode: OFF"))
    (setq my/zen--saved-line-numbers (bound-and-true-p display-line-numbers-mode))
    (display-line-numbers-mode -1)
    (visual-line-mode 1)
    (olivetti-mode 1)
    (message "🧘 ON (%d columns)" olivetti-body-width)))

(defalias 'my/writings-zen-toggle #'my/zen-mode-toggle)

;; Visual hex-only color preview and interactive color picker
(defvar my/color-picker-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] #'my/color-picker-at-point)
    (define-key map [down-mouse-1] #'mouse-set-point)
    map)
  "Keymap for clickable hex color strings.")

(defun my/color-picker-at-point (&optional event)
  "Open visual color picker for the hex color at point, and replace it."
  (interactive (list last-input-event))
  (when (and event (mouse-event-p event))
    (mouse-set-point event))
  (let* ((hex-regexp "#[0-9a-fA-F]\\{3,8\\}")
         (bounds (save-excursion
                   (skip-chars-backward "#0-9a-fA-F")
                   (when (looking-at hex-regexp)
                     (cons (match-beginning 0) (match-end 0)))))
         (old-hex (when bounds (buffer-substring-no-properties (car bounds) (cdr bounds)))))
    (if (not (and bounds old-hex))
        (message "Brak koloru hex pod kursorem!")
      (let* ((zenity (executable-find "zenity"))
             (new-color
              (if zenity
                  (with-temp-buffer
                    (let ((exit-code
                           (call-process zenity nil t nil
                                         "--color-selection"
                                         "--show-palette"
                                         (format "--color=%s" old-hex))))
                      (when (= exit-code 0)
                        (string-trim (buffer-string)))))
                (read-color (format "Dostosuj kolor (obecny %s): " old-hex) nil t old-hex))))
        (when (and new-color (not (string-empty-p new-color)))
          (let ((formatted-hex
                 (cond
                  ((string-match "^#\\([0-9a-fA-F]\\{6\\}\\)" new-color)
                   (concat "#" (downcase (match-string 1 new-color))))
                  ((string-match "rgba?([ \t]*\\([0-9]+\\)[ \t]*,[ \t]*\\([0-9]+\\)[ \t]*,[ \t]*\\([0-9]+\\)" new-color)
                   (format "#%02x%02x%02x"
                           (string-to-number (match-string 1 new-color))
                           (string-to-number (match-string 2 new-color))
                           (string-to-number (match-string 3 new-color))))
                  (t nil))))
            (when formatted-hex
              (save-excursion
                (delete-region (car bounds) (cdr bounds))
                (goto-char (car bounds))
                (insert formatted-hex))
              (font-lock-flush (car bounds) (+ (car bounds) (length formatted-hex)))
              (message "Zaktualizowano kolor: %s -> %s" old-hex formatted-hex))))))))

(defun my/rainbow-colorize-clickable (orig-fn color &optional match)
  "Make highlighted hex colors clickable to open the visual color picker."
  (let ((m (or match 0)))
    (funcall orig-fn color m)
    (let ((beg (match-beginning m))
          (end (match-end m)))
      (when (and beg end)
        (put-text-property beg end 'keymap my/color-picker-keymap)
        (put-text-property beg end 'mouse-face 'highlight)
        (put-text-property beg end 'help-echo "mouse-1: Dostosuj kolor w pickerze")))))

(use-package rainbow-mode
  :ensure t
  :custom
  (rainbow-x-colors nil)
  (rainbow-html-colors nil)
  (rainbow-latex-colors nil)
  (rainbow-ansi-colors nil)
  (rainbow-r-colors nil)
  :config
  (advice-add 'rainbow-colorize-match :around #'my/rainbow-colorize-clickable)
  :hook ((prog-mode . rainbow-mode)
         (conf-mode . rainbow-mode)))

(require 'agents-modeline)
(require 'modeline)
(require 'ui-keys)

(provide 'ui-mod)
