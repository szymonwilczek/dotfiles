;;; Magit, diff-hl and custom Git commands -*- lexical-binding: t; -*-

;; Custom Git Commands
;; (ported from my Lazygit config)
(defun my/magit-add-co-author (author)
  "Add Co-authored-by trailer to commit at point or HEAD."
  (interactive
   (let* ((cmd "(git log --format='%aN <%aE>'; git log --all --format='%(trailers:key=Co-authored-by,valueonly=true)') | sed '/^$/d' | sort -u")
          (authors (split-string (shell-command-to-string cmd) "\n" t))
          (chosen (completing-read "Pick Co-author: " authors nil nil)))
     (list chosen)))
  (let* ((commit (or (magit-commit-at-point) (magit-rev-parse "HEAD")))
         (head (magit-rev-parse "HEAD"))
         (branch (magit-get-current-branch)))
    (if (magit-rev-equal commit head)
        (magit-call-git "commit" "--amend" "--no-edit" (format "--trailer=Co-authored-by: %s" author))
      (if (and branch (magit-commit-p commit))
          (progn
            (magit-call-git "checkout" commit)
            (magit-call-git "commit" "--amend" "--no-edit" (format "--trailer=Co-authored-by: %s" author))
            (magit-call-git "rebase" "--onto" "HEAD" commit branch))
        (user-error "Cannot rebase without an active branch")))
    (magit-refresh)))

(defun my/magit-signoff-commit ()
  "Add Signed-off-by trailer to commit at point or HEAD."
  (interactive)
  (let* ((commit (or (magit-commit-at-point) (magit-rev-parse "HEAD")))
         (head (magit-rev-parse "HEAD"))
         (branch (magit-get-current-branch)))
    (if (magit-rev-equal commit head)
        (magit-call-git "commit" "--amend" "--no-edit" "--signoff")
      (if (and branch (magit-commit-p commit))
          (progn
            (magit-call-git "checkout" commit)
            (magit-call-git "commit" "--amend" "--no-edit" "--signoff")
            (magit-call-git "rebase" "--onto" "HEAD" commit branch))
        (user-error "Cannot rebase without an active branch")))
    (magit-refresh)))

(defun my/magit-extract-commit-files ()
  "Extract files from commit (Mixed reset + Empty commit with message).
Allowed during an active rebase at the current HEAD commit."
  (interactive)
  (unless (magit-rebase-in-progress-p)
    (user-error "Error: Rebase is not in progress"))
  (let* ((head (magit-rev-parse "HEAD"))
         (commit-at-point (magit-commit-at-point)))
    (when (and commit-at-point
               (not (magit-rev-equal commit-at-point head)))
      (user-error "Error: Cursor must be on the HEAD commit (%s)" (magit-rev-format "%h" head)))
    (magit-call-git "reset" "--mixed" "HEAD~1")
    (magit-call-git "commit" "--allow-empty" "-C" head)
    (ignore-errors (magit-call-git "add" "-N" "."))
    (magit-refresh)
    (message "Files extracted from commit %s (ready in Unstaged changes)." (magit-rev-format "%h" head))))

(defun my/magit-stage-intent ()
  "Track untracked file or all files with intent-to-add so they appear in Unstaged changes."
  (interactive)
  (let ((file (magit-file-at-point)))
    (if file
        (magit-call-git "add" "-N" "--" file)
      (magit-call-git "add" "-N" "."))
    (magit-refresh)))

(defun my/magit-remote-to-http-url (remote-url)
  "Convert SSH or HTTPS git remote URL to base HTTP browser URL."
  (let ((url (replace-regexp-in-string "\\.git\\'" "" remote-url)))
    (cond
     ((string-prefix-p "git@" url)
      (let* ((after-at (substring url 4))
             (colon-pos (string-search ":" after-at)))
        (format "https://%s/%s" (substring after-at 0 colon-pos) (substring after-at (1+ colon-pos)))))
     ((string-prefix-p "ssh://git@" url)
      (let* ((after-at (substring url 10))
             (slash-pos (string-search "/" after-at)))
        (format "https://%s/%s" (substring after-at 0 slash-pos) (substring after-at (1+ slash-pos)))))
     ((string-prefix-p "http://" url)
      (concat "https://" (substring url 7)))
     ((string-prefix-p "https://" url)
      url)
     (t (concat "https://" url)))))

