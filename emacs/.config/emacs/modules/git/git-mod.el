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
      (switch-to-buffer buf)
      (when (fboundp 'evil-emacs-state)
        (evil-emacs-state)))))

;; Magit Configuration
(use-package magit
  :ensure t
  :custom
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  (magit-diff-refine-hunk 'all)
  (magit-save-repository-buffers 'dontask)
  :config

  ;; Evil scrolling
  (define-key magit-mode-map (kbd "z") nil)
  (define-key magit-mode-map (kbd "Z") #'magit-stash)
  (define-key magit-status-mode-map (kbd "z") nil)
  (define-key magit-status-mode-map (kbd "Z") #'magit-stash)

  ;; My Lazygit keys in Magit log & status
  (define-key magit-status-mode-map (kbd "W") #'my/magit-add-co-author)
  (define-key magit-status-mode-map (kbd "F") #'my/magit-signoff-commit)
  (define-key magit-status-mode-map (kbd "E") #'my/magit-extract-commit-files)
  (define-key magit-status-mode-map (kbd "I") #'my/magit-stage-intent)
  (define-key magit-log-mode-map (kbd "W") #'my/magit-add-co-author)
  (define-key magit-log-mode-map (kbd "F") #'my/magit-signoff-commit)
  (define-key magit-log-mode-map (kbd "E") #'my/magit-extract-commit-files)
  (define-key magit-log-mode-map (kbd "I") #'my/magit-stage-intent))

;; Git gutter indicators
(use-package diff-hl
  :ensure t
  :config
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1)
  (add-hook 'magit-pre-refresh-hook  #'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))

(require 'git-keys)

(provide 'git-mod)
