;;; LSP and diagnostic keybindings -*- lexical-binding: t; -*-

(defvar my/formatters-alist
  '((go-mode            . ("gofmt"))
    (go-ts-mode         . ("gofmt"))
    (c-mode             . ("clang-format" "-assume-filename=%f"))
    (c++-mode           . ("clang-format" "-assume-filename=%f"))
    (c-ts-mode          . ("clang-format" "-assume-filename=%f"))
    (c++-ts-mode        . ("clang-format" "-assume-filename=%f"))
    (js-mode            . ("prettier" "--stdin-filepath" "%f"))
    (js-ts-mode         . ("prettier" "--stdin-filepath" "%f"))
    (typescript-mode    . ("prettier" "--stdin-filepath" "%f"))
    (typescript-ts-mode . ("prettier" "--stdin-filepath" "%f"))
    (json-mode          . ("prettier" "--stdin-filepath" "%f"))
    (json-ts-mode       . ("prettier" "--stdin-filepath" "%f"))
    (html-mode          . ("prettier" "--stdin-filepath" "%f"))
    (astro-mode         . ("prettier" "--stdin-filepath" "%f"))
    (astro-ts-mode      . ("prettier" "--stdin-filepath" "%f"))
    (css-mode           . ("prettier" "--stdin-filepath" "%f"))
    (yaml-mode          . ("prettier" "--stdin-filepath" "%f"))
    (yaml-ts-mode       . ("prettier" "--stdin-filepath" "%f"))
    (gfm-mode           . ("prettier" "--stdin-filepath" "%f"))
    (markdown-mode      . ("prettier" "--stdin-filepath" "%f")))
  "Alist mapping major-modes to external formatter CLI commands.")

(defun my/format-buffer-with-command (cmd-args)
  "Format current buffer by sending contents through external executable CMD-ARGS."
  (let* ((cmd (car cmd-args))
         (args (mapcar (lambda (arg)
                         (if (string-match-p "%f" arg)
                             (replace-regexp-in-string "%f" (or (buffer-file-name) "temp.md") arg)
                           arg))
                       (cdr cmd-args))))
    (if (not (executable-find cmd))
        nil
      (let ((orig-point (point))
            (orig-window-start (window-start))
            (orig-content (buffer-string))
            (err-file (make-temp-file "formatter-err-")))
        (unwind-protect
            (let ((exit-code
                   (apply #'call-process-region
                          (point-min) (point-max)
                          cmd
                          t
                          (list t err-file)
                          nil
                          args)))
              (if (= exit-code 0)
                  (progn
                    (goto-char (min orig-point (point-max)))
                    (set-window-start nil orig-window-start)
                    (message "Formatted buffer with %s" cmd)
                    t)
                (erase-buffer)
                (insert orig-content)
                (goto-char orig-point)
                (let ((err-msg (with-temp-buffer
                                 (insert-file-contents err-file)
                                 (buffer-string))))
                  (message "❌ Formatter %s error: %s" cmd (string-trim err-msg)))
                nil))
          (when (file-exists-p err-file)
            (delete-file err-file)))))))

(defun my/format-buffer ()
  "Format buffer with dedicated formatter, Eglot LSP, or indent-region fallback."
  (interactive)
  (let ((formatter (cdr (assoc major-mode my/formatters-alist))))
    (cond
     ((and formatter (my/format-buffer-with-command formatter))
      t)
     ((and (bound-and-true-p eglot--managed-mode) (fboundp 'eglot-format-buffer))
      (eglot-format-buffer)
      (message "Formatted buffer with Eglot LSP."))
     ((and (bound-and-true-p eglot--managed-mode) (fboundp 'eglot-format))
      (eglot-format)
      (message "Formatted buffer with Eglot LSP."))
     (t
      (indent-region (point-min) (point-max))
      (message "Formatted buffer with indent-region.")))))

(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    "gd" 'xref-find-definitions
    "gD" 'eglot-find-declaration
    "gi" 'eglot-find-implementation
    "gr" 'xref-find-references
    "K"  'eldoc
    "[d" 'flymake-goto-prev-error
    "]d" 'flymake-goto-next-error
    (kbd "C-w d") 'flymake-show-diagnostic))

;; Leader code actions & refactoring
(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def

      ;; Code & Refactor
      "c"  '(:ignore t :which-key "Code")
      "ci" '(eglot-inlay-hints-mode :which-key "Toggle Inlay Hints")
      "rn" '(eglot-rename :which-key "Rename Symbol")

      ;; Format shortcut
      "fm" '(my/format-buffer :which-key "Format Buffer")

      ;; Diagnostics
      "dq" '(flymake-show-buffer-diagnostics :which-key "Diagnostics List"))))

(provide 'lsp-keys)
