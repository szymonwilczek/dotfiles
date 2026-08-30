;;; -*- lexical-binding: t; -*-
;; Package Management
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa"  . "https://elpa.gnu.org/packages/")))
(package-initialize)

(require 'use-package)
(setq use-package-always-ensure t
      use-package-compute-statistics t)

;; Disable line numbers for large files
(defun my/disable-line-numbers-if-large-file ()
  "Disable line numbers if the buffer has more than 3000 lines."
  (when (> (count-lines (point-min) (point-max)) 3000)
    (setq-local display-line-numbers nil)
    (display-line-numbers-mode -1)))

(add-hook 'find-file-hook #'my/disable-line-numbers-if-large-file)

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

;; Environment PATH and Exec-Path for LSP binaries
(let ((user-paths (list (expand-file-name "~/.local/bin")
                        (expand-file-name "~/.npm-global/bin")
                        (expand-file-name "~/go/bin")
                        (expand-file-name "~/.cargo/bin"))))
  (dolist (p user-paths)
    (when (file-directory-p p)
      (add-to-list 'exec-path p)
      (setenv "PATH" (concat p ":" (getenv "PATH"))))))

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

;; Process read buffer for LSP (16MB) and performance flags
(setq read-process-output-max (* 16 1024 1024))
(setq idle-update-delay 1.0)
(setq native-comp-async-report-warnings-errors nil
      warning-minimum-level :emergency
      warning-suppress-types '((native-compiler) (with-editor) (files) (comp)))

;; Collect only during idle moments
(run-with-idle-timer 15.0 t #'garbage-collect)

;; Disable bidirectional text scanning in code buffers
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right
              bidi-inhibit-bpa t)

;; Only query Git for VC operations
(setq vc-handled-backends '(Git))

;; Rendering and scrolling performance
(setq inhibit-compacting-font-caches t
      highlight-nonselected-windows nil)

(setq-default scroll-conservatively 101
              scroll-margin 5
              scroll-preserve-screen-position t
              auto-window-vscroll nil)

;; Smooth pixel scrolling animation
(use-package good-scroll
  :ensure t
  :init
  (setq good-scroll-render-rate 0.0055
        good-scroll-duration 0.10
        good-scroll-step 60)
  :config
  (good-scroll-mode 1))

;; Window layout tiling compatibility
(setq transpose-dedicated-windows t)

;; Smarter paren pairing
(setq show-paren-not-in-comments-or-strings t)

;; Automatically delete trailing whitespace on save
(when (fboundp 'delete-trailing-whitespace-mode)
  (delete-trailing-whitespace-mode 1))

(add-hook 'server-after-make-frame-hook
          (lambda ()
            (when (get-buffer "*Warnings*")
              (let ((win (get-buffer-window "*Warnings*")))
                (when win (delete-window win))))))

;; Protect against UI freezes on minified/large files
(global-so-long-mode 1)

;; EditorConfig
(when (fboundp 'editorconfig-mode)
  (editorconfig-mode 1))

(which-key-mode 1)
(setq which-key-idle-delay 0.3
      which-key-idle-secondary-delay 0.05
      which-key-add-column-padding 1)

;; PDF viewer settings
(setq doc-view-pdfengine 'mupdf
      doc-view-resolution 180
      doc-view-continuous t)

(provide 'core)
