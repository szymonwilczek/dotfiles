(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))
(add-to-list 'exec-path "~/.npm-global/bin")
(add-to-list 'load-path "~/.config/emacs/lisp")

(require 'core)
(use-package texfrag :ensure t)

(require 'setup-vim)
(require 'setup-ui)
(require 'setup-projects)
(require 'setup-find)
(require 'setup-tabs)
(require 'setup-dashboard)
(require 'setup-format)
(require 'setup-lsp)
(require 'setup-wakatime)
(require 'setup-autocomplete)
(require 'setup-magit)
(require 'setup-latex)
(require 'setup-terminal)
(require 'setup-markdown)
(require 'setup-preview)
(require 'setup-sessions)
; (require 'setup-mail)

(defun my/open-scratch ()
  "Opens or creates clear *scratch* buffer."
  (interactive)
  (switch-to-buffer "*scratch*"))

(defun my/consult-fd-in-project ()
  "Searches for files in current project (or current dir if not in project)."
  (interactive)
  (let ((root (projectile-project-root)))
    (if root
      (consult-fd root)
      (consult-fd))))

(defun my/consult-rg-in-project ()
  "Ripgrep text in current project (or dir)."
  (interactive)
  (let ((root (projectile-project-root)))
    (if root
      (consult-ripgrep root)
      (consult-ripgrep))))

(with-eval-after-load 'general
  (my-leader-def
    ;; F - Files (Find)
    "f" '(:ignore t :which-key "Files")
    "ff" '(my/consult-fd-in-project :which-key "Find File (Project)")
    "fw" '(my/consult-rg-in-project :which-key "Find Word (Project)")
    "bb" '(consult-project-buffer :which-key "Project Buffers")
    
    ;; Tools 
    "tt" '(load-theme :which-key "Toggle Theme")
    "b" (lambda () (interactive) 
          (switch-to-buffer (generate-new-buffer "untitled"))
          (text-mode))
    "x" '(kill-current-buffer :which-key "Kill Buffer")
    
    ;; E - Explorer
    "e"  '(:ignore t :which-key "Explorer")
    "ee" '(treemacs :which-key "Toggle Treemacs")
    "ef" '(treemacs-find-file :which-key "Find current file in tree")

    ;; O - Open
    "o"  '(:ignore t :which-key "Open")
    "os" '(my/open-scratch :which-key "Scratch Buffer")
    "om" '(mu4e :which-key "Open Mail")

    ;; G - Git related
    "g"  '(:ignore t :which-key "Git / Code") ;; 'g' mieliśmy w LSP, tu dodajemy Git
    "gs" '(my/magit-status-treemacs-project :which-key "Magit Status (Treemacs Sync)")
    "gl" '(magit-log-current :which-key "Magit Log")
    "gb" '(magit-blame-addition :which-key "Magit Blame")
    "gf" '(magit-fetch :which-key "Magit Fetch")
    "gP" '(magit-push-current :which-key "Magit Push")
    "gp" '(magit-pull-branch :which-key "Magit Pull")
    
    ;; P - Projects
    "p"  '(:ignore t :which-key "Projects")
    "po" '(projectile-persp-switch-project :which-key "Open Project (List)")
    "pf" '(my/open-folder :which-key "Open Folder (Anywhere)") 
    "pa" '(treemacs-add-project-to-workspace :which-key "Add Project to Tree")
    "pd" '(treemacs-remove-project-from-workspace :which-key "Remove Project from Tree")))


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
    '("6a95b0faf6cee6adfda34cdfadb2fed6f4157a1d49aabef8cc9b94c187d69a1d"
       "22faff66975354a3dd145ae13934758d45930ad09cbbe8bd1ed74224e4aa5684"
       "516ec39655c85f346393f5d93e0f03602b6bfc33335bf2fd673016c9c4cdc69e"
       "6965a903ced31bd58caddb7e7035aadc47f8b0a5c57f246b698be2dfdfed2c4e"
       "f5ab1ad901eb430cdcd9b2a6824e94ff384172a9492ff7a88fe989ee2d583f09"
       "51caf9bf88aba940d98c96add138d83317d50eae4b8526612184e93473252d54"
       "2c7dc80264de0ba9409d4ebb3c7b31cf8e4982015066174c786f16a672db71b2"
       "03ffccc093c553a238a54fea13f2056749d83c24e65940f8d4bdb7135f1199a5"
       "0f738dce3f831b6d64ee3e98052bdea663b74d5149dcbbf555327dcb4517fc08"
       "749a7bb14efeb8b6c9b251c7a771ab7de500b247eb35f69bfccbdfca27e0602c"
       "546f3e8c4cb46043df1f646322c4b57049fc4c31fdf96e41db077c3408660057"
       "0a8cf72fd94bfb67dd72dc085538b39ea47aeae8bfc2b8545c0d3c99c339c204"
       default))
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
