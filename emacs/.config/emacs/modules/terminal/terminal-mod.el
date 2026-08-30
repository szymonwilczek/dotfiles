;;; Ghostel terminal configuration with libghostty -*- lexical-binding: t; -*-

(let ((ghostel-lisp (expand-file-name "elpa/ghostel/lisp" user-emacs-directory)))
  (when (file-directory-p ghostel-lisp)
    (add-to-list 'load-path ghostel-lisp)))

(use-package ghostel
  :ensure nil
  :commands (ghostel ghostel-project)
  :config
  (setq ghostel-color-palette nil)
  (setq ghostel-scrollback-size 10000)

  ;; Terminal buffer clean setup
  (add-hook 'ghostel-mode-hook
            (lambda ()
              (display-line-numbers-mode -1)
              (setq-local global-hl-line-mode nil)
              (setq-local scroll-margin 0)
              (when (fboundp 'evil-emacs-state)
                (evil-emacs-state))
              (when-let* ((proc (get-buffer-process (current-buffer))))
                (set-process-query-on-exit-flag proc nil))))

  (with-eval-after-load 'evil
    (evil-set-initial-state 'ghostel-mode 'emacs))

  ;; Auto-close window when shell process terminates
  (defun my/ghostel-auto-close-on-exit (buf _event)
    "Close terminal buffer and split window when process exits."
    (when (and buf (buffer-live-p buf))
      (let ((win (get-buffer-window buf t)))
        (kill-buffer buf)
        (when (and win (window-live-p win) (not (one-window-p t)))
          (delete-window win)))))

  (add-hook 'ghostel-exit-functions #'my/ghostel-auto-close-on-exit))

(defun my/ghostel-toggle-bottom ()
  "Toggle Ghostel terminal window."
  (interactive)
  (let* ((ghostel-buf (cl-find-if
                       (lambda (b) (with-current-buffer b (eq major-mode 'ghostel-mode)))
                       (buffer-list)))
         (win (and ghostel-buf (get-buffer-window ghostel-buf))))
    (if win
        (if (eq win (selected-window))
            (delete-window win)
          (select-window win))
      (if (and ghostel-buf (buffer-live-p ghostel-buf))
          (let ((new-win (display-buffer-at-bottom ghostel-buf '((window-height . 0.45)))))
            (when new-win (select-window new-win)))
        (let ((new-win (split-window (frame-root-window) -15 'below)))
          (select-window new-win)
          (ghostel))))))

(defun my/ghostel-open-full-buffer ()
  "Open Ghostel as a dedicated full buffer."
  (interactive)
  (let ((buf (ghostel t)))
    (switch-to-buffer buf)))

(require 'terminal-keys)

(provide 'terminal-mod)
