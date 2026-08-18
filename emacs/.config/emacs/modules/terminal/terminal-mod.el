;;; Ghostel terminal configuration with libghostty

(let ((ghostel-lisp (expand-file-name "elpa/ghostel/lisp" user-emacs-directory)))
  (when (file-directory-p ghostel-lisp)
    (add-to-list 'load-path ghostel-lisp)))

(use-package ghostel
  :ensure nil
  :commands (ghostel ghostel-project)
  :config
  (setq ghostel-scrollback-size 10000)

  ;; Terminal buffer clean setup
  (add-hook 'ghostel-mode-hook
            (lambda ()
              (display-line-numbers-mode -1)
              (setq-local global-hl-line-mode nil)
              (setq-local scroll-margin 0)
              (when-let ((proc (get-buffer-process (current-buffer))))
                (set-process-query-on-exit-flag proc nil))))

  ;; Auto-close window when shell process terminates
  ;; (exit / Ctrl-d)
  (add-hook 'ghostel-exit-hook
            (lambda (proc)
              (ignore-errors
                (when (and proc (processp proc))
                  (let ((buf (process-buffer proc)))
                    (when (and buf (buffer-live-p buf))
                      (let ((win (get-buffer-window buf)))
                        (kill-buffer buf)
                        (when (and win (window-live-p win) (not (one-window-p t)))
                          (delete-window win))))))))))

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
