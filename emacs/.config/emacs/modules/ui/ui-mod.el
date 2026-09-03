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
(defvar my/theme-cache-file (expand-file-name ".theme-cache" user-emacs-directory))

(defun my/get-cached-theme ()
  (if (file-exists-p my/theme-cache-file)
      (intern (with-temp-buffer
                (insert-file-contents my/theme-cache-file)
                (string-trim (buffer-string))))
    'ef-bio))

(defun my/apply-custom-face-overrides (&rest _)
  (set-face-attribute 'font-lock-comment-face nil :slant 'italic :weight 'extra-light)
  (set-face-attribute 'font-lock-comment-delimiter-face nil :slant 'italic :weight 'extra-light)
  (set-face-attribute 'font-lock-keyword-face nil :weight 'demi-bold)
  (set-face-attribute 'font-lock-type-face nil :weight 'demi-bold)
  (set-face-attribute 'font-lock-preprocessor-face nil :weight 'demi-bold))

(my/apply-custom-face-overrides)
(advice-add 'load-theme :after #'my/apply-custom-face-overrides)

(advice-add 'load-theme :around
            (lambda (orig-fun theme &rest args)
              (mapc #'disable-theme custom-enabled-themes)
              (apply orig-fun theme args)
              (with-temp-file my/theme-cache-file
                (insert (symbol-name theme)))))

(use-package ef-themes
  :ensure t
  :config
  (setq ef-themes-to-toggle '(ef-bio ef-autumn))
  (defun my/apply-cached-theme (&optional frame)
    (let ((theme (my/get-cached-theme)))
      (with-selected-frame (or frame (selected-frame))
        (mapc #'disable-theme custom-enabled-themes)
        (load-theme theme t))))

  (my/apply-cached-theme))

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

(require 'agents-modeline)
(require 'modeline)
(require 'ui-keys)

(provide 'ui-mod)
