;;; Tree-sitter and Eglot LSP configuration -*- lexical-binding: t; -*-

(require 'treesit)

;; Tree-sitter Setup
(use-package emacs
  :config
  (setq treesit-font-lock-level 4
        treesit-auto-install-grammar 'always
        treesit-enabled-modes t)

  (add-to-list 'treesit-language-source-alist
               '(astro "https://github.com/virchau13/tree-sitter-astro"))

  (add-to-list 'auto-mode-alist '("\\.astro\\'" . astro-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.\\(?:s\\|S\\|asm\\|inc\\)\\'" . asm-mode)))

;; Code folding via Hideshow
(use-package hideshow
  :ensure nil
  :hook (prog-mode . hs-minor-mode))

;; Native Semantic Highlighting for ELisp
(setq elisp-fontify-semantically t)
(add-hook 'emacs-lisp-mode-hook #'cursor-sensor-mode)

;; Enhanced ElDoc documentation
(setq eldoc-help-at-pt t
      eldoc-echo-area-use-multiline-p nil)

(use-package make-mode
  :ensure nil
  :mode (("Makefile\\'" . makefile-gmake-mode)
         ("makefile\\'" . makefile-gmake-mode)
         ("GNUmakefile\\'" . makefile-gmake-mode)
         ("\\.mk\\'"    . makefile-gmake-mode))
  :hook (makefile-mode . (lambda ()
                           (setq-local indent-tabs-mode t)
                           (setq-local tab-width 8))))

(use-package php-ts-mode
  :ensure nil
  :mode "\\.\\(?:php\\|phtml\\|inc\\)\\'"
  :hook (php-ts-mode . (lambda ()
                         (setq-local tab-width 4)
                         (setq-local c-basic-offset 4)
                         (setq-local indent-tabs-mode nil))))

(use-package asm-mode
  :ensure nil
  :mode "\\.\\(?:s\\|S\\|asm\\|inc\\)\\'"
  :hook (asm-mode . (lambda ()
                      (setq-local tab-width 8)
                      (setq-local indent-tabs-mode nil)
                      (setq-local comment-start ";")
                      (setq-local comment-end ""))))

(use-package astro-ts-mode
  :ensure nil
  :mode "\\.astro\\'"
  :hook (astro-ts-mode . (lambda ()
                           (setq-local tab-width 2)
                           (setq-local indent-tabs-mode nil))))

(use-package python
  :ensure nil
  :mode "\\.py\\'"
  :custom
  (python-indent-guess-indent-offset nil)
  (python-indent-guess-indent-offset-verbose nil)
  (python-indent-offset 4))

;; Eglot LSP Client
(use-package eglot
  :ensure nil
  :hook
  ((c-mode            . eglot-ensure)
   (c-ts-mode         . eglot-ensure)
   (go-mode           . eglot-ensure)
   (go-ts-mode        . eglot-ensure)
   (go-mod-ts-mode    . eglot-ensure)
   (go-work-ts-mode   . eglot-ensure)
   (php-mode          . eglot-ensure)
   (php-ts-mode       . eglot-ensure)
   (astro-mode        . eglot-ensure)
   (astro-ts-mode     . eglot-ensure)
   (lua-mode          . eglot-ensure)
   (lua-ts-mode       . eglot-ensure)
   (json-mode         . eglot-ensure)
   (json-ts-mode      . eglot-ensure)
   (sh-mode           . eglot-ensure)
   (bash-ts-mode      . eglot-ensure)
   (python-mode       . eglot-ensure)
   (python-ts-mode    . eglot-ensure))
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

  ;; Server configurations
  (add-to-list 'eglot-server-programs
               '((c-mode c-ts-mode)
                 . ("clangd"
                    "--background-index"
                    "--clang-tidy"
                    "--completion-style=detailed"
                    "--header-insertion=iwyu")))
  (add-to-list 'eglot-server-programs
               '((php-mode php-ts-mode) . ("intelephense" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((astro-ts-mode astro-mode) . ("astro-ls" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) . ("ruff" "server"))))

(require 'lsp-keys)

(provide 'lsp-mod)
