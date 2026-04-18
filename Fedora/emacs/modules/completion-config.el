(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)            ;; popup during typing
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)     ;; min 2 chars to get it to show up 
  (corfu-cycle t)            ;; looping through list 
  (corfu-preselect 'prompt)  ;; do not select first entry right away 
  :init

  ;; disabling corfu in minibuffer 
  (add-hook 'prog-mode-hook #'corfu-mode)
  (add-hook 'text-mode-hook #'corfu-mode)
  (add-hook 'conf-mode-hook #'corfu-mode))

(use-package corfu-terminal
  :ensure t
  :after corfu
  :config
  (unless (display-graphic-p)
    (corfu-terminal-mode +1)))

(use-package cape
  :ensure t
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

(provide 'completion-config)
