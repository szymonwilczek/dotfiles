;;; Completion keybindings -*- lexical-binding: t; -*-

;; Minibuffer (Vertico) navigation
(with-eval-after-load 'vertico
  (define-key vertico-map (kbd "C-j") #'vertico-next)
  (define-key vertico-map (kbd "C-k") #'vertico-previous)
  (define-key vertico-map (kbd "M-j") #'vertico-next)
  (define-key vertico-map (kbd "M-k") #'vertico-previous))

;; In-buffer (Company) navigation & selection
(with-eval-after-load 'company
  (define-key company-active-map (kbd "M-j") #'company-select-next)
  (define-key company-active-map (kbd "M-k") #'company-select-previous)
  (define-key company-active-map (kbd "TAB") #'company-complete-selection)
  (define-key company-active-map (kbd "<tab>") #'company-complete-selection)
  (define-key company-active-map (kbd "RET") #'company-complete-selection)
  (define-key company-active-map (kbd "<return>") #'company-complete-selection)
  (define-key company-active-map (kbd "<escape>") #'company-abort)
  (define-key company-active-map (kbd "C-g") #'company-abort))

;; Global manual completion trigger
(global-set-key (kbd "C-SPC") #'company-complete)
(global-set-key (kbd "C-@") #'company-complete)
(global-set-key (kbd "M-x") #'execute-extended-command)
(global-set-key (kbd "A-x") #'execute-extended-command)

;; Leader search keybindings
(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def

      ;; Files & Search
      "f"  '(:ignore t :which-key "Files/Search")
      "ff" '(consult-fd :which-key "Find File (Project)")
      "fw" '(consult-ripgrep :which-key "Live Grep (Project)")

      ;; Diagnostics
      "d"  '(:ignore t :which-key "Diagnostics")
      "dq" '(flymake-show-buffer-diagnostics :which-key "Diagnostic List"))))

(provide 'completion-keys)
