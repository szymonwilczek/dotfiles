;;; Minad stack minibuffer and Company completion -*- lexical-binding: t; -*-

;; Minibuffer Completion
;; (Vertico + Orderless + Marginalia + Consult)
(use-package vertico
  :ensure t
  :init
  (vertico-mode 1)
  :config
  (setq vertico-count 12
        vertico-cycle t))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode 1))

(use-package nerd-icons-completion
  :ensure t
  :after (marginalia nerd-icons)
  :config
  (nerd-icons-completion-mode 1))

(use-package consult
  :ensure t
  :config
  (setq consult-preview-key 'any
        consult-async-min-input 2))

;; In-Buffer Completion
;; (Company with overlay frontend)
(defcustom my-disabled-completion-modes
  '(text-mode
    markdown-mode
    gfm-mode
    rst-mode
    git-commit-mode
    fundamental-mode)
  "List of major modes where auto-completion popup is disabled."
  :type '(repeat symbol))

(use-package company
  :ensure t
  :hook ((prog-mode . (lambda ()
                        (unless (or (memq major-mode my-disabled-completion-modes)
                                    (derived-mode-p 'text-mode 'markdown-mode 'rst-mode))
                          (company-mode 1))))
         (conf-mode . company-mode))
  :config
  (setq company-minimum-prefix-length 1
        company-idle-delay 0.05
        company-selection-wrap-around t
        company-tooltip-limit 10
        company-tooltip-align-annotations t
        company-require-match nil
        company-frontends '(company-pseudo-tooltip-frontend)
        company-backends '((company-capf :with company-dabbrev)))

  ;; Clean overlay faces
  (set-face-attribute 'company-tooltip nil :inherit 'tooltip :background 'unspecified :foreground 'unspecified)
  (set-face-attribute 'company-tooltip-selection nil :inherit 'highlight :background 'unspecified :foreground 'unspecified :weight 'bold)
  (set-face-attribute 'company-tooltip-common nil :inherit 'font-lock-keyword-face :background 'unspecified :foreground 'unspecified)
  (set-face-attribute 'company-tooltip-annotation nil :inherit 'font-lock-comment-face :background 'unspecified :foreground 'unspecified))

(require 'completion-keys)

(provide 'completion-mod)
