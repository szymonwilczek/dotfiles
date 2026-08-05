(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                          ("elpa" . "https://elpa.gnu.org/packages/")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

(setq gc-cons-threshold 500000000  ;; 500MB
  gc-cons-percentage 0.1)

;; for LSP (16 MB)
(setq read-process-output-max (* 16 1024 1024))

(electric-pair-mode 1)
(setq electric-pair-preserve-balance t)

(setq inhibit-compacting-font-caches t)
(setq fast-but-imprecise-scrolling t)
(setq redisplay-skip-fontification-on-input t)
(setq idle-update-delay 1.0)
(pixel-scroll-precision-mode 1)

(setq-default bidi-display-reordering nil)
(setq bidi-inhibit-bpa t
  long-line-threshold 1000
  large-hscroll-threshold 1000
  syntax-wholeline-max 1000)

(setq vc-handled-backends '(Git))
(remove-hook 'find-file-hook 'vc-find-file-hook)
(remove-hook 'find-file-hook 'vc-refresh-state)
(setq vc-follow-symlinks t)

;; (setq jit-lock-defer-time 0.05
;;       jit-lock-stealth-time 1)

(setq native-comp-async-report-warnings-errors 'silent)
(setq frame-inhibit-implied-resize t)
(setq pop-up-windows nil)

(setq auto-revert-avoid-polling t)
(setq auto-revert-interval 5)
(setq auto-revert-check-vc-info nil)

(provide 'core)
