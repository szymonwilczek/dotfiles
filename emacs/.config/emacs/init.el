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
(require 'projectile-mod)
(require 'git-mod)
(require 'terminal-mod)
(require 'tabs-mod)
(require 'latex-mod)
(require 'org-mod)
(require 'bibliography-mod)
(require 'agent-mod)
(require 'writings-mod)
(require 'jot-mod)
(require 'dired-mod)
(require 'tramp-mod)


(provide 'init)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(global-wakatime-mode t)
 '(package-selected-packages
   '(citar citar-org company consult ef-themes evil evil-collection
           evil-surround forge general ghostel git-gutter
           git-gutter-fringe good-scroll magit marginalia nerd-icons
           nerd-icons-completion nerd-icons-dired olivetti orderless
           persp-projectile perspective plan-polsl projectile
           vertico vundo wakatime-mode))
 '(package-vc-selected-packages
   '((plan-polsl :url "https://github.com/szymonwilczek/plan-polsl.el"
                 :branch "main")
     (astro-ts-mode :url "https://github.com/Sorixelle/astro-ts-mode"
                    :branch "main"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
