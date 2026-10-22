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
        org-src-content-indentation 2
        org-return-follows-link t
        org-startup-folded 'overview
        org-log-done 'time)

  ;; Set directly, not through Custom, which copies them into custom.el
  ;; and drops them again whenever a theme is enabled after them.
  ;; Enabling a theme recomputes faces, so reapply after each one.
  (defun my/org-apply-face-overrides (&rest _)
    "Apply heading and block delimiter faces over the current theme."
    (set-face-attribute 'org-document-title nil
                        :inherit 'default :weight 'bold :height 1.4 :underline nil)
    (set-face-attribute 'org-level-1 nil :inherit 'default :weight 'bold :height 1.25)
    (set-face-attribute 'org-level-2 nil :inherit 'default :weight 'bold :height 1.15)
    (set-face-attribute 'org-level-3 nil :inherit 'default :weight 'bold :height 1.08)
    (set-face-attribute 'org-level-4 nil :inherit 'default :weight 'semi-bold :height 1.02)
    (set-face-attribute 'org-block-begin-line nil
                        :inherit 'font-lock-comment-face :slant 'italic)
    (set-face-attribute 'org-block-end-line nil
                        :inherit 'font-lock-comment-face :slant 'italic))

  (my/org-apply-face-overrides)
  (add-hook 'enable-theme-functions #'my/org-apply-face-overrides)

  (setq org-todo-keywords
        '((sequence "TODO(t)" "IN-PROGRESS(i)" "WAIT(w)" "|" "DONE(d)" "CANCELLED(c)")))

  ;; LaTeX Math Preview
  (setq org-preview-latex-default-process 'dvisvgm)
  (setq org-format-latex-options (plist-put org-format-latex-options :scale 1.35))
  (setq org-format-latex-options (plist-put org-format-latex-options :foreground 'default))
  (setq org-format-latex-options (plist-put org-format-latex-options :background 'default))

  ;; Org Citations
  (require 'oc)
  (require 'oc-basic)
  (require 'oc-csl)
  (setq org-cite-global-bibliography
        (seq-filter #'file-exists-p
                    (list (expand-file-name "~/references/references.bib")
                          (expand-file-name "~/references.bib"))))
  (setq org-cite-export-processors
        '((latex basic)
          (t csl))))

(use-package calendar
  :ensure nil
  :custom
  (calendar-week-start-day 1) ; Monday
  (calendar-date-style 'iso)
  (calendar-day-name-array ["Niedziela" "Poniedziałek" "Wtorek" "Środa" "Czwartek" "Piątek" "Sobota"])
  (calendar-month-name-array ["Styczeń" "Luty" "Marzec" "Kwiecień" "Maj" "Czerwiec" "Lipiec" "Sierpień" "Wrzesień" "Październik" "Listopad" "Grudzień"]))

(use-package plan-polsl
  :vc (:url "https://github.com/szymonwilczek/plan-polsl.el" :branch "main" :rev :newest)
  :custom
  (plan-polsl-id "343266256")
  (plan-polsl-type 0)
  (plan-polsl-auto-add-to-agenda nil)
  (plan-polsl-notes-directory "~/Dokumenty/GitHub/polibuda-notatki")
  (plan-polsl-events-file (expand-file-name "polsl-wydarzenia.org" user-emacs-directory))
  :config
  (setq plan-polsl-target-file (expand-file-name "~/Dokumenty/writings/plan-polsl.org")))

(use-package org-appear
  :ensure t
  :after org
  :hook (org-mode . org-appear-mode)
  :config
  (setq org-appear-autoemphasis t
        org-appear-autolinks t
        org-appear-autosubmarkers t
        org-appear-autoentities t
        org-appear-inside-latex t
        org-appear-delay 0.0))

(use-package evil-org
  :ensure t
  :after (org evil)
  :hook (org-mode . evil-org-mode)
  :custom
  (evil-org-key-theme '(navigation insert textobjects additional return))
  :config
  (evil-org-set-key-theme)
  (evil-define-key '(normal visual) 'evil-org-mode
    (kbd "TAB")   #'my/org-cycle-dwim
    (kbd "<tab>") #'my/org-cycle-dwim))

(defun my/org-toggle-emphasis-markers ()
  "Toggle visibility of Org emphasis markers (* / _ = ~) in this buffer.
Org reads the option when it sets up font lock, and org-appear when
it is enabled, so both are set up again."
  (interactive)
  (setq-local org-hide-emphasis-markers (not org-hide-emphasis-markers))
  (org-restart-font-lock)
  (when (bound-and-true-p org-appear-mode)
    (org-appear-mode -1)
    (org-appear-mode 1))
  (message "Org emphasis markers: %s" (if org-hide-emphasis-markers "hidden" "visible")))

(defun my/org-insert-link-dwim ()
  "Insert an Org link, with the URL from the clipboard already typed in.
In normal state the link goes after the cursor, like `a'; a visual
selection becomes its description."
  (interactive)
  (let ((url (ignore-errors (string-trim (current-kill 0 t)))))
    (when (and (evil-normal-state-p) (not (eolp)))
      (forward-char))
    (if (and url (string-match-p "\\`[a-z][a-z0-9+.-]*:[^ \t\n]+\\'" url))
        (minibuffer-with-setup-hook (lambda () (insert url))
          (call-interactively #'org-insert-link))
      (call-interactively #'org-insert-link))))

(defun my/org-toggle-latex-preview ()
  "Toggle LaTeX math preview for equation at point or entire buffer."
  (interactive)
  (if (org-inside-LaTeX-fragment-p)
      (org-latex-preview)
    (org-latex-preview '(16))))

(defun my/org-cycle-dwim ()
  "Fold or unfold what point is in, wherever it is on the line.
On a heading, cycle it; on a list item with children, cycle the item;
on an item without children, cycle the item above it; anywhere else
in a section, fold that section and go to its heading.  Tables, blocks
and the text before the first heading keep `org-cycle'."
  (interactive)
  (cond
   ((org-at-heading-p)
    (when (invisible-p (point))
      (beginning-of-line))
    (org-cycle))
   ((or (org-at-table-p)
        (org-in-src-block-p)
        (org-before-first-heading-p))
    (org-cycle))
   ((org-in-item-p)
    (goto-char (org-in-item-p))
    (let ((struct (org-list-struct)))
      (unless (org-list-has-child-p (point) struct)
        (let ((parent (org-list-get-parent (point) struct (org-list-parents-alist struct))))
          (when parent (goto-char parent)))))
    (if (org-list-has-child-p (point) (org-list-struct))
        (org-cycle)
      (org-back-to-heading t)
      (org-fold-hide-subtree)))
   (t
    (org-back-to-heading t)
    (org-fold-hide-subtree))))

;; Evil navigation
(with-eval-after-load 'org
  (with-eval-after-load 'evil
    (evil-define-key '(normal visual motion) org-mode-map
      (kbd "TAB")   #'my/org-cycle-dwim
      (kbd "<tab>") #'my/org-cycle-dwim
      "za"          #'my/org-cycle-dwim)))


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


(use-package ox-beamer
  :ensure nil
  :after ox-latex
  :config
  (add-to-list 'org-latex-classes
               '("beamer"
                 "\\documentclass[presentation]{beamer}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}"))))

(defun my/org-beamer-export-and-view-pdf ()
  "Export current Org buffer to Beamer presentation PDF and view it in a right split."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Current buffer is not in Org-mode"))
  (save-buffer)
  (message "⏳ Exporting Org to Beamer slides PDF...")
  (let ((pdf-file (org-beamer-export-to-pdf)))
    (if (not (and pdf-file (file-exists-p pdf-file)))
        (message "❌ Beamer PDF export failed.")
      (message "✅ Beamer slides exported to PDF: %s" (file-name-nondirectory pdf-file))
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

(defvar my/presentation-saved-window-config nil
  "Saved window configuration before entering presentation fullscreen mode.")

(defvar my/presentation-saved-fullscreen nil
  "Saved frame fullscreen parameter before presentation mode.")

(defun my/presentation-toggle-fullscreen ()
  "Toggle presentation mode (fullscreen frame + single maximized window + fit slide)."
  (interactive)
  (if my/presentation-saved-window-config
      ;; Previous layout
      (progn
        (set-window-configuration my/presentation-saved-window-config)
        (set-frame-parameter nil 'fullscreen my/presentation-saved-fullscreen)
        (setq my/presentation-saved-window-config nil
              my/presentation-saved-fullscreen nil)
        (dolist (w (window-list))
          (with-selected-window w
            (when (derived-mode-p 'doc-view-mode)
              (doc-view-fit-width-to-window))))
        (message "Presentation mode exited."))
    ;; Presentation mode
    (setq my/presentation-saved-window-config (current-window-configuration)
          my/presentation-saved-fullscreen (frame-parameter nil 'fullscreen))
    (unless (derived-mode-p 'doc-view-mode)
      (let ((win (seq-find (lambda (w)
                             (with-current-buffer (window-buffer w)
                               (derived-mode-p 'doc-view-mode)))
                           (window-list)))
            (pdf (and buffer-file-name
                      (file-name-with-extension buffer-file-name "pdf"))))
        (cond (win (select-window win))
              ((and pdf (file-exists-p pdf))
               (switch-to-buffer (find-file-noselect pdf))
               (unless (derived-mode-p 'doc-view-mode)
                 (doc-view-mode))))))
    (delete-other-windows)
    (set-frame-parameter nil 'fullscreen 'fullscreen)
    (when (derived-mode-p 'doc-view-mode)
      (doc-view-fit-page-to-window))
    (message "Presentation mode ON (Press SPC o b f or 'f' to toggle off).")))

(with-eval-after-load 'doc-view
  (with-eval-after-load 'evil
    (evil-define-key 'normal doc-view-mode-map
      "f" #'my/presentation-toggle-fullscreen)))

(require 'org-keybindings)

(provide 'org-mod)
