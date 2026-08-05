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


(defvar my/eat-buffer-counter 0 "Licznik sesji eat.")

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
      (let ((buf (or (car eat-bufs) (my/eat--create-new))))
        (let ((display-buffer-alist
               '((".*"
                  (display-buffer-at-bottom)
                  (window-height . 0.35)))))
          (pop-to-buffer buf)
          (evil-emacs-state))))))

(defun my/eat--create-new ()
  "Stwórz nowy bufor eat."
  (cl-incf my/eat-buffer-counter)
  (let ((buf-name (format "*terminal-%d*" my/eat-buffer-counter)))
    (eat nil buf-name)
    (get-buffer buf-name)))


(defun my/eat-new-session ()
  "Otwórz nową sesję terminala na dole."
  (interactive)
  (let* ((buf (my/eat--create-new))
         (display-buffer-alist
          '((".*"
             (display-buffer-at-bottom)
             (window-height . 0.35)))))
    (pop-to-buffer buf)
    (evil-emacs-state)))


(defun my/eat-next ()
  "Przełącz na następny terminal."
  (interactive)
  (let* ((eat-bufs (cl-remove-if-not
                    (lambda (b) (with-current-buffer b (eq major-mode 'eat-mode)))
                    (buffer-list)))
         (current (current-buffer))
         (idx (cl-position current eat-bufs))
         (next (if (and idx (< (1+ idx) (length eat-bufs)))
                   (nth (1+ idx) eat-bufs)
                 (car eat-bufs))))
    (when next (switch-to-buffer next))))

(defun my/eat-prev ()
  "Przełącz na poprzedni terminal."
  (interactive)
  (let* ((eat-bufs (cl-remove-if-not
                    (lambda (b) (with-current-buffer b (eq major-mode 'eat-mode)))
                    (buffer-list)))
         (current (current-buffer))
         (idx (cl-position current eat-bufs))
         (prev (if (and idx (> idx 0))
                   (nth (1- idx) eat-bufs)
                 (car (last eat-bufs)))))
    (when prev (switch-to-buffer prev))))


(defun my/eat-move-to (direction)
  "Przenieś bieżący terminal w DIRECTION (:left :right :up :down)."
  (let ((buf (current-buffer))
        (win (selected-window)))
    (unless (eq major-mode 'eat-mode)
      (user-error "To nie jest bufor terminala!"))
    (delete-window win)
    (pcase direction
      (:left  (split-window-horizontally) (switch-to-buffer buf))
      (:right (split-window-horizontally) (other-window 1) (switch-to-buffer buf))
      (:up    (split-window-vertically) (switch-to-buffer buf))
      (:down  (split-window-vertically) (other-window 1) (switch-to-buffer buf)))))

(defun my/eat-move-left ()  (interactive) (my/eat-move-to :left))
(defun my/eat-move-right () (interactive) (my/eat-move-to :right))
(defun my/eat-move-up ()    (interactive) (my/eat-move-to :up))
(defun my/eat-move-down ()  (interactive) (my/eat-move-to :down))

(defun my/eat-kill ()
  "Zamknij bieżący terminal."
  (interactive)
  (when (eq major-mode 'eat-mode)
    (let ((win (selected-window)))
      (kill-current-buffer)
      (when (and (window-live-p win) (not (one-window-p t)))
        (delete-window win)))))


(global-set-key (kbd "M-f") 'my/eat-toggle-bottom)

(with-eval-after-load 'general
  (my-leader-def
    "t"  '(:ignore t :which-key "Terminal")
    "tc" '(my/eat-new-session :which-key "Nowa sesja")
    "th" '(my/eat-move-left :which-key "Przenieś ←")
    "tl" '(my/eat-move-right :which-key "Przenieś →")
    "tk" '(my/eat-move-up :which-key "Przenieś ↑")
    "tj" '(my/eat-move-down :which-key "Przenieś ↓")
    "tn" '(my/eat-next :which-key "Następny terminal")
    "tp" '(my/eat-prev :which-key "Poprzedni terminal")
    "tx" '(my/eat-kill :which-key "Zamknij terminal")))

(provide 'setup-terminal)
