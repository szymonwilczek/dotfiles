;;; Git and Magit keybindings -*- lexical-binding: t; -*-

;; Git navigation jumps
;; ([c / ]c)
(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    "[c" 'git-gutter:previous-hunk
    "]c" 'git-gutter:next-hunk))

;; Leader bindings
(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def

      ;; Yeah.. I have muscle memory over Lazygit
      ;; Magit is still kinda new thing for me
      "l"  '(:ignore t :which-key "Lazygit")
      "lg" '(my/open-lazygit :which-key "Lazygit")

      ;; Git prefix
      "g"  '(:ignore t :which-key "Git")
      "gg" '(magit-status :which-key "Magit Status")
      "gb" '(magit-blame :which-key "Git Blame")
      "gl" '(magit-log-current :which-key "Git Log")
      "gd" '(magit-diff-dwim :which-key "Git Diff")
      "gi" '(forge-list-issues :which-key "GitHub Issues")
      "gp" '(forge-list-pullreqs :which-key "GitHub Pull Requests")
      "gn" '(forge-list-notifications :which-key "GitHub Notifications")
      "gf" '(forge-pull :which-key "Fetch Forge (Issues/PRs)")
      "gh" '(git-gutter:popup-hunk :which-key "Show Hunk")
      "gs" '(git-gutter:stage-hunk :which-key "Stage Hunk")
      "gr" '(git-gutter:revert-hunk :which-key "Revert Hunk"))))

(provide 'git-keys)
