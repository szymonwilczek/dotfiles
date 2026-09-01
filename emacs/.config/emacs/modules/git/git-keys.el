;;; Git and Magit keybindings -*- lexical-binding: t; -*-

;; Git navigation jumps
;; ([c / ]c)
(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    "[c" 'git-gutter:previous-hunk
    "]c" 'git-gutter:next-hunk))

(defun my/git-conflict-next ()
  "Jump to the next conflict marker line."
  (interactive)
  (let ((orig (point)))
    (forward-line 1)
    (if (re-search-forward "^\\(<<<<<<<\\|=======\\|>>>>>>>\\)" nil t)
        (goto-char (line-beginning-position))
      (goto-char orig)
      (message "No next conflict marker"))))

(defun my/git-conflict-prev ()
  "Jump to the previous conflict marker line."
  (interactive)
  (let ((orig (point)))
    (forward-line -1)
    (if (re-search-backward "^\\(<<<<<<<\\|=======\\|>>>>>>>\\)" nil t)
        (goto-char (line-beginning-position))
      (goto-char orig)
      (message "No previous conflict marker"))))

(defun my/git-conflict-keep-upper ()
  "Keep our / upper version and refresh overlays."
  (interactive)
  (require 'smerge-mode)
  (smerge-keep-upper)
  (when (fboundp 'my/git-conflict-highlight-buffer)
    (my/git-conflict-highlight-buffer)))

(defun my/git-conflict-keep-lower ()
  "Keep their / lower version and refresh overlays."
  (interactive)
  (require 'smerge-mode)
  (smerge-keep-lower)
  (when (fboundp 'my/git-conflict-highlight-buffer)
    (my/git-conflict-highlight-buffer)))

(defun my/git-conflict-keep-all ()
  "Keep both versions and refresh overlays."
  (interactive)
  (require 'smerge-mode)
  (smerge-keep-all)
  (when (fboundp 'my/git-conflict-highlight-buffer)
    (my/git-conflict-highlight-buffer)))

;; Smerge conflict navigation jumps
(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    "[x" #'my/git-conflict-prev
    "]x" #'my/git-conflict-next))

;; Leader bindings
(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def

      ;; Yeah.. I have muscle memory over Lazygit
      ;; Magit is still kinda new thing for me
      "l"  '(:ignore t :which-key "Lazygit")
      "lg" '(my/open-lazygit :which-key "Lazygit")

      ;; Git prefix
      "g"   '(:ignore t :which-key "Git")
      "gg"  '(magit-status :which-key "Magit Status")
      "gb"  '(magit-blame :which-key "Git Blame")
      "gl"  '(magit-log-current :which-key "Git Log")
      "gd"  '(magit-diff-dwim :which-key "Git Diff")
      "gi"  '(forge-list-issues :which-key "GitHub Issues")
      "gp"  '(forge-list-pullreqs :which-key "GitHub Pull Requests")
      "gn"  '(forge-list-notifications :which-key "GitHub Notifications")
      "gf"  '(forge-pull :which-key "Fetch Forge (Issues/PRs)")

      ;; Conflict resolution
      "gc"  '(:ignore t :which-key "Conflicts")
      "gcu" '(my/git-conflict-keep-upper :which-key "Keep Ours (Upper)")
      "gcl" '(my/git-conflict-keep-lower :which-key "Keep Theirs (Lower)")
      "gca" '(my/git-conflict-keep-all :which-key "Keep Both (All)"))))

(provide 'git-keys)
