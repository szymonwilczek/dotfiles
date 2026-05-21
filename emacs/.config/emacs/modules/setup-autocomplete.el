(use-package company
  :ensure t
  :hook ((prog-mode . company-mode)
         (conf-mode . company-mode))
  :config
  (setq company-minimum-prefix-length 1 
        company-idle-delay 0.1                 ;; 100ms delay
        company-selection-wrap-around t        ;; Looping menu
        company-tooltip-limit 10               ;; 10 hints
        company-tooltip-align-annotations t    ;; Align to right side
        company-dabbrev-downcase nil           ;; Camel Case
        company-dabbrev-ignore-case t
        company-require-match nil
        company-frontends '(company-pseudo-tooltip-frontend))

  (setq company-global-modes '(not minibuffer-mode))

  (setq company-backends '((company-capf :with company-dabbrev)))

  (define-key company-active-map (kbd "M-j") #'company-select-next)
  (define-key company-active-map (kbd "M-k") #'company-select-previous)
  (define-key company-active-map (kbd "TAB") #'company-complete-selection)
  (define-key company-active-map (kbd "<tab>") #'company-complete-selection)
  (define-key company-active-map (kbd "RET") nil)
  (define-key company-active-map (kbd "<return>") nil)
  (define-key company-active-map (kbd "SPC") nil)
  (define-key company-active-map (kbd "<escape>") #'company-abort)

  (set-face-attribute 'company-tooltip nil 
    :inherit 'tooltip 
    :background 'unspecified 
    :foreground 'unspecified)
  (set-face-attribute 'company-tooltip-selection nil 
    :inherit 'highlight 
    :background 'unspecified 
    :foreground 'unspecified 
    :weight 'bold)
  (set-face-attribute 'company-tooltip-common nil 
    :inherit 'font-lock-keyword-face 
    :background 'unspecified 
    :foreground 'unspecified)
  (set-face-attribute 'company-tooltip-annotation nil 
    :inherit 'font-lock-comment-face 
    :background 'unspecified 
    :foreground 'unspecified))

(provide 'setup-autocomplete)
