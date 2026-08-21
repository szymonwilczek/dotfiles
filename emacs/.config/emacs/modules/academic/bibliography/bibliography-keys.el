;;; Keybindings for Citar in LaTeX and Org -*- lexical-binding: t; -*-

(defun my/setup-bibliography-keys ()
  "Define Citar citation keybindings for LaTeX and Org modes."
  (when (fboundp 'general-define-key)
    ;; LaTeX
    (general-define-key
     :states '(normal visual motion)
     :keymaps '(LaTeX-mode-map latex-mode-map TeX-mode-map tex-mode-map)
     :prefix "SPC"
     "lc" '(citar-insert-citation :which-key "Insert Citation (\\cite)")
     "lo" '(citar-open :which-key "Open Bibliography Paper / PDF"))

    ;; Org Mode
    (general-define-key
     :states '(normal visual motion)
     :keymaps 'org-mode-map
     :prefix "SPC"
     "oc" '(citar-insert-citation :which-key "Insert Citation ([cite:@])")
     "oo" '(citar-open :which-key "Open Bibliography Paper / PDF"))))

(with-eval-after-load 'citar (my/setup-bibliography-keys))
(with-eval-after-load 'tex (my/setup-bibliography-keys))
(with-eval-after-load 'latex (my/setup-bibliography-keys))
(with-eval-after-load 'org (my/setup-bibliography-keys))
(add-hook 'LaTeX-mode-hook #'my/setup-bibliography-keys)
(add-hook 'latex-mode-hook #'my/setup-bibliography-keys)
(add-hook 'org-mode-hook #'my/setup-bibliography-keys)

(provide 'bibliography-keys)
