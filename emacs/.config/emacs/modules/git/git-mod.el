;;; Magit, diff-hl and custom Git commands

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
    (if (string= commit head)
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
    (if (string= commit head)
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
Only allowed during an active rebase on the exact commit at HEAD."
  (interactive)
  (let* ((commit (magit-commit-at-point))
         (head (magit-rev-parse "HEAD")))
    (unless (and (magit-rebase-in-progress-p)
                 commit
                 (string= commit head))
      (user-error "Error: You can do that ONLY during REBASE on THAT commit."))
    (magit-call-git "reset" "--mixed" (format "%s~1" commit))
    (magit-call-git "commit" "--allow-empty" "-C" commit)
    (magit-refresh)))

;; Magit Configuration
(use-package magit
  :ensure t
  :custom
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  (magit-diff-refine-hunk 'all)
  (magit-save-repository-buffers 'dontask)
  :config

  ;; My Lazygit keys in Magit log & status
  (define-key magit-status-mode-map (kbd "W") #'my/magit-add-co-author)
  (define-key magit-status-mode-map (kbd "F") #'my/magit-signoff-commit)
  (define-key magit-status-mode-map (kbd "E") #'my/magit-extract-commit-files)
  (define-key magit-log-mode-map (kbd "W") #'my/magit-add-co-author)
  (define-key magit-log-mode-map (kbd "F") #'my/magit-signoff-commit)
  (define-key magit-log-mode-map (kbd "E") #'my/magit-extract-commit-files))

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
