;;; UI keybindings and theme picker -*- lexical-binding: t; -*-

;; Font scaling
(global-set-key (kbd "C-=") 'text-scale-increase)
(global-set-key (kbd "C-+") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)
(global-set-key (kbd "C-_") 'text-scale-decrease)
(global-set-key (kbd "C-0") (lambda () (interactive) (text-scale-set 0)))

;; Leader theme picker
(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "t"  '(:ignore t :which-key "Terminal / Themes")
      "tt" '(ef-themes-select :which-key "Theme Picker")
      "w"  '(:ignore t :which-key "Writings / Zen")
      "wz" '(my/zen-mode-toggle :which-key "Toggle Zen Mode"))))

(provide 'ui-keys)
