;;; -*- lexical-binding: t; -*-
(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-undo-system 'undo-redo)
  :config
  (evil-mode 1)

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
  (global-evil-surround-mode 1))

(use-package evil-matchit
  :after evil
  :config
  (global-evil-matchit-mode 1))

(use-package evil-numbers
  :after evil)

(use-package evil-mc
  :after evil
  :ensure t
  :init
  (global-evil-mc-mode 1)
  :config
  (add-hook 'evil-mc-after-cursors-deleted-hook #'evil-ex-nohighlight))

(use-package vundo
  :ensure t
  :custom
  (vundo-glyph-alist vundo-unicode-symbols)
  (vundo-compact-display t))

(require 'evil-keys)

(provide 'evil-mod)
