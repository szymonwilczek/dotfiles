;;; Projectile and Perspective keybindings

(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "p"  '(:ignore t :which-key "Projects")
      "po" '(projectile-persp-switch-project :which-key "Open Project"))))

(provide 'projectile-keys)
