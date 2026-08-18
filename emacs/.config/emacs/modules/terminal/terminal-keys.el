;;; Ghostel terminal keybindings

;; Global toggle (M-f) across Emacs
(global-set-key (kbd "M-f") #'my/ghostel-toggle-bottom)

;; Evil states & Leader mappings
(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "o"  '(:ignore t :which-key "Open/Terminal")
      "ot" '(my/ghostel-toggle-bottom :which-key "Toggle Terminal")
      "op" '(ghostel-project :which-key "Terminal in Project Root"))))

;; In-terminal toggle back
(with-eval-after-load 'ghostel
  (define-key ghostel-semi-char-mode-map (kbd "M-f") #'my/ghostel-toggle-bottom))

(provide 'terminal-keys)
