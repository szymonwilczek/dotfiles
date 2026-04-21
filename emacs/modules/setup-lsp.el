(use-package markdown-mode :ensure t :mode ("\\.md\\'" . markdown-mode))
(use-package dotenv-mode :ensure t :mode ("\\.env\\..*\\'" "\\.env\\'"))

(setq treesit-font-lock-level 4)
(use-package treesit-auto
  :ensure t
  :custom
  (treesit-auto-install 'prompt)
  :config
  (setq treesit-auto-langs '(c cpp go javascript typescript tsx html css json yaml))
  (global-treesit-auto-mode))

(setq major-mode-remap-alist
  '((c-mode          . c-ts-mode)
     (c++-mode        . c++-ts-mode)
     (c-or-c++-mode   . c-or-c++-ts-mode)
     (typescript-mode . typescript-ts-mode)
     (javascript-mode . js-ts-mode)
     (js-mode         . js-ts-mode)
     (css-mode        . css-ts-mode)
     (json-mode       . json-ts-mode)
     (yaml-mode       . yaml-ts-mode)
     (go-mode         . go-ts-mode)))

(add-to-list 'auto-mode-alist '("\\.ts\\'"  . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'"  . js-ts-mode))
(add-to-list 'auto-mode-alist '("\\.jsx\\'" . tsx-ts-mode))

(defun my/eglot-ensure-deferred ()
  (run-with-idle-timer 0.2 nil #'eglot-ensure))

(use-package eglot
  :ensure nil
  :hook
  ((c-ts-mode c++-ts-mode go-ts-mode js-ts-mode 
     typescript-ts-mode tsx-ts-mode yaml-ts-mode) . my/eglot-ensure-deferred)
  :config
  (fset #'jsonrpc--log-event #'ignore) 
  (setq eglot-events-buffer-size 0)
  (setq eglot-sync-connect nil)

  (add-to-list 'eglot-server-programs
    '((typescript-ts-mode tsx-ts-mode js-ts-mode js-mode typescript-mode) . ("vtsls" "--stdio")))
  (add-to-list 'eglot-ignored-server-capabilities :snippetSupport)

  (setq eglot-autoshutdown nil) 
  (fset #'eglot--message #'ignore)
  (setq jsonrpc-event-hook nil)

  (add-hook 'eglot-managed-mode-hook (lambda () (eldoc-mode -1))))

(with-eval-after-load 'general
  (my-leader-def
    "g"  '(:ignore t :which-key "LSP / Code")
    "gr" '(eglot-rename :which-key "Rename Symbol")
    "gc" '(eglot-code-actions :which-key "Code Actions")
    "gd" '(xref-find-definitions :which-key "Go to Definition")
    "fr" '(xref-find-references :which-key "Find References")
    "fm" '(apheleia-format-buffer :which-key "Format Buffer (Force)")))

(global-eldoc-mode -1)
(setq eldoc-display-functions nil)
(setq eglot-ignored-server-capabilities '(:documentHighlightProvider :hoverProvider))

(provide 'setup-lsp)
