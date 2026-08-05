(defun my/get-project-root ()
  "Searches for project root:
   1. Checks project.el (for .git)
   2. Checks Treemacs (if project is open there)
   3. Fallback to currently open dir."
  (or (when-let ((project (project-current)))
        (project-root project))
    (when (fboundp 'treemacs-current-workspace)
      (let ((projects (treemacs-workspace->projects (treemacs-current-workspace))))
        (when projects (treemacs-project->path (car projects)))))
    default-directory))

(defun my/consult-fd-in-project ()
  "Searches for files in current project (or current dir if not in project)."
  (interactive)
  (let ((root (my/get-project-root)))
    (consult-fd root)))

(defun my/consult-rg-in-project ()
  "Ripgrep text in current project (or dir)."
  (interactive)
  (let ((root (my/get-project-root)))
    (consult-ripgrep root)))

(use-package vertico
  :ensure t
  :init (vertico-mode 1)
  :config
  (setq vertico-count 15)
  (define-key vertico-map (kbd "C-j") 'vertico-next)
  (define-key vertico-map (kbd "C-k") 'vertico-previous)

  (vertico-multiform-mode 1)
  (setq vertico-multiform-commands
    '((evil-ex (vertico-mode . nil))
       (execute-extended-command (vertico-mode . t))
       (t (vertico-mode . t))))

  (setq vertico-multiform-categories
    '((file flat)
       (buffer flat)
       (consult-grep flat)
       (consult-location flat))))

(use-package consult
  :ensure t
  :after vertico
  :config
  (setq consult-project-function (lambda (_) (my/get-project-root)))

  (consult-customize
    consult-fd :prompt "Find File: "
    consult-ripgrep :prompt "Find Word: "
    consult-buffer :prompt "Switch Buffer: ")

  (setq consult-preview-key 'any)
  (setq consult-async-min-input 2)
  (setq consult-async-refresh-delay 0.01)
  (setq consult-async-input-throttle 0.0)
  (setq consult-async-input-debounce 0.01)
  (setq consult-async-split-style nil))

(use-package orderless
  :ensure t
  :custom (completion-styles '(orderless basic)))

(use-package marginalia
  :ensure t
  :init (marginalia-mode))

(use-package nerd-icons-completion
  :ensure t
  :after (marginalia nerd-icons)
  :config (nerd-icons-completion-mode))

(provide 'setup-find)
