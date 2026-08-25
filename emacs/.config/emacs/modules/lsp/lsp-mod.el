;;; Tree-sitter and Eglot LSP configuration -*- lexical-binding: t; -*-

;; Tree-sitter Setup
(use-package emacs
  :config
  (setq treesit-font-lock-level 4
        treesit-auto-install-grammar 'always)

  ;; Enable all Tree-sitter major modes
  (setq treesit-enabled-modes t)

  ;; File associations
  (add-to-list 'auto-mode-alist '("\\.c\\'"                . c-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.h\\'"                . c-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.cpp\\'"              . c++-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.hpp\\'"              . c++-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.cc\\'"               . c++-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.go\\'"               . go-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.json\\'"             . json-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.cmake\\'"            . cmake-ts-mode))
  (add-to-list 'auto-mode-alist '("CMakeLists\\.txt\\'"    . cmake-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.\\(?:s\\|S\\|asm\\|inc\\)\\'" . asm-mode))
  (add-to-list 'auto-mode-alist '("\\.\\(?:sh\\|bash\\|zsh\\)\\'"   . bash-ts-mode)))

;; Code folding via Hideshow
(use-package hideshow
  :ensure nil
  :hook (prog-mode . hs-minor-mode))

;; Enhanced ElDoc documentation
(setq eldoc-help-at-pt t
      eldoc-echo-area-use-multiline-p nil)

(use-package asm-mode
  :ensure nil
  :hook (asm-mode . (lambda ()
                      (setq-local tab-width 8)
                      (setq-local indent-tabs-mode nil)
                      (setq-local comment-start ";")
                      (setq-local comment-end ""))))

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
        eglot-send-changes-idle-time 0.05)
  (add-to-list 'warning-suppress-types '(jsonrpc))
  (add-to-list 'warning-suppress-types '(eglot))

  ;; Inlay Hints typography
  (set-face-attribute 'eglot-inlay-hint-face nil
                      :inherit 'shadow
                      :slant 'italic
                      :height 0.85)

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
