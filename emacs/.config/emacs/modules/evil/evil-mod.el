;;; -*- lexical-binding: t; -*-
(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-minibuffer t
        evil-search-module 'evil-search
        evil-undo-system 'undo-redo)
  :config
  (evil-mode 1)

  ;; Start minibuffer prompts in insert state
  (evil-set-initial-state 'minibuffer-mode 'insert)
  (add-hook 'minibuffer-setup-hook #'evil-insert-state 90)

  ;; Highlight on yank
  (defun my/evil-highlight-yank (orig-fn beg end &rest args)
    (let ((res (apply orig-fn beg end args)))
      (when (and (number-or-marker-p beg) (number-or-marker-p end))
        (let ((ov (make-overlay beg end)))
          (overlay-put ov 'face 'highlight)
          (overlay-put ov 'priority 1000)
          (run-at-time 0.2 nil
                       (lambda (overlay)
                         (when (overlay-buffer overlay)
                           (delete-overlay overlay)))
                       ov)))
      res))
  (advice-add 'evil-yank :around #'my/evil-highlight-yank)

  ;; strip redundant comment leader on line join
  (defun my/evil-clean-comment-on-join (&rest _args)
    "Strip redundant comment leader when joining comment lines."
    (when (or (nth 4 (syntax-ppss (point)))
              (and comment-start
                   (save-excursion
                     (forward-line 0)
                     (looking-at (concat "[ \t]*" (regexp-quote (string-trim comment-start)))))))
      (unless (and comment-end (> (length (string-trim comment-end)) 0)
                   (looking-at (concat "[ \t]*" (regexp-quote (string-trim comment-end)))))
        (let* ((comment-regex
                (cond
                 ((and (looking-at "[ \t]*\\*+[ \t]*")
                       (not (looking-at "[ \t]*\\*+/")))
                  "[ \t]*\\*+[ \t]*")
                 ((and comment-start-skip (looking-at (concat "[ \t]*" comment-start-skip)))
                  (concat "[ \t]*" comment-start-skip))
                 ((and comment-start (looking-at (concat "[ \t]*" (regexp-quote (string-trim comment-start)) "+[ \t]*")))
                  (concat "[ \t]*" (regexp-quote (string-trim comment-start)) "+[ \t]*")))))
          (when comment-regex
            (when (looking-at comment-regex)
              (replace-match " ")
              (fixup-whitespace)))))))
  (advice-add 'delete-indentation :after #'my/evil-clean-comment-on-join))

(use-package evil-collection
  :after evil
  :demand t
  :init
  (setq evil-collection-setup-minibuffer t)
  :config
  (setq evil-collection-mode-list (delq 'org (delq 'org-agenda evil-collection-mode-list)))
  (evil-collection-init))

(use-package evil-commentary
  :after evil
  :ensure t
  :config
  (evil-commentary-mode 1)
  (define-key evil-operator-state-map "c" #'evil-line))

(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1)

  ;; Surround the word at point without picking a text object: the
  ;; word runs to whitespace like iW, minus trailing , ; . : ! ? and
  ;; brackets or quotes left unpaired at its edges
  (defun my/evil-surround-thing-bounds ()
    "Return (BEG . END) of the word at point, or nil if there is none."
    (save-excursion
      (unless (looking-at-p "[ \t]\\|$")
        (let ((beg (progn (skip-chars-backward "^ \t\n") (point)))
              (end (let ((depth 0) (eol (line-end-position)))
                     (while (and (< (point) eol)
                                 (or (> depth 0)
                                     (not (memq (char-after) '(?\s ?\t)))))
                       (pcase (char-after)
                         ((or ?\( ?\[ ?\{) (cl-incf depth))
                         ((or ?\) ?\] ?\}) (setq depth (max 0 (1- depth)))))
                       (forward-char))
                     (point)))
              (pairs '((?\( . ?\)) (?\[ . ?\]) (?\{ . ?\}) (?< . ?>)))
              (trimmed t))
          (cl-flet ((count (c) (cl-count c (buffer-substring-no-properties beg end))))
            (while (and trimmed (< beg end))
              (let ((first (char-after beg))
                    (last (char-before end)))
                (setq trimmed t)
                (cond
                 ((memq last '(?, ?\; ?. ?: ?! ??))
                  (setq end (1- end)))
                 ((and (rassq last pairs)
                       (> (count last) (count (car (rassq last pairs)))))
                  (setq end (1- end)))
                 ((and (assq first pairs)
                       (> (count first) (count (cdr (assq first pairs)))))
                  (setq beg (1+ beg)))
                 ((and (memq last '(?\" ?' ?`)) (cl-oddp (count last)))
                  (setq end (1- end)))
                 ((and (memq first '(?\" ?' ?`)) (cl-oddp (count first)))
                  (setq beg (1+ beg)))
                 (t (setq trimmed nil))))))
          (and (< beg end) (cons beg end))))))

  (defun my/evil-surround-thing (char)
    "Surround the word at point with CHAR, the way `ys' would."
    (interactive (evil-surround-input-char))
    (let ((bounds (my/evil-surround-thing-bounds)))
      (unless bounds
        (user-error "No word at point"))
      (evil-surround-region (car bounds) (cdr bounds) nil char))))

(use-package evil-matchit
  :after evil
  :config
  (global-evil-matchit-mode 1))

(use-package evil-numbers
  :after evil)

(use-package evil-textobj-tree-sitter
  :after evil)

(use-package vundo
  :ensure t
  :commands vundo)

(require 'evil-keys)

(provide 'evil-mod)
