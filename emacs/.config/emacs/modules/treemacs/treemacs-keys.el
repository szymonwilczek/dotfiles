;;; Treemacs keybindings and shortcuts -*- lexical-binding: t; -*-

(with-eval-after-load 'evil
  ;; Global Ctrl-n toggle across all Evil states
  ;; (I have strong Neovim muscle memory with this)
  (general-define-key
    :states '(normal motion visual insert)
    "C-n" #'treemacs))


(provide 'treemacs-keys)
