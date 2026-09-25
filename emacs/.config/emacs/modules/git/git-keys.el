;;; Git and Magit keybindings -*- lexical-binding: t; -*-

;; Git navigation jumps
;; ([c / ]c)
(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    "[c" 'git-gutter:previous-hunk
    "]c" 'git-gutter:next-hunk))

(defun my/git-conflict-next ()
  "Jump to the next conflict marker line."
  (interactive)
  (let ((orig (point)))
    (forward-line 1)
    (if (re-search-forward "^\\(<<<<<<<\\|=======\\|>>>>>>>\\)" nil t)
        (goto-char (line-beginning-position))
      (goto-char orig)
      (message "No next conflict marker"))))

(defun my/git-conflict-prev ()
  "Jump to the previous conflict marker line."
  (interactive)
  (let ((orig (point)))
    (forward-line -1)
    (if (re-search-backward "^\\(<<<<<<<\\|=======\\|>>>>>>>\\)" nil t)
        (goto-char (line-beginning-position))
      (goto-char orig)
      (message "No previous conflict marker"))))

(defun my/git-conflict-keep-upper ()
  "Keep our / upper version."
  (interactive)
  (require 'smerge-mode)
  (smerge-keep-upper))

(defun my/git-conflict-keep-lower ()
  "Keep their / lower version."
  (interactive)
  (require 'smerge-mode)
  (smerge-keep-lower))

(defun my/git-conflict-keep-all ()
  "Keep both versions."
  (interactive)
  (require 'smerge-mode)
  (smerge-keep-all))

;; Smerge conflict navigation jumps
(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    "[x" #'my/git-conflict-prev
    "]x" #'my/git-conflict-next))

;; Leader bindings
(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      ;; Git prefix
      "g"   '(:ignore t :which-key "Git")
      "gg"  '(magit-status :which-key "Magit Status")
      "gb"  '(magit-blame :which-key "Git Blame")
      "gl"  '(magit-log-current :which-key "Git Log"))))

(provide 'git-keys)
