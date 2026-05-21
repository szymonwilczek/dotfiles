(use-package vterm
  :ensure t
  :init
  (with-eval-after-load 'evil
    (evil-set-initial-state 'vterm-mode 'emacs))

  :config
  (setq vterm-timer-delay 0.01)
  (setq vterm-max-scrollback 10000)
  (setq vterm-keymap-exceptions '("C-c" "C-x" "C-u" "C-h" "M-x" "M-:" "M-!" "M-&" "C-y"))

  (add-hook 'vterm-mode-hook
    (lambda ()
      (setq-local emulation-mode-map-alists
        (remove '((general-override-mode . general-override-mode-map))
          emulation-mode-map-alists))

      (let ((proc (get-buffer-process (current-buffer))))
        (when proc (set-process-query-on-exit-flag proc nil)))

      (display-line-numbers-mode -1)
      (setq-local global-hl-line-mode nil)

      (define-key vterm-mode-map (kbd "<escape>") 'evil-normal-state)
      (evil-define-key 'normal vterm-mode-map (kbd "i") 'evil-emacs-state)
      (evil-define-key 'normal vterm-mode-map (kbd "a") 'evil-emacs-state)
      (evil-define-key 'normal vterm-mode-map (kbd "SPC") 'my-leader-def)))

  (add-hook 'vterm-exit-functions
    (lambda (proc _event)
      (ignore-errors
        (when (and proc (processp proc))
          (let ((buf (process-buffer proc)))
            (when (and buf (buffer-live-p buf))
              (let ((win (get-buffer-window buf)))
                (kill-buffer buf)
                (when (and win (window-live-p win) (not (one-window-p t)))
                  (delete-window win))))))))))

(defun my/vterm-toggle-bottom ()
  (interactive)
  (let* ((buf-name "*vterm*")
          (vterm-buf (get-buffer buf-name))
          (vterm-win (and vterm-buf (get-buffer-window vterm-buf))))
    (if vterm-win
      (delete-window vterm-win)
      (let ((display-buffer-alist
              '(("\\*vterm\\*"
                  (display-buffer-at-bottom)
                  (window-height . 0.35)))))
        (if vterm-buf
          (pop-to-buffer vterm-buf)
          (vterm))
        (evil-emacs-state)))))

(defun my/vterm-new-session ()
  (interactive)
  (vterm t)
  (evil-emacs-state))

(with-eval-after-load 'general
  (my-leader-def
    "v" 'my/vterm-toggle-bottom
    "t" '(:ignore t :which-key "Terminal")
    "tc" '(my/vterm-new-session :which-key "New session")
    ))

(provide 'setup-terminal)
