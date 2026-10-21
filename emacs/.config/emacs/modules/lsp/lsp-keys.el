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
    (flymake-goto-prev-error 1 nil t))
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
    (flymake-goto-next-error 1 nil t))
   ((and (bound-and-true-p flycheck-mode) (fboundp 'flycheck-next-error))
    (flycheck-next-error))
   ((fboundp 'next-error)
    (condition-case nil (next-error) (error (message "No next diagnostic found"))))
   (t (message "No active diagnostic engine"))))

(defvar my/diagnostic-popup-buffer " *diagnostic-popup*"
  "Buffer shown in the diagnostic popup.")

(defvar my/diagnostic-popup--source nil
  "Window, buffer and diagnostic spans the popup was opened for.
A list (WINDOW BUFFER SPANS), where SPANS is a list of (BEG . END).")

(defvar-keymap my/diagnostic-popup-mode-map
  :doc "Keymap active in the diagnostic popup.")

(define-minor-mode my/diagnostic-popup-mode
  "Minor mode of the diagnostic popup buffer."
  :keymap my/diagnostic-popup-mode-map)

(defun my/diagnostic-popup--window ()
  "Return the popup's window while it is shown, else nil."
  (and my/diagnostic-popup--source
       (get-buffer-window my/diagnostic-popup-buffer t)))

(defun my/diagnostic-popup--select (window)
  "Select WINDOW and give its frame input focus."
  (select-frame-set-input-focus (window-frame window))
  (select-window window))

(defun my/diagnostic-popup-window-next (count)
  "Move between the diagnostic popup and the window it was opened from.
Without a popup shown, run `evil-window-next' with COUNT."
  (interactive "P")
  (let ((popup (my/diagnostic-popup--window))
        (source (car my/diagnostic-popup--source)))
    (cond
     ((and popup (eq (selected-window) popup) (window-live-p source))
      (my/diagnostic-popup--select source))
     ((and popup (eq (selected-window) source))
      (my/diagnostic-popup--select popup))
     (t (evil-window-next count)))))

(defun my/diagnostic-popup-quit ()
  "Hide the diagnostic popup and return to the window it was opened from."
  (interactive)
  (let ((source (car my/diagnostic-popup--source)))
    (my/diagnostic-popup-hide)
    (when (window-live-p source)
      (my/diagnostic-popup--select source))))

(defun my/diagnostic-popup--label (diag)
  "Return the severity label of flymake DIAG, in its echo face."
  (pcase (flymake--lookup-type-property (flymake-diagnostic-type diag)
                                        'flymake-category)
    ('flymake-error (propertize "error" 'face 'flymake-error-echo))
    ('flymake-warning (propertize "warning" 'face 'flymake-warning-echo))
    (_ (propertize "note" 'face 'flymake-note-echo))))

(defun my/diagnostic-popup--fill (diags)
  "Fill the popup buffer with DIAGS, one paragraph each."
  (with-current-buffer (get-buffer-create my/diagnostic-popup-buffer)
    (let ((inhibit-read-only t)
          (fill-column 78))
      (erase-buffer)
      (dolist (diag diags)
        (unless (bobp) (insert "\n\n"))
        (let ((beg (point)))
          (insert (my/diagnostic-popup--label diag) ": "
                  (flymake-diagnostic-text diag))
          (fill-region beg (point))))
      (goto-char (point-min)))
    (setq buffer-read-only t)
    (my/diagnostic-popup-mode 1)
    (when (fboundp 'evil-local-mode)
      (evil-local-mode 1)
      (evil-normal-state)
      (evil-normalize-keymaps))
    (current-buffer)))

(defun my/diagnostic-popup-hide ()
  "Hide the diagnostic popup."
  (interactive)
  (setq my/diagnostic-popup--source nil)
  (remove-hook 'post-command-hook #'my/diagnostic-popup--maybe-hide)
  (when (get-buffer my/diagnostic-popup-buffer)
    (posframe-hide my/diagnostic-popup-buffer)))

(defun my/diagnostic-popup--maybe-hide ()
  "Hide the popup once point leaves the diagnostics it was opened for.
Moving into the popup itself keeps it open."
  (pcase-let ((`(,window ,buffer ,spans) my/diagnostic-popup--source))
    (unless (or (eq (current-buffer) (get-buffer my/diagnostic-popup-buffer))
                (and (eq (selected-window) window)
                     (eq (current-buffer) buffer)
                     (seq-some (lambda (span)
                                 (<= (car span) (point) (cdr span)))
                               spans)))
      (my/diagnostic-popup-hide))))

(defun my/diagnostic-popup ()
  "Show the flymake diagnostics at point in a popup above the cursor."
  (interactive)
  (let ((diags (flymake-diagnostics (point))))
    (unless diags
      (user-error "No diagnostic at point"))
    (posframe-show (my/diagnostic-popup--fill diags)
                   :poshandler #'posframe-poshandler-point-bottom-left-corner-upward
                   :border-width 1
                   :border-color (face-foreground 'shadow nil t)
                   :left-fringe 6
                   :right-fringe 6
                   :accept-focus t
                   :cursor 'box)
    (setq my/diagnostic-popup--source
          (list (selected-window) (current-buffer)
                (mapcar (lambda (d)
                          (cons (flymake-diagnostic-beg d)
                                (flymake-diagnostic-end d)))
                        diags)))
    (add-hook 'post-command-hook #'my/diagnostic-popup--maybe-hide)))

(defun my/show-diagnostic ()
  "Show diagnostic message under point."
  (interactive)
  (cond
   ((bound-and-true-p flymake-mode)
    (my/diagnostic-popup))
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
    (kbd "C-w d") #'my/show-diagnostic
    (kbd "C-w w") #'my/diagnostic-popup-window-next)
  (evil-define-key 'normal my/diagnostic-popup-mode-map
    "q" #'my/diagnostic-popup-quit))

;; Leader code actions & refactoring
(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def

      ;; Code & Refactor
      "c"  '(:ignore t :which-key "Code")
      "cf" '(my/format-buffer :which-key "Format Buffer")
      "cd" '(consult-flymake :which-key "Search Diagnostics")
      "cD" '(flymake-show-buffer-diagnostics :which-key "Diagnostics List")
      "ci" '(eglot-inlay-hints-mode :which-key "Toggle Inlay Hints")
      "cr" '(eglot-rename :which-key "Rename Symbol"))))

(provide 'lsp-keys)
