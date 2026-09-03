;;; Tree-sitter and Eglot LSP configuration -*- lexical-binding: t; -*-

(require 'treesit)

;; Tree-sitter Setup
(use-package emacs
  :config
  (setopt treesit-font-lock-level 4
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
  :init
  (defun my/astro-ts-setup ()
    "Setup multi-language embedded parsers and full level-4 syntax highlighting for Astro templates."
    (setq-local tab-width 2
                indent-tabs-mode nil)
    (when (treesit-ready-p 'astro)
      (setq-local treesit-font-lock-level 4)
      (treesit-parser-create 'astro)
      (when (treesit-ready-p 'tsx)
        (treesit-parser-create 'tsx))
      (when (treesit-ready-p 'css)
        (treesit-parser-create 'css))
      (treesit-update-ranges (point-min) (point-max))
      (treesit-font-lock-recompute-features)
      (add-hook 'after-change-functions
                (lambda (beg end _len)
                  (when (and (bound-and-true-p astro-ts-mode)
                             (treesit-parser-list))
                    (treesit-update-ranges beg end)))
                nil t)))
  :hook (astro-ts-mode . my/astro-ts-setup)
  :config
  (defun astro-ts-mode--prefix-font-lock-features (prefix settings)
    "Prefix with PREFIX the font lock features in SETTINGS, preserving all elements."
    (mapcar (lambda (setting)
              (let ((copy (copy-sequence setting)))
                (setf (nth 2 copy) (intern (format "%s-%s" prefix (nth 2 setting))))
                copy))
            settings))

  (setq astro-ts-mode--font-lock-settings
        (append
         (astro-ts-mode--prefix-font-lock-features
          "tsx"
          (typescript-ts-mode--font-lock-settings 'tsx))
         (astro-ts-mode--prefix-font-lock-features "css" css--treesit-settings)
         (treesit-font-lock-rules
          :language 'astro
          :feature 'astro-comment
          '((comment) @font-lock-comment-face
            (frontmatter ("---") @font-lock-comment-face))

          :language 'astro
          :feature 'astro-keyword
          '("doctype" @font-lock-keyword-face)

          :language 'astro
          :feature 'astro-definition
          '((tag_name) @font-lock-function-name-face)

          :language 'astro
          :feature 'astro-string
          '((quoted_attribute_value) @font-lock-string-face
            (attribute_name) @font-lock-constant-face)

          :language 'astro
          :feature 'astro-bracket
          '((["<" ">" "</" "/>" "{" "}"]) @font-lock-bracket-face))))

  (setq astro-ts-mode--range-settings
        (treesit-range-rules
         :embed 'tsx
         :host 'astro
         '((frontmatter (frontmatter_js_block) @cap)
           (attribute_interpolation (attribute_js_expr) @cap)
           (html_interpolation (permissible_text) @cap)
           (script_element (raw_text) @cap))

         :embed 'css
         :host 'astro
         '((style_element (raw_text) @cap)))))

(use-package python
  :ensure nil
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
   (php-ts-mode       . eglot-ensure)
   (astro-ts-mode     . eglot-ensure)
   (json-ts-mode      . eglot-ensure)
   (sh-mode           . eglot-ensure)
   (bash-ts-mode      . eglot-ensure)
   (python-ts-mode    . eglot-ensure))
  :config

  ;; Performance & JSON-RPC optimization
  (fset #'jsonrpc--log-event #'ignore)
  (setq eglot-events-buffer-size 0
        eglot-autoshutdown t
        eglot-sync-connect nil
        eglot-send-changes-idle-time 0.2)
  (add-to-list 'warning-suppress-types '(jsonrpc))
  (add-to-list 'warning-suppress-types '(eglot))

  ;; Inlay Hints typography
  (set-face-attribute 'eglot-inlay-hint-face nil
                      :inherit 'shadow
                      :slant 'italic
                      :height 0.85)

  ;; Server configurations
  (defun my/eglot-astro-contact (_interactive)
    "Resolve typescript.tsdk path for astro-ls language server."
    (let* ((proj-dir (or (and (fboundp 'projectile-project-root) (projectile-project-root))
                         (and (fboundp 'project-root) (project-current) (project-root (project-current)))
                         default-directory))
           (local-tsdk (expand-file-name "node_modules/typescript/lib" proj-dir))
           (global-tsdk (or (and (file-directory-p (expand-file-name "~/.npm-global/lib/node_modules/typescript/lib"))
                                 (expand-file-name "~/.npm-global/lib/node_modules/typescript/lib"))
                            (and (file-directory-p "/usr/local/lib/node_modules/typescript/lib")
                                 "/usr/local/lib/node_modules/typescript/lib")
                            (and (file-directory-p "/usr/lib/node_modules/typescript/lib")
                                 "/usr/lib/node_modules/typescript/lib")))
           (tsdk (if (file-directory-p local-tsdk)
                     local-tsdk
                   (or global-tsdk "node_modules/typescript/lib"))))
      (list "astro-ls" "--stdio"
            :initializationOptions
            (list :typescript (list :tsdk tsdk)))))

  (add-to-list 'eglot-server-programs
               '((c-mode c-ts-mode)
                 . ("clangd"
                    "--background-index"
                    "--clang-tidy"
                    "--completion-style=detailed"
                    "--header-insertion=iwyu")))
  (add-to-list 'eglot-server-programs
               '(php-ts-mode . ("intelephense" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(astro-ts-mode . my/eglot-astro-contact))
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) . ("ruff" "server"))))

(require 'lsp-keys)

(provide 'lsp-mod)
