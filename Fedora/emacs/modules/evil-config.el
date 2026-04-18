(setq evil-want-C-u-scroll t)

(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-undo-system 'undo-redo)
  :config
  (evil-mode 1)

  (setq evil-insert-state-cursor '(bar . 2)
        evil-normal-state-cursor '(box . "white")
        evil-visual-state-cursor '(box . "orange")
        evil-replace-state-cursor '(hbar . "red"))

  (unless (display-graphic-p)
    (add-hook 'evil-insert-state-entry-hook
              (lambda () (send-string-to-terminal "\033[5 q")))
    (add-hook 'evil-normal-state-entry-hook
              (lambda () (send-string-to-terminal "\033[2 q")))
    (add-hook 'evil-visual-state-entry-hook
              (lambda () (send-string-to-terminal "\033[2 q")))
    (add-hook 'evil-replace-state-entry-hook
              (lambda () (send-string-to-terminal "\033[4 q")))
    (add-hook 'kill-emacs-hook
              (lambda () (send-string-to-terminal "\033[2 q"))))

  (defun my/smooth-scroll (lines direction)
    "Proste, płynne przewijanie o stałej prędkości."
    (ignore-errors
      (dotimes (_ lines)
        (if (eq direction 'down)
            (evil-scroll-line-down 1)
          (evil-scroll-line-up 1))
        (redisplay)
        (sleep-for 0.003))))

  (defun my/smooth-zz () (interactive)
	 (let ((diff (- (line-number-at-pos) (line-number-at-pos (window-start)) (/ (window-height) 2))))
	   (my/smooth-scroll (abs diff) (if (> diff 0) 'down 'up))))

  (defun my/smooth-zt () (interactive)
	 (let ((diff (- (line-number-at-pos) (line-number-at-pos (window-start)))))
	   (my/smooth-scroll (abs diff) 'down)))

  (defun my/smooth-zb () (interactive)
	 (let ((diff (- (line-number-at-pos) (line-number-at-pos (window-start)) (1- (window-height)))))
	   (my/smooth-scroll (abs diff) 'up)))

  
  (define-key evil-normal-state-map (kbd "C-d") (lambda () (interactive) (my/smooth-scroll (/ (window-height) 2) 'down)))
  (define-key evil-normal-state-map (kbd "C-u") (lambda () (interactive) (my/smooth-scroll (/ (window-height) 2) 'up)))
  (define-key evil-normal-state-map (kbd "C-f") (lambda () (interactive) (my/smooth-scroll (window-height) 'down)))
  (define-key evil-normal-state-map (kbd "C-b") (lambda () (interactive) (my/smooth-scroll (window-height) 'up)))
  
  (define-key evil-normal-state-map (kbd "zz") 'my/smooth-zz)
  (define-key evil-normal-state-map (kbd "zt") 'my/smooth-zt)
  (define-key evil-normal-state-map (kbd "zb") 'my/smooth-zb)

  (define-key minibuffer-local-map [escape] 'keyboard-escape-quit)
  )

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(provide 'evil-config)
