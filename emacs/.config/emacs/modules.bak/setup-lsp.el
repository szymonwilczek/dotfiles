(use-package emacs
  :config
  (setq treesit-font-lock-level 4)

  (setq treesit-language-source-alist
        '((javascript . ("https://github.com/tree-sitter/tree-sitter-javascript" "master" "src"))
          (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src"))
          (tsx        . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src"))
          (css        . ("https://github.com/tree-sitter/tree-sitter-css" "master" "src"))
          (json       . ("https://github.com/tree-sitter/tree-sitter-json" "master" "src"))
          (go         . ("https://github.com/tree-sitter/tree-sitter-go" "master" "src"))
          (cmake      . ("https://github.com/uyha/tree-sitter-cmake" "master" "src"))
          (make       . ("https://github.com/alemuller/tree-sitter-make" "main" "src"))
          (c          . ("https://github.com/tree-sitter/tree-sitter-c" "master" "src"))
          (cpp        . ("https://github.com/tree-sitter/tree-sitter-cpp" "master" "src"))
          (c-sharp    . ("https://github.com/tree-sitter/tree-sitter-c-sharp" "master" "src"))))

  (add-to-list 'major-mode-remap-alist '(js-mode . js-ts-mode))
  (add-to-list 'major-mode-remap-alist '(js2-mode . js-ts-mode))
  (add-to-list 'major-mode-remap-alist '(typescript-mode . typescript-ts-mode))
  (add-to-list 'major-mode-remap-alist '(json-mode . json-ts-mode))
  (add-to-list 'major-mode-remap-alist '(css-mode . css-ts-mode))
  (add-to-list 'major-mode-remap-alist '(go-mode . go-ts-mode))
  (add-to-list 'major-mode-remap-alist '(cmake-mode . cmake-ts-mode))
  (add-to-list 'major-mode-remap-alist '(c-mode . c-ts-mode))
  (add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode))
  (add-to-list 'major-mode-remap-alist '(c-or-c++-mode . c-or-c++-ts-mode))
  (add-to-list 'major-mode-remap-alist '(csharp-mode . csharp-ts-mode))

  (add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.jsx\\'" . tsx-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.ts\\'"  . typescript-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.mjs\\'" . js-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.cjs\\'" . js-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.js\\'"  . js-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.go\\'"  . go-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.c\\'"   . c-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.h\\'"   . c-or-c++-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.cpp\\'" . c++-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.cc\\'"  . c++-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.hpp\\'" . c++-ts-mode))
  (add-to-list 'auto-mode-alist '("CMakeLists\\.txt\\'" . cmake-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.cmake\\'" . cmake-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.cs\\'"  . csharp-ts-mode))

  (dolist (lang treesit-language-source-alist)
    (let ((language (car lang)))
      (unless (treesit-language-available-p language)
        (ignore-errors
          (let ((current-prefix-arg t))
            (treesit-install-language-grammar language)))))))

(use-package eglot
  :ensure nil
  :hook
  ((js-ts-mode         . eglot-ensure)
   (typescript-ts-mode . eglot-ensure)
   (tsx-ts-mode        . eglot-ensure)
   (css-ts-mode        . eglot-ensure)
   (json-ts-mode       . eglot-ensure)
   (go-ts-mode         . eglot-ensure)
   (cmake-ts-mode      . eglot-ensure)
   (csharp-ts-mode     . eglot-ensure)
   (c-ts-mode          . eglot-ensure)
   (c++-ts-mode        . eglot-ensure))
  :config
  (fset #'jsonrpc--log-event #'ignore))

;;;; Custom Tree-sitter Syntax Highlighting overrides to match Neovim
(require 'treesit)

(defface my-parameter-face
  '((t :foreground "#d4aa02"))
  "Face for function/method parameters to match Neovim.")

(defun my/syntax-apply-theme (&rest _)
  "Applies dynamic face overrides to match Neovim's ef-themes setup."
  (interactive)
  (let* ((yellow (ignore-errors (ef-themes-with-colors yellow)))
         (accent2 (ignore-errors (ef-themes-with-colors accent-2)))
         (fnname (ignore-errors (ef-themes-with-colors fnname)))
         (fg-main (face-foreground 'default nil t))
         (fg-dim (ignore-errors (ef-themes-with-colors fg-dim)))
         (comment (ignore-errors (ef-themes-with-colors comment)))
         (preprocessor (ignore-errors (ef-themes-with-colors preprocessor))))
    ;; Fallbacks
    (setq yellow (or yellow "#d4aa02"))
    (setq accent2 (or accent2 "#e490df"))
    (setq fnname (or fnname "#7fc500"))
    (setq preprocessor (or preprocessor "#5dc0aa"))
    (setq fg-main (or fg-main "#cfdfd5"))
    (setq fg-dim (or fg-dim "#808f80"))
    (setq comment (or comment "#b7a07f"))
    
    (set-face-attribute 'my-parameter-face nil :foreground yellow :weight 'normal :slant 'normal)
    (set-face-attribute 'font-lock-property-name-face nil :foreground accent2 :weight 'normal)
    (set-face-attribute 'font-lock-property-use-face nil :foreground accent2 :weight 'normal)
    (set-face-attribute 'font-lock-function-call-face nil :foreground fnname :weight 'normal)
    (set-face-attribute 'font-lock-operator-face nil :foreground fg-main :weight 'normal)
    (set-face-attribute 'font-lock-variable-use-face nil :foreground fg-main :weight 'normal :inherit nil)
    (set-face-attribute 'font-lock-bracket-face nil :foreground fg-dim :weight 'normal)
    (set-face-attribute 'font-lock-delimiter-face nil :foreground comment :weight 'normal)
    (set-face-attribute 'font-lock-preprocessor-face nil :foreground preprocessor :weight 'normal :inherit nil)))

(my/syntax-apply-theme)
(advice-add 'load-theme :after #'my/syntax-apply-theme)

(defun my/c-ts-setup-syntax ()
  (setq-local treesit-font-lock-settings
              (append treesit-font-lock-settings
                      (treesit-font-lock-rules
                       :language 'c
                       :feature 'preprocessor
                       :override t
                       '((preproc_def name: (identifier) @font-lock-preprocessor-face)
                         (preproc_function_def name: (identifier) @font-lock-preprocessor-face)
                         (preproc_directive) @font-lock-keyword-face
                         ["#define" "#if" "#ifdef" "#ifndef" "#else" "#elif" "#endif" "#include"] @font-lock-keyword-face)
                       :language 'c
                       :feature 'type
                       :override t
                       '((primitive_type) @font-lock-builtin-face)
                       :language 'c
                       :feature 'definition
                       :override t
                       '((parameter_declaration declarator: (identifier) @my-parameter-face)
                         (parameter_declaration declarator: (pointer_declarator declarator: (identifier) @my-parameter-face))
                         (parameter_declaration declarator: (pointer_declarator declarator: (pointer_declarator declarator: (identifier) @my-parameter-face)))
                         (parameter_declaration declarator: (array_declarator declarator: (identifier) @my-parameter-face))
                         (parameter_declaration declarator: (array_declarator declarator: (pointer_declarator declarator: (identifier) @my-parameter-face)))))))
  (treesit-font-lock-recompute-features))

(defun my/cpp-ts-setup-syntax ()
  (setq-local treesit-font-lock-settings
              (append treesit-font-lock-settings
                      (treesit-font-lock-rules
                       :language 'cpp
                       :feature 'preprocessor
                       :override t
                       '((preproc_def name: (identifier) @font-lock-preprocessor-face)
                         (preproc_function_def name: (identifier) @font-lock-preprocessor-face)
                         (preproc_directive) @font-lock-keyword-face
                         ["#define" "#if" "#ifdef" "#ifndef" "#else" "#elif" "#endif" "#include"] @font-lock-keyword-face)
                       :language 'cpp
                       :feature 'type
                       :override t
                       '((primitive_type) @font-lock-builtin-face)
                       :language 'cpp
                       :feature 'definition
                       :override t
                       '((parameter_declaration declarator: (identifier) @my-parameter-face)
                         (parameter_declaration declarator: (pointer_declarator declarator: (identifier) @my-parameter-face))
                         (parameter_declaration declarator: (pointer_declarator declarator: (pointer_declarator declarator: (identifier) @my-parameter-face)))
                         (parameter_declaration declarator: (array_declarator declarator: (identifier) @my-parameter-face))
                         (parameter_declaration declarator: (array_declarator declarator: (pointer_declarator declarator: (identifier) @my-parameter-face)))
                         (parameter_declaration declarator: (reference_declarator declarator: (identifier) @my-parameter-face))))))
  (treesit-font-lock-recompute-features))

(defun my/go-ts-setup-syntax ()
  (setq-local treesit-font-lock-settings
              (append treesit-font-lock-settings
                      (treesit-font-lock-rules
                       :language 'go
                       :feature 'definition
                       :override t
                       '((parameter_declaration name: (identifier) @my-parameter-face))
                       :language 'go
                       :feature 'type
                       :override t
                       '(((type_identifier) @font-lock-builtin-face
                          (:match "^\\(string\\|int\\|int8\\|int16\\|int32\\|int64\\|uint\\|uint8\\|uint16\\|uint32\\|uint64\\|uintptr\\|float32\\|float64\\|complex64\\|complex128\\|byte\\|rune\\|bool\\|error\\|any\\)$" @font-lock-builtin-face))))))
  (treesit-font-lock-recompute-features))

(add-hook 'c-ts-mode-hook #'my/c-ts-setup-syntax)
(add-hook 'c++-ts-mode-hook #'my/cpp-ts-setup-syntax)
(add-hook 'go-ts-mode-hook #'my/go-ts-setup-syntax)

(provide 'setup-lsp)
