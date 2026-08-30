;;; -*- lexical-binding: t; -*-

;; Global C-s Prefix Map
;; matching my tmux.conf prefix
(define-prefix-command 'my-tmux-prefix-map)
(global-set-key (kbd "C-s") 'my-tmux-prefix-map)

(define-key my-tmux-prefix-map (kbd "j")   #'jot-toggle)
(define-key my-tmux-prefix-map (kbd "M-j") #'jot-find-note)
(define-key my-tmux-prefix-map (kbd "M-w") #'jot-search)
(define-key my-tmux-prefix-map (kbd "M-i") #'jot-doctor)
(define-key my-tmux-prefix-map (kbd "M-k") #'jot-cleanup)
(define-key my-tmux-prefix-map (kbd "M-=") #'jot-increase-size)
(define-key my-tmux-prefix-map (kbd "M-+") #'jot-increase-size)
(define-key my-tmux-prefix-map (kbd "M--") #'jot-decrease-size)
(define-key my-tmux-prefix-map (kbd "M-_") #'jot-decrease-size)
(define-key my-tmux-prefix-map (kbd "M-r") #'jot-reset-size)

(defun my-jot-register-leader-keys ()
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "j"  '(:ignore t :which-key "Jot")
      "jj" '(jot-toggle :which-key "Toggle Note")
      "jf" '(jot-find-note :which-key "Find / Create Note")
      "js" '(jot-search :which-key "Search Notes")
      "jd" '(jot-doctor :which-key "Doctor")
      "jc" '(jot-cleanup :which-key "Cleanup")
      "ju" '(jot-unlink-session :which-key "Unlink Note"))))

(my-jot-register-leader-keys)
(with-eval-after-load 'evil-keys
  (my-jot-register-leader-keys))

(provide 'jot-keys)
