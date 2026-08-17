;; ========================
;; AUCTeX
;; ========================
(use-package tex
  :ensure auctex
  :defer t
  :hook ((LaTeX-mode . TeX-source-correlate-mode)
         (LaTeX-mode . TeX-PDF-mode)
         (LaTeX-mode . LaTeX-math-mode)
         (LaTeX-mode . flyspell-mode)
         (LaTeX-mode . visual-line-mode)
         (LaTeX-mode . company-mode)
         (LaTeX-mode . reftex-mode))
  :config
  (setq TeX-auto-save t
        TeX-parse-self t
        TeX-save-query nil)

  (setq-default TeX-master nil)
  (setq TeX-source-correlate-method 'synctex)
  (setq TeX-command-default "LatexMk")

  (add-to-list 'TeX-view-program-list
    '("Zathura"
      ("zathura --synctex-forward \"%n:0:%b\" -x \"emacsclient --no-wait +%%{line} %%{input}\" %o")
      "zathura"))
  (setq TeX-view-program-selection
    '(((output-dvi style-pstricks) "dvips and gv")
       (output-dvi "xdvi")
       (output-pdf "Zathura")
       (output-html "xdg-open")))

  (setq LaTeX-electric-left-right-brace t
        TeX-electric-sub-and-superscript t)

  (setq font-latex-fontify-script t
        font-latex-fontify-sectioning 'color)

  (defun my/latex-view-pdf ()
    "Otwórz PDF w Zathura, ale tylko jeśli plik istnieje."
    (interactive)
    (let* ((master (TeX-master-file))
           (pdf (concat (file-name-sans-extension (expand-file-name master)) ".pdf")))
      (if (file-exists-p pdf)
          (start-process "zathura" nil "zathura"
                         "--synctex-forward"
                         (format "%d:0:%s" (line-number-at-pos) (buffer-file-name))
                         "-x" "emacsclient --no-wait +%{line} %{input}"
                         pdf)
        (message "⚠️ Brak PDF: %s — najpierw skompiluj (SPC l c)" pdf)))))


;; ========================
;; LATEXMK
;; ========================
(use-package auctex-latexmk
  :ensure t
  :after tex
  :config
  (auctex-latexmk-setup)
  (setq auctex-latexmk-inherit-TeX-PDF-mode t))


;; ========================
;; REFTEX
;; ========================
(use-package reftex
  :ensure nil
  :defer t
  :config
  (setq reftex-plug-into-AUCTeX t)
  (setq reftex-default-bibliography nil)

  (setq reftex-label-alist
        '(("equation" ?e "eq:" "~\\eqref{%s}" t ("equation" "eq.") -1)
          ("figure"   ?f "fig:" "~\\ref{%s}" t ("figure" "fig.") -1)
          ("table"    ?t "tab:" "~\\ref{%s}" t ("table" "tab.") -1)
          ("section"  ?s "sec:" "~\\ref{%s}" t ("section" "sec.") -1))))


;; ========================
;; COMPANY-AUCTEX
;; ========================
(use-package company-auctex
  :ensure t
  :after (tex company)
  :config
  (company-auctex-init))

(use-package company-reftex
  :ensure t
  :after (tex company reftex)
  :config
  (add-hook 'LaTeX-mode-hook
    (lambda ()
      (setq-local company-backends
        (append '(company-reftex-citations company-reftex-labels)
                company-backends)))))


