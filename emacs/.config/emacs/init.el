(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))
(add-to-list 'exec-path "~/.npm-global/bin")
(add-to-list 'load-path "~/.config/emacs/lisp")

(require 'core)

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
(require 'setup-mail)

(defun my/open-scratch ()
  "Opens or creates clear *scratch* buffer."
  (interactive)
  (switch-to-buffer "*scratch*"))

(defun my/new-untitled-buffer ()
  "Creates and switches to a new untitled buffer."
  (interactive)
  (let ((buf (generate-new-buffer "untitled")))
    (switch-to-buffer buf)
    (text-mode)))

(defun my/open-folder ()
  "Prompts to open a directory."
  (interactive)
  (read-directory-name "Otwórz katalog: "))

(defun my/bind-leader-keys ()
  "Bind all leader keybindings via general."
  (when (fboundp 'my-leader-def)
    (my-leader-def
      ;; F - Files / Search
      "f"  '(:ignore t :which-key "Files")
      "ff" '(my/consult-fd-in-project :which-key "Find File (Project)")
      "fw" '(my/consult-rg-in-project :which-key "Find Word (Project)")
      "fr" '(recentf-open :which-key "Recent Files")

      ;; B - Buffers
      "b"  '(:ignore t :which-key "Buffers")
      "bb" '(consult-project-buffer :which-key "Project Buffers")
      "bn" '(my/new-untitled-buffer :which-key "New Buffer")
      "bk" '(kill-current-buffer :which-key "Kill Buffer")

      ;; Tools & Window
      "T"  '(:ignore t :which-key "Toggles")
      "Tt" '(load-theme :which-key "Toggle Theme")
      "Tc" '(my/toggle-cursor-visibility :which-key "Toggle Cursor")
      "x"  '(kill-current-buffer :which-key "Kill Buffer")
      "s"  '(evil-window-vsplit :which-key "Split Vertical")
      "v"  '(evil-window-split :which-key "Split Horizontal")
      "q"  '(kill-current-buffer :which-key "Close Buffer")

      ;; E - Explorer / Treemacs
      "e"  '(:ignore t :which-key "Explorer")
      "ee" '(treemacs :which-key "Toggle Treemacs")
      "ef" '(treemacs-find-file :which-key "Find current file in tree")

      ;; O - Open
      "o"  '(:ignore t :which-key "Open")
      "os" '(my/open-scratch :which-key "Scratch Buffer")
      "om" '(my/open-mail :which-key "Open Mail")

      ;; G - Git / Magit
      "g"  '(:ignore t :which-key "Git")
      "gs" '(my/magit-status-treemacs-project :which-key "Magit Status (Treemacs Sync)")
      "lg" '(magit-status :which-key "Magit Status")
      "gl" '(magit-log-current :which-key "Magit Log")
      "gb" '(magit-blame-addition :which-key "Magit Blame")
      "gf" '(magit-fetch :which-key "Magit Fetch")
      "gP" '(magit-push-current :which-key "Magit Push")
      "gp" '(magit-pull-branch :which-key "Magit Pull")

      ;; P - Projects
      "p"  '(:ignore t :which-key "Projects")
      "pp" '(projectile-switch-project :which-key "Switch Project")
      "po" '(projectile-persp-switch-project :which-key "Open Project (List)")
      "pf" '(my/open-folder :which-key "Open Folder")
      "pa" '(treemacs-add-project-to-workspace :which-key "Add Project to Tree")
      "pd" '(treemacs-remove-project-from-workspace :which-key "Remove Project from Tree")

      ;; Harpoon / Bookmarks
      "a"  '(bookmark-set :which-key "Add Bookmark")

      ;; Config
      "r"  '(my/toggle-relative-line-numbers :which-key "Relative Lines")
      "dq" '(flymake-show-buffer-diagnostics :which-key "Diagnostics"))))

(my/bind-leader-keys)


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-vc-selected-packages
    '((ghostel :url "https://github.com/dakra/ghostel" :lisp-dir "lisp"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
