(use-package treemacs
  :ensure t
  :defer t
  :config
  (setq treemacs-width 35)
  (setq treemacs-collapse-dirs 0)
  
  (setq treemacs-is-never-other-window nil) 

  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (pcase (cons (not (null (executable-find "git")))
               (not (null (executable-find "python3"))))
    (`(t . t)
     (treemacs-git-mode 'deferred)))

  (add-hook 'treemacs-mode-hook (lambda () (display-line-numbers-mode -1))))

(defun my/treemacs-auto-start ()
  "Open Treemacs with root to default-directory."
  (require 'treemacs)
  (let* ((dir (expand-file-name default-directory))
         (path (treemacs-canonical-path dir))
         (name (treemacs--filename path)))
    
    (setq-default default-directory dir)
    (when (get-buffer "*scratch*")
      (with-current-buffer "*scratch*"
        (setq default-directory dir)))
    (when (get-buffer "*Messages*")
      (with-current-buffer "*Messages*"
        (setq default-directory dir)))

    (--when-let (treemacs-get-local-buffer)
      (kill-buffer it))
    (treemacs--show-single-project path name)
    (other-window 1)))

(add-hook 'server-visit-hook #'my/treemacs-auto-start)
(unless (daemonp)
  (add-hook 'emacs-startup-hook #'my/treemacs-auto-start))

(use-package treemacs-evil
  :after (treemacs evil)
  :ensure t
  :config
  (define-key evil-treemacs-state-map (kbd "C-n") 'treemacs-quit)
  (define-key evil-treemacs-state-map (kbd "SPC e e") 'treemacs-quit)

  (define-key evil-treemacs-state-map (kbd "w") 'evil-forward-word-begin)
  (define-key evil-treemacs-state-map (kbd "W") 'treemacs-set-width)

  (define-key evil-treemacs-state-map (kbd "G")
	      (lambda () (interactive)
		(goto-char (point-max))
		(forward-line -1)
		(treemacs--evade-treemacs-window-if-needed)))

  (defun my/treemacs-create-file-or-dir ()
    "Create a file or directory."
    (interactive)
    (let* ((btn (button-at (point)))
           (node-path (if btn (button-get btn :local-path) default-directory))
           (base-dir (if (and node-path (file-directory-p node-path))
                         (file-name-as-directory node-path)
                       (if node-path (file-name-directory node-path) default-directory)))
           (full-path (read-string "Create: " base-dir)))
      
      (when (not (string-empty-p full-path))
        (if (string-suffix-p "/" full-path)
            (progn
              (make-directory full-path t)
              (message "Created dir: %s" full-path))
          (progn
            (make-directory (file-name-directory full-path) t)
            (write-region "" nil full-path)
            (message "Created file: %s" full-path)))
        (treemacs-refresh))))

  (define-key evil-treemacs-state-map (kbd "a") 'my/treemacs-create-file-or-dir))

(use-package nerd-icons
  :ensure t)

(use-package treemacs-nerd-icons
  :ensure t
  :after (treemacs nerd-icons)
  :config
  (treemacs-load-theme "nerd-icons"))

(use-package treemacs-evil
  :after (treemacs evil)
  :ensure t
  :config
  (define-key evil-treemacs-state-map (kbd "C-n") 'treemacs-quit)
  (define-key evil-treemacs-state-map (kbd "SPC e e") 'treemacs-quit))

(provide 'treemacs-config)
