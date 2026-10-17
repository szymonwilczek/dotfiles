;;; Treemacs keybindings and shortcuts -*- lexical-binding: t; -*-

(with-eval-after-load 'evil
  ;; Global Ctrl-n toggle across all Evil states
  ;; (I have strong Neovim muscle memory with this)
  (general-define-key
   :states '(normal motion visual insert)
   "C-n" #'treemacs))

(with-eval-after-load 'treemacs
  ;; Replace stock "o" visit-node prefix map
  (general-define-key
   :keymaps 'treemacs-mode-map
   "o" #'my/show-in-file-manager))


(provide 'treemacs-keys)
