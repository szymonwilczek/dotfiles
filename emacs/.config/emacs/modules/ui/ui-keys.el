;;; UI keybindings and theme picker -*- lexical-binding: t; -*-

;; Font scaling
(global-set-key (kbd "C-=") 'text-scale-increase)
(global-set-key (kbd "C-+") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)
(global-set-key (kbd "C-_") 'text-scale-decrease)
(global-set-key (kbd "C-0") (lambda () (interactive) (text-scale-set 0)))

;; Leader toggles and themes
(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "t"  '(:ignore t :which-key "Toggle")
      "tt" '(my/theme-toggle :which-key "Toggle Theme (Dark/Light)")
      "tp" '(au-themes-select :which-key "Au Themes Picker")
      "tc" '(my/color-picker-at-point :which-key "Color Picker (HSL/RGB)")
      "tn" '(my/toggle-line-numbers-type :which-key "Relative/Absolute Line Numbers")
      "tz" '(my/zen-mode-toggle :which-key "Toggle Zen Mode"))))

(provide 'ui-keys)
