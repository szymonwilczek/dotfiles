;;; -*- lexical-binding: t; -*-
(let ((modules-dir (expand-file-name "modules" user-emacs-directory)))
  (add-to-list 'load-path modules-dir)
  (let ((default-directory modules-dir))
    (normal-top-level-add-subdirs-to-load-path)))

(require 'core)
(require 'evil-mod)
(require 'ui-mod)
(require 'completion-mod)
(require 'lsp-mod)
(require 'treemacs-mod)
(require 'projectile-mod)
(require 'git-mod)
(require 'terminal-mod)
(require 'dashboard-mod)
(require 'tabs-mod)
(require 'latex-mod)
(require 'org-mod)
(require 'bibliography-mod)
(require 'agent-mod)
(require 'writings-mod)

;; Native-compile modules in background if modified
(when (featurep 'native-compile)
  (add-hook 'emacs-startup-hook
            (lambda ()
              (let ((modules-dir (expand-file-name "modules" user-emacs-directory)))
                (native-compile-async modules-dir t)))))

(provide 'init)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(global-wakatime-mode t)
 '(package-selected-packages
   '(agent-shell apheleia auctex-latexmk cape cdlatex citar
                 company-auctex company-reftex consult corfu dashboard
                 diff-hl doom-themes eat ef-themes evil-collection
                 evil-org evil-surround forge general ghostel lsp-ui
                 marginalia nerd-icons-completion nerd-icons-corfu
                 notmuch olivetti orderless org-roam org-superstar
                 org-tree-slide pdf-tools persp-projectile plan-polsl
                 texfrag treemacs-evil treemacs-nerd-icons
                 treemacs-perspective treemacs-projectile vertico
                 vterm vundo wakatime-mode))
 '(package-vc-selected-packages
   '((plan-polsl :url "https://github.com/szymonwilczek/plan-polsl.el"
                 :branch "main"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
