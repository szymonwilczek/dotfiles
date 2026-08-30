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

  (custom-set-faces
   '(org-document-title ((t (:inherit default :weight bold :height 1.4 :underline nil))))
   '(org-level-1 ((t (:inherit default :weight bold :height 1.25))))
   '(org-level-2 ((t (:inherit default :weight bold :height 1.15))))
   '(org-level-3 ((t (:inherit default :weight bold :height 1.08))))
   '(org-level-4 ((t (:inherit default :weight semi-bold :height 1.02))))
   '(org-block-begin-line ((t (:inherit font-lock-comment-face :slant italic))))
   '(org-block-end-line ((t (:inherit font-lock-comment-face :slant italic)))))

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

(use-package org-agenda
  :ensure nil
  :after org
  :custom
  (org-agenda-span 'week)
  (org-agenda-start-on-weekday 1) ; Monday
  (org-agenda-show-all-dates t)
  (org-agenda-time-leading-zero t)
  (org-agenda-timegrid-use-ampm nil)
  (org-agenda-current-time-string "⭠ teraz")
  (org-agenda-use-time-grid t)
  (org-agenda-files (list (expand-file-name "~/Dokumenty/writings/plan-polsl.org")))
  :config
  (setq org-agenda-time-grid
        '((daily today require-timed)
          (800 1000 1200 1400 1600 1800 2000)
          "......" "----------------")))

(use-package plan-polsl
  :vc (:url "https://github.com/szymonwilczek/plan-polsl.el" :branch "main")
  :custom
  (plan-polsl-id "343266256")
  (plan-polsl-type 0)
  (plan-polsl-target-file (expand-file-name "~/Dokumenty/writings/plan-polsl.org"))
  (plan-polsl-auto-add-to-agenda t))

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

(defun my/org-toggle-emphasis-markers ()
  "Toggle visibility of Org emphasis markers (* / _ = ~)."
  (interactive)
  (setq org-hide-emphasis-markers (not org-hide-emphasis-markers))
  (font-lock-flush)
  (message "Org emphasis markers: %s" (if org-hide-emphasis-markers "hidden" "visible")))

(defun my/org-toggle-latex-preview ()
  "Toggle LaTeX math preview for equation at point or entire buffer."
  (interactive)
  (if (org-inside-LaTeX-fragment-p)
      (org-latex-preview)
    (org-latex-preview '(16))))

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
        (when (derived-mode-p 'doc-view-mode)
          (doc-view-fit-width-to-window))
        (message "Presentation mode exited."))
    ;; Presentation mode
    (setq my/presentation-saved-window-config (current-window-configuration)
          my/presentation-saved-fullscreen (frame-parameter nil 'fullscreen))
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
