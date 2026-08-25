;;; -*- lexical-binding: t; -*-
(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "TAB") #'bufferline-next-tab)
  (define-key evil-normal-state-map (kbd "<tab>") #'bufferline-next-tab)
  (define-key evil-normal-state-map (kbd "<backtab>") #'bufferline-prev-tab)
  (define-key evil-normal-state-map (kbd "S-TAB") #'bufferline-prev-tab)
  (define-key evil-normal-state-map (kbd "<S-tab>") #'bufferline-prev-tab))

(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "b"  '(:ignore t :which-key "Buffers")
      "bp" '(bufferline-pick :which-key "Pick Buffer")
      "bd" '(bufferline-pick-close :which-key "Pick Close Buffer")
      "bc" '(bufferline-pick-close :which-key "Pick Close Buffer")
      "bP" '(bufferline-toggle-pin :which-key "Toggle Pin Buffer"))))

(provide 'tabs-keys)
