(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "C-n") nil)
  (define-key evil-motion-state-map (kbd "C-n") nil)
  
  (define-key evil-normal-state-map (kbd "SPC") nil)
  (define-key evil-motion-state-map (kbd "SPC") nil)
  
  (define-key evil-normal-state-map (kbd "C-n") 'treemacs))

(use-package general
  :config
  (general-evil-setup)
  (general-create-definer my-leader-def :prefix "SPC")
  (my-leader-def
    :states 'normal
    ;; --- files 
    "f f" 'fzf-find-file
    "f w" 'my/fzf-live-grep
    "f g" 'fzf-git-files
    "f o" 'fzf-recentf
    ;; --- buffers 
    "b b" 'fzf-switch-buffer
    ;; --- formatting 
    "f m" 'apheleia-format-buffer
    ;; --- git 
    "g s" 'magit-status
    "g d" 'magit-dispatch
    "g g" (lambda () (interactive) (vterm-other-window "lazygit"))
    ;; --- org mode 
    "o a" 'org-agenda
    "o c" 'org-capture
    "o t" 'org-todo-list
    "o l" 'org-store-link
    "o o" (lambda () (interactive) (find-file org-directory))
    ;; --- others 
    "q q" 'save-buffers-kill-terminal
    "x"   'kill-current-buffer
    "e e" 'treemacs))

(use-package vterm
  :commands vterm)

(provide 'keybinds-config)
