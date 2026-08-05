(use-package eat
  :ensure t
  :commands (eat eat-other-window)
  :init
  (with-eval-after-load 'evil
    (evil-set-initial-state 'eat-mode 'emacs))

  :config
  (setq eat-term-scrollback-size 10000)

  (add-hook 'eat-mode-hook
    (lambda ()
      (display-line-numbers-mode -1)
      (setq-local global-hl-line-mode nil)
      (setq-local scroll-margin 0)

      (let ((proc (get-buffer-process (current-buffer))))
        (when proc (set-process-query-on-exit-flag proc nil)))

      ;; ESC → Evil Normal, i/a → z powrotem do terminala
      (evil-define-key 'emacs eat-mode-map (kbd "<escape>") 'evil-normal-state)
      (evil-define-key 'normal eat-mode-map (kbd "i") 'eat-emacs-mode)
      (evil-define-key 'normal eat-mode-map (kbd "a") 'eat-emacs-mode)
      (evil-define-key 'normal eat-mode-map (kbd "SPC") 'my-leader-def)
      (define-key eat-mode-map (kbd "M-f") 'my/eat-toggle-bottom)))

  (add-hook 'eat-exit-hook
    (lambda (proc)
      (ignore-errors
        (when (and proc (processp proc))
          (let ((buf (process-buffer proc)))
            (when (and buf (buffer-live-p buf))
              (let ((win (get-buffer-window buf)))
                (kill-buffer buf)
                (when (and win (window-live-p win) (not (one-window-p t)))
                  (delete-window win))))))))))

(defun my/eat-toggle-bottom ()
  "Pokaż/ukryj terminal na dole ekranu (35% wysokości)."
  (interactive)
  (let* ((eat-bufs (cl-remove-if-not
                    (lambda (b) (with-current-buffer b (eq major-mode 'eat-mode)))
                    (buffer-list)))
         (visible (cl-find-if
                   (lambda (b) (get-buffer-window b))
                   eat-bufs)))
    (if visible
        (delete-window (get-buffer-window visible))
      (let ((buf (or (car eat-bufs)
                     (let ((b (generate-new-buffer "*terminal*")))
                       (with-current-buffer b (eat-mode))
                       b))))
        (display-buffer-at-bottom buf '((window-height . 0.35)))
        (select-window (get-buffer-window buf))
        (evil-emacs-state)))))

(global-set-key (kbd "M-f") 'my/eat-toggle-bottom)

(provide 'setup-terminal)
