;;; Keybindings for LaTeX and In-Emacs PDF Viewer -*- lexical-binding: t; -*-

(defun my/setup-latex-keys ()
  "Define LaTeX keybindings under SPC l (LaTeX / Lazygit)."
  (when (fboundp 'general-define-key)
    (general-define-key
     :states '(normal visual motion)
     :keymaps '(LaTeX-mode-map latex-mode-map TeX-mode-map tex-mode-map)
     :prefix "SPC"
     "l"  '(:ignore t :which-key "LaTeX / Lazygit")
     "lg" '(my/open-lazygit :which-key "Lazygit")
     "la" '(my/latex-compile-and-view :which-key "Compile & View in Split")
     "lc" '(my/latex-compile :which-key "Compile (LatexMk Async)")
     "lv" '(my/latex-view-pdf :which-key "View PDF in Split")
     "le" '(my/latex-next-error :which-key "Next Compilation Error")
     "ll" '(my/latex-show-log :which-key "Toggle Compilation Log")
     "ln" '(LaTeX-environment :which-key "Insert Environment"))))

(with-eval-after-load 'tex (my/setup-latex-keys))
(with-eval-after-load 'latex (my/setup-latex-keys))
(add-hook 'LaTeX-mode-hook #'my/setup-latex-keys)
(add-hook 'latex-mode-hook #'my/setup-latex-keys)


(with-eval-after-load 'doc-view
  (with-eval-after-load 'evil
    (evil-define-key 'normal doc-view-mode-map
      "j"     #'doc-view-next-line-or-next-page
      "k"     #'doc-view-previous-line-or-previous-page
      "J"     #'doc-view-next-page
      "K"     #'doc-view-previous-page
      "d"     #'doc-view-scroll-up-or-next-page
      "u"     #'doc-view-scroll-down-or-previous-page
      "+"     #'doc-view-enlarge
      "="     #'doc-view-enlarge
      "-"     #'doc-view-shrink
      "r"     #'doc-view-revert-buffer
      "q"     #'my/latex-quit-pdf)))

(provide 'latex-keys)
