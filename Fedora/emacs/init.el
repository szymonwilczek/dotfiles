;; ==========
;; fast start 
;; ==========
(setq gc-cons-threshold (* 50 1024 1024))
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 2 1024 1024))))

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; ================
;; ui & performance
;; ================
(setq inhibit-startup-message t)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq ring-bell-function 'ignore)

;; static line numbers
(setq display-line-numbers-type t)
(global-display-line-numbers-mode t)

(setq jit-lock-chunk-size 256000)

;; bidi off 
(setq-default bidi-display-reordering 'left-to-right)
(setq bidi-inhibit-bpa t)

(blink-cursor-mode -1)
(setq resize-mini-windows nil)

(recentf-mode 1)
(setq recentf-max-saved-items 50)

;; =======
;; modules 
;; =======
(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))

(require 'evil-config)
(require 'keybinds-config)
(require 'treemacs-config)
(require 'tabs-config)
(require 'fuzzy-config)
(require 'format-config)
(require 'completion-config)
(require 'git-config)
(require 'modeline-config)
(require 'whichkey-config)
(require 'org-config)

;; ==========
;; treesitter 
;; ==========
(setq treesit-font-lock-level 4)

(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  (setq treesit-auto-langs '(c cpp java javascript typescript tsx html css json yaml))
  (global-treesit-auto-mode))

(setq major-mode-remap-alist
      '((c-mode . c-ts-mode)
        (c++-mode . c++-ts-mode)
        (c-or-c++-mode . c-or-c++-ts-mode)
        (typescript-mode . typescript-ts-mode)
        (javascript-mode . js-ts-mode)
        (js-mode . js-ts-mode)
        (css-mode . css-ts-mode)
        (java-mode . java-ts-mode)
        (html-mode . html-ts-mode)
        (json-mode . json-ts-mode)
        (yaml-mode . yaml-ts-mode)
        (tsx-mode . tsx-ts-mode)))

;; manual bindng
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'" . js-ts-mode))
(add-to-list 'auto-mode-alist '("\\.jsx\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.json\\'" . json-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-ts-mode))

(use-package markdown-mode
  :ensure t
  :mode ("\\.md\\'" . markdown-mode))


;; ======
;; tweaks 
;; ======

;; native bg for terminal usage 
(use-package ef-themes
  :config
  (load-theme 'ef-day t))

;; restore garbage collection
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024))))

;; silence ui 
(setq inhibit-startup-screen t)        ; no log 
(setq initial-scratch-message nil)     ; empty scratch 
(setq ring-bell-function 'ignore)      ; silence 

;; eglot
(use-package eglot
  :ensure nil
  :hook ((c-mode . eglot-ensure)
         (go-mode . eglot-ensure)))

;; 2. Zabij UI zanim zdąży się narysować (zero mrugania)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)



;; Zrób z Emacsa w terminalu Neovima (przejęcie myszy)
(xterm-mouse-mode 1)

;; Upewnij się, że kółko myszy jest globalnie włączone
(mouse-wheel-mode 1)

;; (Opcjonalnie) Krok scrollowania: 1 linijka zamiast przeskakiwania o pół ekranu
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1)))
(setq mouse-wheel-progressive-speed nil) ; Wyłącza przyspieszanie scrolla




;; --- Prawdziwy, systemowy schowek w terminalu i GUI ---

;; 1. Powiedz Emacsowi, żeby domyślnie ufał schowkowi systemowemu
(setq select-enable-clipboard t)
(setq select-enable-primary t)
(setq evil-kill-on-visual-paste nil)

;; 2. Most dla terminala (-nw) (automatycznie użyje wl-clipboard na Waylandzie)
(setq interprogram-cut-function
      (lambda (text)
	(let* ((process-connection-type nil)
	       (proc (start-process "wl-copy" nil "wl-copy")))
	  (process-send-string proc text)
	  (process-send-eof proc))))

(setq interprogram-paste-function
      (lambda()
	(shell-command-to-string "wl-paste -n")))




(require 'server)
(unless (server-running-p)
  (server-start))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