;; ========================
;; CITAR
;; ========================
(use-package citar
  :ensure t
  :defer t
  :config
  (setq org-cite-global-bibliography '("~/orgfiles/references.bib"))
  (setq citar-bibliography org-cite-global-bibliography)
  (setq org-cite-insert-processor 'citar)
  (setq org-cite-follow-processor 'citar)
  (setq org-cite-preview-processor 'citar))


;; ========================
;; Eksport LaTeX z Org-Mode
;; ========================
(use-package ox-latex
  :ensure nil
  :after org
  :config
  (setq org-latex-pdf-process
    '("latexmk -f -pdf -interaction=nonstopmode -output-directory=%o %f"))

  (setcdr (assoc "\\.pdf\\'" org-file-apps) "zathura %s")

  (defun my/color-to-hex-raw (color-str default-str)
    (let ((color (or color-str default-str)))
      (if (string-prefix-p "#" color)
        (substring color 1)
        (let ((rgb (color-name-to-rgb color)))
          (if rgb
            (apply #'format "%02x%02x%02x" 
              (mapcar (lambda (x) (round (* x 255))) rgb))
            (substring default-str 1))))))

  (defun my/org-latex-theme-colors-exporter (backend)
    "Inject active Emacs theme colors and Beamer customizations into LaTeX headers before exporting."
    (when (org-export-derived-backend-p backend 'latex)
      (let* ((bg (face-background 'default nil t))
              (fg (face-foreground 'default nil t))
              (primary (face-foreground 'font-lock-keyword-face nil t))
              (secondary (face-foreground 'font-lock-function-name-face nil t))
              (comment (face-foreground 'font-lock-comment-face nil t))
              (bg-hex (my/color-to-hex-raw bg "#ffffff"))
              (fg-hex (my/color-to-hex-raw fg "#000000"))
              (primary-hex (my/color-to-hex-raw primary "#0000ee"))
              (secondary-hex (my/color-to-hex-raw secondary "#006600"))
              (comment-hex (my/color-to-hex-raw comment "#888888"))
              (latex-header (format "
\\definecolor{themebg}{HTML}{%s}
\\definecolor{themefg}{HTML}{%s}
\\definecolor{themeprimary}{HTML}{%s}
\\definecolor{themesecondary}{HTML}{%s}
\\definecolor{themecomment}{HTML}{%s}

\\mode<presentation>{
  \\setbeamercolor{background canvas}{bg=themebg}
  \\setbeamercolor{normal text}{fg=themefg}
  \\setbeamercolor{structure}{fg=themeprimary}
  \\setbeamercolor{local structure}{fg=themesecondary}
  \\setbeamercolor{alerted text}{fg=themesecondary}
  \\setbeamercolor{title}{fg=themeprimary}
  \\setbeamercolor{subtitle}{fg=themecomment}
  \\setbeamercolor{author}{fg=themefg}
  \\setbeamercolor{date}{fg=themecomment}
  \\setbeamercolor{frametitle}{fg=themeprimary}
  \\setbeamertemplate{navigation symbols}{}
  \\setbeamertemplate{frametitle}[default][left]
}
"
                              bg-hex
                              fg-hex
                              primary-hex
                              secondary-hex
                              comment-hex)))
        (goto-char (point-min))
        (insert "#+LATEX_HEADER: " (replace-regexp-in-string "\n" "\n#+LATEX_HEADER: " latex-header) "\n"))))

  (add-hook 'org-export-before-processing-hook #'my/org-latex-theme-colors-exporter))

(use-package ox-beamer
  :ensure nil
  :after org)


(with-eval-after-load 'general
  (with-eval-after-load 'evil
    (general-define-key
     :states 'normal
     :keymaps 'LaTeX-mode-map
     :prefix "SPC"
     "l"  '(:ignore t :which-key "LaTeX")
     "lc" '(TeX-command-master :which-key "Kompiluj")
     "lv" '(my/latex-view-pdf :which-key "Podgląd PDF")
     "le" '(TeX-next-error :which-key "Następny błąd")
     "ll" '(TeX-recenter-output-buffer :which-key "Log kompilacji")
     "lb" '(reftex-citation :which-key "Wstaw cytowanie")
     "lr" '(reftex-reference :which-key "Wstaw referencję")
     "lm" '(TeX-insert-macro :which-key "Wstaw makro")
     "ls" '(LaTeX-section :which-key "Wstaw sekcję")
     "ln" '(LaTeX-environment :which-key "Wstaw środowisko")
     "lf" '(LaTeX-fill-buffer :which-key "Formatuj bufor")
     "lw" '(TeX-command-run-all :which-key "Kompiluj i podgląd"))))


(provide 'setup-latex)
