(use-package apheleia
  :ensure t
  :config
  (setf (alist-get 'prettier apheleia-formatters)
    '("prettier" "--tab-width" "2" "--stdin-filepath" filepath))
  (setf (alist-get 'typescript-ts-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'tsx-ts-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'js-ts-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'emacs-lisp-mode apheleia-mode-alist) 'lisp-indent)
  (setf (alist-get 'lisp-mode apheleia-mode-alist) 'lisp-indent)
  (setf (alist-get 'common-lisp-mode apheleia-mode-alist) 'lisp-indent)
  )

(with-eval-after-load 'general
  (my-leader-def
    "f m" '(apheleia-format-buffer :which-key "Format Buffer")))


(setq-default typescript-ts-mode-indent-offset 2)
(setq-default js-indent-level 2)
(setq-default lisp-indent-offset 2)

(provide 'setup-format)
