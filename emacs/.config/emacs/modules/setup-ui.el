(use-package emacs
  :config
  (set-face-attribute 'default nil
    :family "Typus Mono 95"
    :height 120
    :weight (if (display-graphic-p) 'semi-bold 'normal))
  (setq-default cursor-type 'box)
  (setq-default cursor-in-non-selected-windows nil)
  (setq-default x-stretch-cursor t)
  (blink-cursor-mode -1))

(global-display-line-numbers-mode 1)
(global-hl-line-mode 1)
(setq-default display-line-numbers-width 3)

(defvar my/theme-cache-file (expand-file-name ".theme-cache" user-emacs-directory)
  "File that contains name of the last used theme.")

(defun my/get-cached-theme ()
  "Reads theme from file. If the file doesnt exists, returns ef-autumn."
  (if (file-exists-p my/theme-cache-file)
      (intern (with-temp-buffer
                (insert-file-contents my/theme-cache-file)
                (string-trim (buffer-string))))
    'ef-autumn))

(advice-add 'load-theme :around
            (lambda (orig-fun theme &rest args)
              (mapc #'disable-theme custom-enabled-themes)
              (apply orig-fun theme args)
              (with-temp-file my/theme-cache-file
                (insert (symbol-name theme)))))

(use-package ef-themes
  :config 
  (defun my/apply-cached-theme (&rest _)
    "Loads theme in save environment."
    (let ((theme (my/get-cached-theme)))
      (mapc #'disable-theme custom-enabled-themes)
      (load-theme theme t)))

  (if (daemonp)
      (add-hook 'server-after-make-frame-hook #'my/apply-cached-theme)
    (my/apply-cached-theme)))

(use-package which-key
  :init (which-key-mode))

(use-package nerd-icons
  :custom
  (nerd-icons-font-family "Typus Mono 95"))

(use-package treemacs-nerd-icons
  :ensure t
  :after (treemacs nerd-icons)
  :config
  (treemacs-load-theme "nerd-icons"))

(use-package treemacs
  :ensure t
  :config
  (setq treemacs-no-png-images t
    treemacs-width 40
    treemacs-indentation 2
    treemacs-show-cursor nil
    treemacs-space-between-root-nodes nil
    treemacs-is-never-other-window nil)

  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-fringe-indicator-mode nil))

(add-to-list 'default-frame-alist '(internal-border-width . 6))
(fringe-mode 10)
(add-hook 'treemacs-mode-hook (lambda () (display-line-numbers-mode -1)))
(setq treemacs-indentation 2)

(defvar my/treemacs-theme-version 0)

(defun my/treemacs-apply-theme (&rest _)
  "Applies theme for Treemacs."
  (setq my/treemacs-theme-version (1+ my/treemacs-theme-version))
  
  (let ((bg (face-background 'default nil t))
        (current-version my/treemacs-theme-version))
    
    (when (and bg (not (string= bg "unspecified-bg")))
      (dolist (buf (buffer-list))
        (with-current-buffer buf
          (when (and (eq major-mode 'treemacs-mode)
                     (= current-version my/treemacs-theme-version))
            
            (setq header-line-format " ")
            (setq face-remapping-alist (assq-delete-all 'header-line face-remapping-alist))
            (face-remap-add-relative 'header-line
                                     (list :background bg :box nil :underline nil))))))))

(add-hook 'treemacs-mode-hook #'my/treemacs-apply-theme)
(advice-add 'load-theme :after #'my/treemacs-apply-theme)

(use-package treemacs-evil
  :after (treemacs evil)
  :ensure t)

(defun my/save-bg-to-cache (&rest _)
  (let ((bg (face-background 'default nil t)))
    (when (and bg (string-prefix-p "#" bg) (not (string= bg "unspecified-bg")))
      (with-temp-file (expand-file-name ".bg-cache" user-emacs-directory)
        (insert bg)))))

(advice-add 'load-theme :after #'my/save-bg-to-cache)
(add-hook 'kill-emacs-hook #'my/save-bg-to-cache)

(provide 'setup-ui)
