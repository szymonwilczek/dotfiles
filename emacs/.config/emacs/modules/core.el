;; Package Management
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa"  . "https://elpa.gnu.org/packages/")))
(package-initialize)

(require 'use-package)
(setq use-package-always-ensure t)

;; Encoding
(set-charset-priority 'unicode)
(setq locale-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)

;; Clean working directory baseline for daemon
(setq-default default-directory (expand-file-name "~/"))
(setq default-directory (expand-file-name "~/"))

;; Disable server frame instructions message
(setq server-client-instructions nil)

;; Disable visual/audio bells
(setq ring-bell-function 'ignore)

;; Scratch buffer settings
(setq inhibit-startup-screen t
      initial-scratch-message nil)

;; Indentation
(setq-default indent-tabs-mode nil
              tab-width 4)
(setq sentence-end-double-space nil)

;; Auto pair parentheses, brackets and quotes
(electric-pair-mode 1)
(setq electric-pair-preserve-balance t)

;; Auto refresh buffers when files change on disk
(global-auto-revert-mode 1)
(setq auto-revert-avoid-polling t
      auto-revert-interval 3
      auto-revert-check-vc-info nil)

;; Increase process read buffer for LSP (16MB)
(setq read-process-output-max (* 16 1024 1024))
(setq idle-update-delay 1.0)
(setq native-comp-async-report-warnings-errors 'silent)
(pixel-scroll-precision-mode 1)

(which-key-mode 1)
(setq which-key-idle-delay 0.3
      which-key-idle-secondary-delay 0.05
      which-key-add-column-padding 1)

(provide 'core)
