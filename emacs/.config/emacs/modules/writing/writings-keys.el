;;; Keybindings for Writings -*- lexical-binding: t; -*-

(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "w"  '(:ignore t :which-key "Writings")
      "wz" '(my/writings-zen-toggle :which-key "Toggle Zen Mode"))))

(provide 'writings-keys)
