;;; LSP and diagnostic keybindings

(with-eval-after-load 'evil

  ;; Definition & Reference jumps
  (evil-define-key 'normal 'global
    "gd" 'xref-find-definitions
    "gD" 'eglot-find-declaration
    "gi" 'eglot-find-implementation
    "gy" 'eglot-find-typeDefinition
    "gr" 'xref-find-references
    "K"  'eldoc
    "[d" 'flymake-goto-prev-error
    "]d" 'flymake-goto-next-error
    (kbd "C-w d") 'flymake-show-diagnostic))

;; Leader code actions & refactoring
(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def

      ;; Code & Refactor
      "c"  '(:ignore t :which-key "Code")
      "ca" '(eglot-code-actions :which-key "Code Action")
      "cr" '(eglot-rename :which-key "Rename Symbol")
      "cf" '(eglot-format :which-key "Format Buffer")
      "rn" '(eglot-rename :which-key "Rename Symbol")

      ;; Format shortcut
      "fm" '(eglot-format :which-key "Format Buffer")

      ;; Diagnostics
      "dq" '(flymake-show-buffer-diagnostics :which-key "Diagnostics List"))))

(provide 'lsp-keys)
