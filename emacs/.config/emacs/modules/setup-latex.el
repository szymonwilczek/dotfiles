(use-package tex
  :ensure auctex
  :defer t
  :config
  (setq TeX-auto-save t)
  (setq TeX-parse-self t)
  (setq-default TeX-master nil)
  (setq TeX-source-correlate-mode t)
  (setq TeX-source-correlate-start-server t)

  (add-to-list 'TeX-view-program-list
    '("Zathura" "zathura -x \"emacsclient --no-wait +%%l %%f\" %o"))
  (setq TeX-view-program-selection
    '(((output-dvi style-pstricks) "dvips and gv")
       (output-dvi "xdvi")
       (output-pdf "Zathura")
       (output-html "xdg-open"))))

(use-package ox-latex
  :ensure nil
  :after org
  :config
  (setq org-latex-pdf-process
    '("latexmk -f -pdf -interaction=nonstopmode -output-directory=%o %f"))

  (setcdr (assoc "\\.pdf\\'" org-file-apps) "zathura %s")

  ;; helper to safely convert color names or hex values to raw hex digits
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

(use-package citar
  :ensure t
  :after org
  :config
  (setq org-cite-global-bibliography '("~/orgfiles/references.bib"))
  (setq citar-bibliography org-cite-global-bibliography)
  (setq org-cite-insert-processor 'citar)
  (setq org-cite-follow-processor 'citar)
  (setq org-cite-preview-processor 'citar)
  (with-eval-after-load 'general
    (my-leader-def
      "oC" '(citar-insert-citation :which-key "Wstaw cytowanie (Citation)"))))

(provide 'setup-latex)
