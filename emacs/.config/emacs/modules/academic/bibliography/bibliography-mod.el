;;; Academic bibliography & citation management -*- lexical-binding: t; -*-

(use-package citar
  :ensure t
  :custom
  (citar-bibliography (seq-filter #'file-exists-p
                                  (list (expand-file-name "~/references/references.bib")
                                        (expand-file-name "~/references.bib")
                                        "references.bib")))
  (citar-library-paths (list (expand-file-name "~/Zotero/storage")
                             (expand-file-name "~/Dokumenty/Papers")))
  (citar-notes-paths (list (expand-file-name "~/Dokumenty/Notes/Literature")))
  (citar-latex-prompt-for-cite-style nil)
  (citar-latex-default-cite-style "cite")
  :hook ((LaTeX-mode . citar-capf-setup)
         (latex-mode . citar-capf-setup)
         (org-mode . citar-capf-setup))
  :config

  ;; Icon indicators
  (when (fboundp 'nerd-icons-faicon)
    (setq citar-symbols
          `((file ,(nerd-icons-faicon "nf-fa-file_pdf_o" :face 'nerd-icons-red) . " ")
            (note ,(nerd-icons-faicon "nf-fa-file_text_o" :face 'nerd-icons-blue) . " ")
            (link ,(nerd-icons-faicon "nf-fa-link" :face 'nerd-icons-orange) . " ")))
    (setq citar-symbol-separator "  ")))

(use-package citar-org
  :ensure nil
  :after (citar org))


(require 'bibliography-keys)

(provide 'bibliography-mod)
