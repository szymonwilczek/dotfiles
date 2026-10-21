;;; -*- lexical-binding: t; -*-
(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    "[b" #'bufferline-prev-tab
    "]b" #'bufferline-next-tab
    "[B" #'bufferline-move-tab-to-window-left
    "]B" #'bufferline-move-tab-to-window-right))

(with-eval-after-load 'evil-collection-unimpaired
  (evil-define-key 'normal evil-collection-unimpaired-mode-map
    "[b" #'bufferline-prev-tab
    "]b" #'bufferline-next-tab
    "[B" #'bufferline-move-tab-to-window-left
    "]B" #'bufferline-move-tab-to-window-right))

(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "b"  '(:ignore t :which-key "Buffers")
      "bb" '(consult-buffer :which-key "Switch Buffer")
      "bp" '(bufferline-pick :which-key "Pick Buffer")
      "bd" '(bufferline-pick-close :which-key "Pick Close Buffer")
      "bP" '(bufferline-toggle-pin :which-key "Toggle Pin Buffer")
      "bs" '(bufferline-swap-tab :which-key "Swap Buffer")
      "<"  '(bufferline-move-tab-left :which-key "Move Buffer Left")
      ">"  '(bufferline-move-tab-right :which-key "Move Buffer Right"))))

(provide 'tabs-keys)
