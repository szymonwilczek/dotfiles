(use-package ghostel
  :ensure t
  :vc (:url "https://github.com/dakra/ghostel"
       :lisp-dir "lisp"
       :rev :newest)
  :commands (ghostel ghostel-project)

  :config
  (setq ghostel-scrollback-size 10000)

  (add-hook 'ghostel-mode-hook
    (lambda ()
      (display-line-numbers-mode -1)
      (setq-local global-hl-line-mode nil)
      (setq-local scroll-margin 0)

      (let ((proc (get-buffer-process (current-buffer))))
        (when proc (set-process-query-on-exit-flag proc nil)))

      (define-key ghostel-semi-char-mode-map (kbd "M-f") 'my/ghostel-toggle-bottom)))

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

(use-package evil-ghostel
  :ensure t
  :vc (:url "https://github.com/dakra/evil-ghostel"
       :rev :newest)
  :after (ghostel evil)
  :hook (ghostel-mode . evil-ghostel-mode))

(defun my/ghostel-toggle-bottom ()
  "Pokaż/ukryj terminal na dole ekranu (35% wysokości)."
  (interactive)
  (let* ((ghostel-bufs (cl-remove-if-not
                        (lambda (b) (with-current-buffer b (eq major-mode 'ghostel-mode)))
                        (buffer-list)))
         (visible (cl-find-if
                   (lambda (b) (get-buffer-window b))
                   ghostel-bufs)))
    (if visible
        (delete-window (get-buffer-window visible))
      (let ((buf (or (car ghostel-bufs)
                     (ghostel))))
        (display-buffer-at-bottom buf '((window-height . 0.35)))
        (select-window (get-buffer-window buf))))))

(global-set-key (kbd "M-f") 'my/ghostel-toggle-bottom)

(provide 'setup-terminal)
