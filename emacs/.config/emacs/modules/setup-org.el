(use-package org
  :ensure nil
  :custom
  (org-directory "~/orgfiles")
  (org-default-notes-file (expand-file-name "refile.org" org-directory))
  (org-agenda-files (directory-files-recursively "~/orgfiles" "\\.org$"))

  (org-capture-templates
    '(("p" "Zadanie Projektowe" entry
	(file "~/orgfiles/projects.org")
	"* TODO %?\n  SCHEDULED: %^t\n  Kontekst: %a\n\n  %x")
       ("n" "Szybka Notatka" entry
	 (file "~/orgfiles/refile.org")
	 "* %?\n  %a")))

  (org-hide-emphasis-markers t)
  (org-startup-indented t)
  (org-ellipsis " ▾")
  (org-pretty-entities t)
  (org-image-actual-width nil)

  (org-todo-keywords
    '((sequence "TODO(t)" "DOING(i)" "|" "DONE(d)" "CANCELED(c)")))

  :config
  (setq org-src-fontify-natively t)    
  (setq org-src-tab-acts-natively t)
  (setq org-edit-src-content-indentation 0)

  (org-babel-do-load-languages
    'org-babel-load-languages
    '((emacs-lisp . t)
       (js . t)
       (python . t)
       (C . t)
       )))

(use-package org-superstar
  :ensure t
  :hook (org-mode . org-superstar-mode)
  :custom
  (org-superstar-headline-bullets-list '("◉" "○" "◈" "◇" "●" "◦"))
  (org-superstar-special-todo-items t))

(use-package evil-org
  :ensure t
  :after org
  :hook (org-mode . evil-org-mode)
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

(add-hook 'org-agenda-mode-hook
  (lambda ()
    (evil-set-initial-state 'org-agenda-mode 'normal)))

(with-eval-after-load 'general
  (my-leader-def
    "o"  '(:ignore t :which-key "Org Mode")
    "oa" '(org-agenda :which-key "Agenda")
    "oc" '(org-capture :which-key "Szybka notatka (Capture)")
    "oo" '(org-open-at-point :which-key "Otwórz link") ;; Twój skrót <Leader>oo
    "oe" '(org-export-dispatch :which-key "Eksportuj")))

(provide 'setup-org)
