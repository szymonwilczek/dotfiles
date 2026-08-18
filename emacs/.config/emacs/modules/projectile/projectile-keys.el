;;; Projectile keybindings

(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "p"  '(:ignore t :which-key "Projects")
      "pp" '(projectile-switch-project :which-key "Switch Project")
      "po" '(projectile-switch-open-project :which-key "Open Project"))))

(provide 'projectile-keys)
