;;; Projectile and Perspective keybindings -*- lexical-binding: t; -*-

(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "p"  '(:ignore t :which-key "Projects")
      "po" '(projectile-persp-switch-project :which-key "Open Project")
      "pd" '(my/open-directory-anywhere :which-key "Open Directory (Anywhere)"))))

(provide 'projectile-keys)
