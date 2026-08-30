;;; Keybindings for Writings -*- lexical-binding: t; -*-

(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "w"  '(:ignore t :which-key "Writings & Poetry")
      "wz" '(my/writings-zen-toggle :which-key "Toggle Zen Mode")
      "wn" '(my/writings-new :which-key "New Poem / Meditation")
      "wf" '(my/writings-find :which-key "Find Writing / Poem"))))

(provide 'writings-keys)
