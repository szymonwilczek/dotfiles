;;; Treemacs keybindings and shortcuts

(use-package general
  :after (treemacs evil)
  :config

  ;; Global Ctrl-n toggle across all Evil states
  ;; (I have strong Neovim muscle memory with this)
  (general-define-key
    :states '(normal motion visual insert)
    "C-n" #'treemacs))

;; Leader bindings
(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def

      ;; Explorer
      "e"  '(:ignore t :which-key "Explorer")
      "ee" '(treemacs :which-key "Toggle Treemacs")
      "ef" '(treemacs-find-file :which-key "Find Current File")
      "ea" '(treemacs-add-project-to-workspace :which-key "Add Project")
      "ed" '(treemacs-remove-project-from-workspace :which-key "Remove Project")

      ;; Project tree shortcuts
      "p"  '(:ignore t :which-key "Projects")
      "pa" '(treemacs-add-project-to-workspace :which-key "Add Project to Tree")
      "pd" '(treemacs-remove-project-from-workspace :which-key "Remove Project from Tree"))))

(provide 'treemacs-keys)
