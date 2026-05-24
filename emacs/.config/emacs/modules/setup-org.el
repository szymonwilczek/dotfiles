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
	 "* %?\n  %a")
       ("l" "Plan Wykładu" entry
	 (file "~/orgfiles/lectures.org")
	 "* LECTURE %?\n  SCHEDULED: %^t\n  Przedmiot: %^{Przedmiot}\n  Temat: %^{Temat}\n\n** Cele Wykładu:\n- \n\n** Notatki:\n- ")
       ("e" "Egzamin/Ocenianie" entry
	 (file "~/orgfiles/grading.org")
	 "* EXAM %?\n  DEADLINE: %^t\n  Przedmiot: %^{Przedmiot}\n  Grupa: %^{Grupa}\n\n** Lista studentów:\n| Nazwisko i Imię | Album | Ocena |\n|-----------------+-------+-------|\n|                 |       |       |\n\n#+TBLFM: ")
       ("s" "Harmonogram Akademicki" entry
	 (file "~/orgfiles/schedule.org")
	 "* TODO %?\n  SCHEDULED: %^t\n  Kategoria: %^{Kategoria|Konsultacje|Rada Wydziału|Seminarium}")))

  (org-hide-emphasis-markers t)
  (org-startup-indented t)
  (org-ellipsis " ▾")
  (org-pretty-entities t)
  (org-image-actual-width nil)

  (org-todo-keywords
    '((sequence "TODO(t)" "DOING(i)" "LECTURE(l)" "EXAM(e)" "GRADE(g)" "REVIEW(r)" "|" "DONE(d)" "CANCELED(c)")))

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

(use-package org-tree-slide
  :ensure t
  :after org
  :custom
  (org-tree-slide-header nil)
  (org-tree-slide-slide-in-effect nil)
  :config
  (defvar-local my/org-tree-slide-cookie nil)
  (defvar-local my/org-tree-slide-old-modeline nil)

  (defun my/org-tree-slide-start ()
    "Clean up UI when starting slide presentation."
    (setq my/org-tree-slide-cookie (face-remap-add-relative 'default :height 1.8))
    (when (bound-and-true-p display-line-numbers-mode)
      (display-line-numbers-mode -1))
    (setq my/org-tree-slide-old-modeline mode-line-format)
    (setq mode-line-format nil)
    (setq-local left-margin-width 12)
    (setq-local right-margin-width 12)
    (set-window-margins nil left-margin-width right-margin-width)
    (recenter-top-bottom))

  (defun my/org-tree-slide-stop ()
    "Restore UI when stopping slide presentation."
    (when my/org-tree-slide-cookie
      (face-remap-remove-relative my/org-tree-slide-cookie)
      (setq my/org-tree-slide-cookie nil))
    (when (and (boundp 'global-display-line-numbers-mode) global-display-line-numbers-mode)
      (display-line-numbers-mode 1))
    (when my/org-tree-slide-old-modeline
      (setq mode-line-format my/org-tree-slide-old-modeline)
      (setq my/org-tree-slide-old-modeline nil))
    (set-window-margins nil 0 0)
    (recenter-top-bottom))

  (add-hook 'org-tree-slide-play-start-hook #'my/org-tree-slide-start)
  (add-hook 'org-tree-slide-play-stop-hook #'my/org-tree-slide-stop)

  (with-eval-after-load 'evil
    (evil-define-key 'normal org-tree-slide-mode-map
      (kbd "<right>") #'org-tree-slide-move-next-tree
      (kbd "<left>") #'org-tree-slide-move-previous-tree
      (kbd "n") #'org-tree-slide-move-next-tree
      (kbd "p") #'org-tree-slide-move-previous-tree)))

(with-eval-after-load 'general
  (my-leader-def
    "o"  '(:ignore t :which-key "Org Mode")
    "oa" '(org-agenda :which-key "Agenda")
    "oc" '(org-capture :which-key "Szybka notatka (Capture)")
    "oo" '(org-open-at-point :which-key "Otwórz link")
    "oe" '(org-export-dispatch :which-key "Eksportuj")
    "op" '(org-tree-slide-mode :which-key "Tryb prezentacji (Slides)")))

(provide 'setup-org)
