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

(require 'agents-modeline)
(require 'modeline)
(require 'ui-keys)

(provide 'ui-mod)
