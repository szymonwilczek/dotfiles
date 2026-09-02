;;; LSP and diagnostic keybindings -*- lexical-binding: t; -*-

(defvar my/formatters-alist
  '((go-mode            . ("gofmt"))
    (go-ts-mode         . ("gofmt"))
    (python-mode        . ("ruff" "format" "--stdin-filename=%f" "-"))
    (python-ts-mode     . ("ruff" "format" "--stdin-filename=%f" "-"))
    (c-mode             . ("clang-format" "-assume-filename=%f"))
    (c-ts-mode          . ("clang-format" "-assume-filename=%f"))
    (sh-mode            . ("shfmt" "-i" "4"))
    (bash-ts-mode       . ("shfmt" "-i" "4"))
    (js-mode            . ("prettier" "--stdin-filepath" "%f"))
    (js-ts-mode         . ("prettier" "--stdin-filepath" "%f"))
    (typescript-mode    . ("prettier" "--stdin-filepath" "%f"))
    (typescript-ts-mode . ("prettier" "--stdin-filepath" "%f"))
    (json-mode          . ("prettier" "--stdin-filepath" "%f"))
    (json-ts-mode       . ("prettier" "--stdin-filepath" "%f"))
    (js-json-mode       . ("prettier" "--stdin-filepath" "%f"))
    (html-mode          . ("prettier" "--stdin-filepath" "%f"))
    (mhtml-mode         . ("prettier" "--stdin-filepath" "%f"))
    (mhtml-ts-mode      . ("prettier" "--stdin-filepath" "%f"))
    (astro-mode         . ("prettier" "--stdin-filepath" "%f"))
    (astro-ts-mode      . ("prettier" "--stdin-filepath" "%f"))
    (css-mode           . ("prettier" "--stdin-filepath" "%f"))
    (css-ts-mode        . ("prettier" "--stdin-filepath" "%f"))
    (yaml-mode          . ("prettier" "--stdin-filepath" "%f"))
    (yaml-ts-mode       . ("prettier" "--stdin-filepath" "%f"))
    (gfm-mode           . ("prettier" "--stdin-filepath" "%f"))
    (markdown-mode      . ("prettier" "--stdin-filepath" "%f")))
  "Alist mapping major-modes to external formatter CLI commands.")

(defun my/format-buffer-with-command (cmd-args)
  "Format current buffer by sending contents through external executable CMD-ARGS.
If formatted output is identical to current buffer content, no modifications are made."
  (let* ((cmd (car cmd-args))
         (args (mapcar (lambda (arg)
                         (if (string-match-p "%f" arg)
                             (replace-regexp-in-string "%f" (or (buffer-file-name) "temp.txt") arg)
                           arg))
                       (cdr cmd-args))))
    (if (not (executable-find cmd))
        nil
      (let* ((orig-point (point))
             (orig-window-start (window-start))
             (err-file (make-temp-file "formatter-err-"))
             (out-buf (generate-new-buffer " *formatter-out*")))
        (unwind-protect
            (let ((exit-code
                   (apply #'call-process-region
                          (point-min) (point-max)
                          cmd
                          nil
                          (list out-buf err-file)
                          nil
                          args)))
              (if (/= exit-code 0)
                  (let ((err-msg (with-temp-buffer
                                   (insert-file-contents err-file)
                                   (buffer-string))))
                    (message "Formatter %s error: %s" cmd (string-trim err-msg))
                    nil)
                (let ((identical (and (= (buffer-size) (buffer-size out-buf))
                                      (zerop (compare-buffer-substrings (current-buffer) nil nil out-buf nil nil)))))
                  (if identical
                      (progn
                        (message "Buffer is already formatted (no changes).")
                        t)
                    (replace-buffer-contents out-buf)
                    (goto-char (min orig-point (point-max)))
                    (set-window-start nil orig-window-start)
                    (message "Formatted buffer with %s" cmd)
                    t))))
          (kill-buffer out-buf)
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
     ((derived-mode-p 'python-mode 'python-ts-mode)
      (message "No Python formatter available."))
     (t
      (let ((was-modified (buffer-modified-p))
            (tick (buffer-chars-modified-tick)))
        (indent-region (point-min) (point-max))
        (if (= tick (buffer-chars-modified-tick))
            (progn
              (set-buffer-modified-p was-modified)
              (message "Buffer is already formatted (no changes)."))
          (message "Formatted buffer with indent-region.")))))))

(defun my/goto-prev-diagnostic ()
  "Jump to previous diagnostic error or warning across Flymake, Flycheck, or next-error."
  (interactive)
  (cond
   ((and (bound-and-true-p flymake-mode) (fboundp 'flymake-goto-prev-error))
    (flymake-goto-prev-error 1 t))
   ((and (bound-and-true-p flycheck-mode) (fboundp 'flycheck-previous-error))
    (flycheck-previous-error))
   ((fboundp 'previous-error)
    (condition-case nil (previous-error) (error (message "No previous diagnostic found"))))
   (t (message "No active diagnostic engine"))))

(defun my/goto-next-diagnostic ()
  "Jump to next diagnostic error or warning across Flymake, Flycheck, or next-error."
  (interactive)
  (cond
   ((and (bound-and-true-p flymake-mode) (fboundp 'flymake-goto-next-error))
    (flymake-goto-next-error 1 t))
   ((and (bound-and-true-p flycheck-mode) (fboundp 'flycheck-next-error))
    (flycheck-next-error))
   ((fboundp 'next-error)
    (condition-case nil (next-error) (error (message "No next diagnostic found"))))
   (t (message "No active diagnostic engine"))))

(defun my/show-diagnostic ()
  "Show diagnostic message under point."
  (interactive)
  (cond
   ((and (bound-and-true-p flymake-mode) (fboundp 'flymake-show-diagnostic))
    (flymake-show-diagnostic (point)))
   ((and (bound-and-true-p flycheck-mode) (fboundp 'flycheck-display-error-at-point))
    (flycheck-display-error-at-point))
   ((fboundp 'eldoc-doc-buffer)
    (eldoc-doc-buffer))
   (t (message "No diagnostic at point"))))

(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    "gd" 'xref-find-definitions
    "gD" 'eglot-find-declaration
    "gi" 'eglot-find-implementation
    "gr" 'xref-find-references
    "K"  'eldoc
    "[d" #'my/goto-prev-diagnostic
    "]d" #'my/goto-next-diagnostic
    (kbd "C-w d") #'my/show-diagnostic))

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
