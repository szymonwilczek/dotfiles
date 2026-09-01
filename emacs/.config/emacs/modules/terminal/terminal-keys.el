;;; Ghostel terminal keybindings -*- lexical-binding: t; -*-

;; Global toggle (M-f) across Emacs
(global-set-key (kbd "M-f") #'my/ghostel-toggle-bottom)

;; Evil states & Leader mappings
(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "tb" '(my/ghostel-open-full-buffer :which-key "Terminal Full Buffer"))))

;; In-terminal toggle back
(with-eval-after-load 'ghostel
  (define-key ghostel-mode-map (kbd "M-f") #'my/ghostel-toggle-bottom)
  (define-key ghostel-semi-char-mode-map (kbd "M-f") #'my/ghostel-toggle-bottom))

(with-eval-after-load 'evil-ghostel
  (evil-define-key* '(insert normal visual motion emacs) evil-ghostel-mode-map
    (kbd "M-f") #'my/ghostel-toggle-bottom))

(provide 'terminal-keys)