(defun my/magit-browse-at-point ()
  "Open commit, branch, or repository at point in the remote web browser."
  (interactive)
  (require 'magit)
  (let* ((remote-url (or (magit-get "remote" (or (magit-get-remote) "origin") "url")
                         (magit-get "remote" "origin" "url")))
         (commit (or (magit-commit-at-point)
                     (magit-branch-or-commit-at-point)))
         (branch (magit-branch-at-point)))
    (if (not remote-url)
        (user-error "No Git remote URL found for this repository")
      (let* ((base-url (my/magit-remote-to-http-url remote-url))
             (target-url
              (cond
               (commit
                (format "%s/commit/%s" base-url commit))
               (branch
                (format "%s/tree/%s" base-url branch))
               (t
                base-url))))
        (message "Opened %s in browser." target-url)
        (browse-url target-url)))))

(defun my/open-lazygit ()
  "Open Lazygit inside Ghostel terminal in the current project root or directory."
  (interactive)
  (let* ((proj-root (or (and (fboundp 'projectile-project-root) (projectile-project-root))
                        default-directory))
         (old-buf (get-buffer "*lazygit*"))
         (script-path (expand-file-name "scripts/lazygit-edit.sh" user-emacs-directory))
         (launcher-path (expand-file-name "scripts/run-lazygit.sh" user-emacs-directory))
         (override-cfg (expand-file-name ".cache/lazygit-emacs.yml" user-emacs-directory)))
    (make-directory (file-name-directory override-cfg) t)
    (with-temp-file override-cfg
      (insert (format "gui:\n  nerdFontsVersion: \"3\"\n\nos:\n  editPreset: \"\"\n  edit: \"sh %s {{filename}}\"\n  editAtLine: \"sh %s {{filename}} {{line}}\"\n  open: \"sh %s {{filename}}\"\n  suspendOnEdit: false\n"
                      script-path script-path script-path)))
    (when (and old-buf (buffer-live-p old-buf))
      (kill-buffer old-buf))
    (let* ((default-directory proj-root)
           (ghostel-shell launcher-path)
           (ghostel-buffer-name "*lazygit*")
           (buf (ghostel t)))
      (delete-other-windows)
      (switch-to-buffer buf))))

;; Magit Configuration
(use-package magit
  :ensure t
  :defer t
  :init
  (setq with-editor-emacsclient-executable "emacsclient")
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  (magit-diff-refine-hunk 'all)
  (magit-save-repository-buffers 'dontask)
  :config
  (setq epa-file-default-user-key "B8E944071CB7EB8A")

  ;; Turn off line numbers
  ;; This caused flashbangs...
  (add-hook 'git-commit-mode-hook (lambda () (display-line-numbers-mode -1)))

  ;; -s (--signoff) and -S (--gpg-sign) in Magit commit
  ;; This is the only way
  (with-eval-after-load 'magit-commit
    (when-let* ((proto (get 'magit-commit 'transient--prefix)))
      (oset proto value '("--gpg-sign=B8E944071CB7EB8A" "--signoff" "--verbose"))))

  ;; Evil scrolling
  (define-key magit-mode-map (kbd "z") nil)
  (define-key magit-mode-map (kbd "Z") #'magit-stash)
  (define-key magit-status-mode-map (kbd "z") nil)
  (define-key magit-status-mode-map (kbd "Z") #'magit-stash)

  ;; 'o' key in Magit (Open in browser)
  (define-key magit-mode-map (kbd "o") #'my/magit-browse-at-point)
  (define-key magit-status-mode-map (kbd "o") #'my/magit-browse-at-point)
  (define-key magit-log-mode-map (kbd "o") #'my/magit-browse-at-point)
  (define-key magit-revision-mode-map (kbd "o") #'my/magit-browse-at-point)

  (with-eval-after-load 'evil
    (dolist (map (list magit-mode-map magit-status-mode-map magit-log-mode-map magit-revision-mode-map))
      (evil-define-key* '(normal visual motion emacs) map "o" #'my/magit-browse-at-point)))

  ;; My Lazygit keys in Magit log & status
  (define-key magit-status-mode-map (kbd "W") #'my/magit-add-co-author)
  (define-key magit-status-mode-map (kbd "F") #'my/magit-signoff-commit)
  (define-key magit-status-mode-map (kbd "E") #'my/magit-extract-commit-files)
  (define-key magit-status-mode-map (kbd "I") #'my/magit-stage-intent)
  (define-key magit-log-mode-map (kbd "W") #'my/magit-add-co-author)
  (define-key magit-log-mode-map (kbd "F") #'my/magit-signoff-commit)
  (define-key magit-log-mode-map (kbd "E") #'my/magit-extract-commit-files)
  (define-key magit-log-mode-map (kbd "I") #'my/magit-stage-intent))

(with-eval-after-load 'evil-collection-magit
  (with-eval-after-load 'magit
    (dolist (map (list magit-mode-map magit-status-mode-map magit-log-mode-map magit-revision-mode-map))
      (evil-define-key* '(normal visual motion emacs) map "o" #'my/magit-browse-at-point))))

;; GitHub Issues and Pull Requests
(use-package forge
  :ensure t
  :defer t
  :after magit
  :init
  (setq forge-add-default-bindings nil)
  :config
  (setq forge-database-connector 'sqlite-builtin))

;; Git gutter indicators
(use-package git-gutter
  :ensure t
  :hook (prog-mode . git-gutter-mode)
  :config
  (setq git-gutter:update-interval 0)
  (add-hook 'magit-post-refresh-hook #'git-gutter:update-all-windows)
  (add-hook 'focus-in-hook           #'git-gutter:update-all-windows)
  (add-hook 'after-save-hook         #'git-gutter:update-all-windows)
  (add-hook 'after-revert-hook       #'git-gutter:update-all-windows))

(use-package git-gutter-fringe
  :ensure t
  :after git-gutter
  :config
  (define-fringe-bitmap 'git-gutter-fr:added [224] nil nil '(center repeated))
  (define-fringe-bitmap 'git-gutter-fr:modified [224] nil nil '(center repeated))
  (define-fringe-bitmap 'git-gutter-fr:deleted [128 192 224 240] nil nil 'bottom)

  ;; Sync gutter colors with active theme
  (defun my/git-gutter-sync-theme-faces (&rest _)
    "Synchronize git-gutter colors with the active theme and ensure transparent background."
    (cl-flet ((get-fg (face) (when (and (facep face) (face-foreground face nil t))
                               (face-foreground face nil t))))
      (let ((add-fg (or (get-fg 'diff-added)
                        (get-fg 'success)
                        (get-fg 'magit-diff-added-highlight)
                        (get-fg 'magit-diff-added)))
            (mod-fg (or (get-fg 'warning)
                        (get-fg 'font-lock-warning-face)
                        (get-fg 'diff-changed)
                        (get-fg 'magit-diff-modified-highlight)))
            (del-fg (or (get-fg 'error)
                        (get-fg 'diff-removed)
                        (get-fg 'magit-diff-removed-highlight)
                        (get-fg 'magit-diff-removed))))
        (when add-fg
          (set-face-attribute 'git-gutter-fr:added nil :foreground add-fg :background 'unspecified)
          (set-face-attribute 'git-gutter:added nil :foreground add-fg :background 'unspecified))
        (when mod-fg
          (set-face-attribute 'git-gutter-fr:modified nil :foreground mod-fg :background 'unspecified)
          (set-face-attribute 'git-gutter:modified nil :foreground mod-fg :background 'unspecified))
        (when del-fg
          (set-face-attribute 'git-gutter-fr:deleted nil :foreground del-fg :background 'unspecified)
          (set-face-attribute 'git-gutter:deleted nil :foreground del-fg :background 'unspecified))
        (set-face-attribute 'fringe nil :background 'unspecified))))

  (my/git-gutter-sync-theme-faces)
  (advice-add 'load-theme :after #'my/git-gutter-sync-theme-faces))

(require 'git-keys)

(provide 'git-mod)
