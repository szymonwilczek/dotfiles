;;; Base Org-mode configuration -*- lexical-binding: t; -*-

(use-package org
  :ensure nil
  :defer t
  :hook ((org-mode . visual-line-mode)
         (org-mode . (lambda () (setq-local tab-width 8))))
  :config

  ;; Visuals and syntax highlighting
  (setq org-ellipsis " ▾"
        org-hide-emphasis-markers t
        org-src-fontify-natively t
        org-fontify-whole-heading-line t
        org-fontify-quote-and-verse-blocks t
        org-fontify-done-headline t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 2
        org-return-follows-link t
        org-startup-folded 'overview
        org-log-done 'time)

  (setq org-todo-keywords
        '((sequence "TODO(t)" "IN-PROGRESS(i)" "WAIT(w)" "|" "DONE(d)" "CANCELLED(c)"))))

;; Evil navigation
(with-eval-after-load 'org
  (with-eval-after-load 'evil
    (evil-define-key '(normal visual motion) org-mode-map
      (kbd "TAB")   #'org-cycle
      (kbd "<tab>") #'org-cycle
      "za"          #'org-cycle
      "zA"          #'org-shifttab
      "gh"          #'org-up-element
      "gj"          #'org-forward-heading-same-level
      "gk"          #'org-backward-heading-same-level
      "gl"          #'org-down-element
      (kbd "M-h")   #'org-metaleft
      (kbd "M-l")   #'org-metaright
      (kbd "M-j")   #'org-metadown
      (kbd "M-k")   #'org-metaup
      (kbd "M-RET") #'org-meta-return
      (kbd "M-S-RET") #'org-insert-todo-heading)
    (evil-define-key 'insert org-mode-map
      (kbd "M-RET") #'org-meta-return
      (kbd "M-S-RET") #'org-insert-todo-heading)))


(require 'org-keybindings)

(provide 'org-mod)
