(defun my/magit-status-treemacs-project ()
  "Open Magit for project loaded in Treemacs."
  (interactive)
  (require 'treemacs)
  (require 'magit)
  (let ((projects (treemacs-workspace->projects (treemacs-current-workspace))))
    (if projects
      (magit-status (treemacs-project->path (car projects)))
      (message "Treemacs: No open project.")
      (call-interactively #'magit-status))))

(use-package magit
  :ensure t
  :custom
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  (magit-diff-refine-hunk 'all)
  (magit-save-repository-buffers 'dontask)
  :config
  (setq auto-revert-buffer-list-filter 'magit-auto-revert-repository-buffers-p)

  (with-eval-after-load 'evil-collection
    (with-eval-after-load 'general
      (general-define-key
	:states 'normal
	:keymaps '(magit-mode-map magit-status-mode-map magit-log-mode-map magit-diff-mode-map)
	"<tab>" 'magit-section-toggle
	"<backtab>" 'magit-section-cycle
	"S-<tab>" 'magit-section-cycle
	"o" 'forge-browse
	))))

(use-package transient
  :ensure nil
  :custom
  (transient-default-level 7)
  :config
  (define-key transient-base-map (kbd "<escape>") 'transient-quit-one)
  (define-key transient-base-map (kbd "q") 'transient-quit-one))

(use-package autorevert
  :ensure nil
  :hook (after-init . global-auto-revert-mode)
  :custom
  (auto-revert-verbose nil)
  (global-auto-revert-non-file-buffers t))

(use-package forge
  :ensure t
  :after magit
  :init
  (setq auth-sources '("~/.authinfo"))
  :custom
  (forge-add-default-bindings nil)
  :config
  (auth-source-forget-all-cached))

(use-package diff-hl
  :ensure t
  :config

  (global-diff-hl-mode)
  (diff-hl-flydiff-mode 1)
  (fringe-mode '(8 . 0)) ;; 8px
  (set-face-background 'fringe (face-background 'default))

  (define-fringe-bitmap 'my-diff-plus  [0 0 0 24 24 126 126 24 24 0 0 0])
  (define-fringe-bitmap 'my-diff-minus [0 0 0 0 0 126 126 0 0 0 0 0])
  (define-fringe-bitmap 'my-diff-tilde [0 0 0 0 102 255 153 0 0 0 0 0])

  (setq diff-hl-fringe-bmp-function
    (lambda (type _pos)
      (cond
        ((eq type 'insert) 'my-diff-plus)
        ((eq type 'delete) 'my-diff-minus)
        ((eq type 'change) 'my-diff-tilde)
        (t 'my-diff-plus))))

  (let ((ins "#98c379")
         (del "#e06c75")
	 (chg "#61afef"))
    (set-face-attribute 'diff-hl-insert nil :foreground ins :background nil)
    (set-face-attribute 'diff-hl-delete nil :foreground del :background nil)
    (set-face-attribute 'diff-hl-change nil :foreground chg :background nil))

  (add-hook 'magit-pre-refresh-hook  #'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))

(provide 'setup-magit)
