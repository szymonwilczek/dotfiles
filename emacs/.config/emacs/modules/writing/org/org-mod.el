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


(use-package ox-latex
  :ensure nil
  :after org
  :config
  (setq org-latex-pdf-process
        '("latexmk -pdf -interaction=nonstopmode -output-directory=%o %f"))
  (setq org-latex-compiler "pdflatex")
  (setq org-latex-default-packages-alist
        '(("AUTO" "inputenc" t ("pdflatex"))
          ("T1"   "fontenc"   t ("pdflatex"))
          (""     "graphicx"  t)
          (""     "longtable" nil)
          (""     "amsmath"   t)
          (""     "amssymb"   t)
          (""     "hyperref"  nil))))

(defun my/org-export-and-view-pdf ()
  "Export current Org buffer to PDF via LaTeX and view it in a right split."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Current buffer is not in Org-mode"))
  (save-buffer)
  (message "⏳ Exporting Org to PDF...")
  (let ((pdf-file (org-latex-export-to-pdf)))
    (if (not (and pdf-file (file-exists-p pdf-file)))
        (message "❌ Org PDF export failed.")
      (message "✅ Org exported to PDF: %s" (file-name-nondirectory pdf-file))
      (let* ((pdf-buffer (or (find-buffer-visiting pdf-file)
                             (find-file-noselect pdf-file)))
             (win (get-buffer-window pdf-buffer)))
        (with-current-buffer pdf-buffer
          (unless (derived-mode-p 'doc-view-mode)
            (doc-view-mode))
          (auto-revert-mode 1))
        (if win
            (select-window win)
          (let ((new-win (split-window-right)))
            (set-window-buffer new-win pdf-buffer)
            (select-window new-win)))))))


(require 'org-keybindings)

(provide 'org-mod)
