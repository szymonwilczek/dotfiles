;;; -*- lexical-binding: t; -*-

;; Global C-s Prefix Map
;; matching my tmux.conf prefix
(define-prefix-command 'my-tmux-prefix-map)
(global-set-key (kbd "C-s") 'my-tmux-prefix-map)

(define-key my-tmux-prefix-map (kbd "j")   #'jot-toggle)
(define-key my-tmux-prefix-map (kbd "M-j") #'jot-find-note)
(define-key my-tmux-prefix-map (kbd "M-k") #'jot-cleanup)
(define-key my-tmux-prefix-map (kbd "M-=") #'jot-increase-size)
(define-key my-tmux-prefix-map (kbd "M-+") #'jot-increase-size)
(define-key my-tmux-prefix-map (kbd "M--") #'jot-decrease-size)
(define-key my-tmux-prefix-map (kbd "M-_") #'jot-decrease-size)
(define-key my-tmux-prefix-map (kbd "M-r") #'jot-reset-size)

(with-eval-after-load 'evil
  (evil-define-key* '(insert normal visual motion emacs) 'global
    (kbd "C-s") 'my-tmux-prefix-map))

(with-eval-after-load 'ghostel
  (unless (member "C-s" ghostel-keymap-exceptions)
    (setq ghostel-keymap-exceptions (append (list "C-s") ghostel-keymap-exceptions))
    (ghostel--rebuild-semi-char-keymap))
  (define-key ghostel-mode-map (kbd "C-s") 'my-tmux-prefix-map)
  (define-key ghostel-semi-char-mode-map (kbd "C-s") 'my-tmux-prefix-map)
  (with-eval-after-load 'evil
    (when (boundp 'evil-ghostel-mode-map)
      (evil-define-key* '(insert normal visual motion emacs) evil-ghostel-mode-map
        (kbd "C-s") 'my-tmux-prefix-map))))

(provide 'jot-keys)
