(use-package doom-modeline
  :ensure t
  :init
  (doom-modeline-mode 1)
  :custom
  (doom-modeline-icon t)
  (doom-modeline-vcs-max-length 25)
  (doom-modeline-checker-simple-format nil)
  (doom-modeline-buffer-encoding nil)
  (doom-modeline-height 30))

(provide 'modeline-config)
