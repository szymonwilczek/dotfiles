;;; Tree-sitter and Eglot LSP configuration

;; Tree-sitter Setup
(use-package emacs
  :config
  (setq treesit-font-lock-level 4)

  ;; Remap standard modes to Tree-sitter modes
  (add-to-list 'major-mode-remap-alist '(c-mode          . c-ts-mode))
  (add-to-list 'major-mode-remap-alist '(c++-mode        . c++-ts-mode))
  (add-to-list 'major-mode-remap-alist '(c-or-c++-mode  . c-or-c++-ts-mode))
  (add-to-list 'major-mode-remap-alist '(go-mode         . go-ts-mode))
  (add-to-list 'major-mode-remap-alist '(json-mode       . json-ts-mode))
  (add-to-list 'major-mode-remap-alist '(cmake-mode      . cmake-ts-mode))
  (add-to-list 'major-mode-remap-alist '(sh-mode         . bash-ts-mode))
  (add-to-list 'major-mode-remap-alist '(python-mode     . python-ts-mode))

  ;; File associations
  (add-to-list 'auto-mode-alist '("\\.c\\'"   . c-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.h\\'"   . c-or-c++-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.cpp\\'" . c++-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.hpp\\'" . c++-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.cc\\'"  . c++-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.go\\'"  . go-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.json\\'" . json-ts-mode)))

;; Eglot LSP Client
(use-package eglot
  :ensure nil
  :hook
  ((c-ts-mode         . eglot-ensure)
   (c++-ts-mode       . eglot-ensure)
   (c-or-c++-ts-mode  . eglot-ensure)
   (go-ts-mode        . eglot-ensure)
   (json-ts-mode      . eglot-ensure)
   (cmake-ts-mode     . eglot-ensure)
   (bash-ts-mode      . eglot-ensure))
  :config

  ;; Performance & JSON-RPC optimization
  (fset #'jsonrpc--log-event #'ignore)
  (setq eglot-events-buffer-size 0
        eglot-autoshutdown t
        eglot-sync-connect nil
        eglot-send-changes-idle-time 0.2)
  (add-to-list 'warning-suppress-types '(jsonrpc))
  (add-to-list 'warning-suppress-types '(eglot))

  ;; Server configuration for C/C++ (clangd) and Go (gopls)
  (add-to-list 'eglot-server-programs
               '((c-mode c-ts-mode c++-mode c++-ts-mode c-or-c++-ts-mode)
                 . ("clangd"
                    "--background-index"
                    "--clang-tidy"
                    "--completion-style=detailed"
                    "--header-insertion=iwyu")))
  (add-to-list 'eglot-server-programs
               '((go-mode go-ts-mode) . ("gopls"))))

(require 'lsp-keys)

(provide 'lsp-mod)
