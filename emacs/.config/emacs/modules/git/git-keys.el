;;; Git and Magit keybindings -*- lexical-binding: t; -*-

;; Git navigation jumps
;; ([c / ]c)
(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    "[c" 'git-gutter:previous-hunk
    "]c" 'git-gutter:next-hunk))

;; Smerge conflict navigation jumps
(with-eval-after-load 'smerge-mode
  (with-eval-after-load 'evil
    (evil-define-key 'normal smerge-mode-map
      "[n" #'smerge-prev
      "]n" #'smerge-next
      "[x" #'smerge-prev
      "]x" #'smerge-next)))

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
      "gcu" '(smerge-keep-upper :which-key "Keep Ours (Upper)")
      "gcl" '(smerge-keep-lower :which-key "Keep Theirs (Lower)")
      "gca" '(smerge-keep-all :which-key "Keep Both (All)"))))

(provide 'git-keys)
