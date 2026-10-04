;;; -*- lexical-binding: t; -*-
(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    "[b" #'bufferline-prev-tab
    "]b" #'bufferline-next-tab))

(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "b"  '(:ignore t :which-key "Buffers")
      "bb" '(consult-buffer :which-key "Switch Buffer")
      "bp" '(bufferline-pick :which-key "Pick Buffer")
      "bd" '(bufferline-pick-close :which-key "Pick Close Buffer")
      "bP" '(bufferline-toggle-pin :which-key "Toggle Pin Buffer"))))

(provide 'tabs-keys)
