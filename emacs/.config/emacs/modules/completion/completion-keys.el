;;; Completion keybindings -*- lexical-binding: t; -*-

(with-eval-after-load 'vertico
  (define-key vertico-map (kbd "C-j") #'vertico-next)
  (define-key vertico-map (kbd "C-k") #'vertico-previous)
  (define-key vertico-map (kbd "M-j") #'vertico-next)
  (define-key vertico-map (kbd "M-k") #'vertico-previous)
  (evil-define-key '(insert normal) vertico-map
    (kbd "C-j") #'vertico-next
    (kbd "C-k") #'vertico-previous))

(global-set-key (kbd "C-SPC") #'completion-at-point)
(global-set-key (kbd "C-@") #'completion-at-point)
(global-set-key (kbd "M-x") #'execute-extended-command)
(global-set-key (kbd "A-x") #'execute-extended-command)

(global-set-key (kbd "C-.") #'embark-act)
(with-eval-after-load 'evil
  (define-key evil-insert-state-map (kbd "C-SPC") #'completion-at-point)
  (define-key evil-insert-state-map (kbd "C-@") #'completion-at-point)
  (define-key evil-normal-state-map (kbd "C-.") #'embark-act))

(with-eval-after-load 'evil-keys
  (when (fboundp 'my/leader-def)
    (my/leader-def

      ;; Files & Search
      "f"  '(:ignore t :which-key "Files/Search")
      "ff" '(my/project-find-file :which-key "Find File (Project)")
      "fo" '(my/open-file-anywhere :which-key "Open File (Anywhere)")
      "fw" '(my/project-search-word :which-key "Live Grep (Project)")
      "fl" '(consult-line :which-key "Search Lines (Buffer)"))))

(provide 'completion-keys)
