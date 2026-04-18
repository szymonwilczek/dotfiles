(use-package which-key
  :ensure nil
  :config
  (which-key-mode)
  :custom
  (which-key-idle-delay 0.5)
  (which-key-side-window-location 'bottom)
  (which-key-sort-order 'which-key-key-order-alpha))

(provide 'whichkey-config)
