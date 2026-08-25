;;; Git and Magit keybindings -*- lexical-binding: t; -*-

;; Git navigation jumps
;; ([c / ]c)
(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    "[c" 'diff-hl-previous-hunk
    "]c" 'diff-hl-next-hunk))

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
      "gh" '(diff-hl-show-hunk :which-key "Show Hunk"))))

(provide 'git-keys)
