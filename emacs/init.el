(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))

(require 'core)
(require 'setup-vim)
(require 'setup-ui)
(require 'setup-projects)
(require 'setup-completion)
(require 'setup-tabs)
(require 'setup-dashboard)
(require 'setup-format)
(require 'setup-lsp)
(require 'setup-wakatime)
(require 'setup-autocomplete)
(require 'setup-magit)
(require 'setup-org)
(require 'setup-terminal)

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

(defun my/open-folder (dir)
  "Pick any directory. Emacs will make it a project and will load it into Treemacs."
  (interactive "DOpen folder: ")
  (let ((default-directory dir))
    (projectile-add-known-project dir)
    (when (featurep 'treemacs)
      (treemacs-display-current-project-exclusively)
      (treemacs-select-window))))


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
    "po" '(projectile-switch-project :which-key "Open Project (List)")
    "pf" '(my/open-folder :which-key "Open Folder (Anywhere)") ; <--- TWOJA NOWA SUPERBROŃ
    "pa" '(treemacs-add-project-to-workspace :which-key "Add Project to Tree")
    "pd" '(treemacs-remove-project-from-workspace :which-key "Remove Project from Tree")))


(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
  '(custom-safe-themes
     '("749a7bb14efeb8b6c9b251c7a771ab7de500b247eb35f69bfccbdfca27e0602c"
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
