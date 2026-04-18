(use-package org
  :ensure nil
  :config
  (setq org-directory "~/org")
  (unless (file-exists-p org-directory)
    (make-directory org-directory t))

  (setq org-agenda-files (list org-directory))

  (setq org-startup-indented t        ;; indents 
        org-hide-emphasis-markers t    ;; hide *bold*, /italic/ markers 
        org-startup-folded 'content    ;; expanded headers for 1 lvl
        org-ellipsis " ▾"             ;; instead of "..."
        org-return-follows-link t      ;; Enter on the link opens it
        org-log-done 'time)            ;; save time for TODO

  (setq org-todo-keywords
        '((sequence "TODO(t)" "IN-PROGRESS(i)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)")))

  (setq org-todo-keyword-faces
        '(("TODO" . (:foreground "#e45649" :weight bold))
          ("IN-PROGRESS" . (:foreground "#da8548" :weight bold))
          ("WAITING" . (:foreground "#986801" :weight bold))
          ("DONE" . (:foreground "#50a14f" :weight bold))
          ("CANCELLED" . (:foreground "#9ca0a4" :weight bold))))

  (setq org-capture-templates
        '(("t" "TODO" entry (file+headline "~/org/tasks.org" "Inbox")
           "* TODO %?\n  %U\n")
          ("n" "Notatka" entry (file+headline "~/org/notes.org" "Notatki")
           "* %?\n  %U\n")
          ("j" "Dziennik" entry (file+datetree "~/org/journal.org")
           "* %?\n  %U\n"))))

(use-package evil-org
  :ensure t
  :after (evil org)
  :hook (org-mode . evil-org-mode)
  :config
  (evil-org-set-key-theme '(navigation insert textobjects additional calendar todo)))

(use-package evil-org-agenda
  :ensure nil
  :after evil-org
  :config
  (evil-org-agenda-set-keys))

(provide 'org-config)
