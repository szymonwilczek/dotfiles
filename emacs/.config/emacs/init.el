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

(provide 'init)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(global-wakatime-mode t)
 '(package-selected-packages
   '(apheleia auctex-latexmk cape citar company-auctex company-reftex
              consult corfu dashboard diff-hl doom-themes eat
              ef-themes evil-collection evil-org evil-surround forge
              general ghostel lsp-ui marginalia nerd-icons-completion
              notmuch orderless org-roam org-superstar org-tree-slide
              persp-projectile texfrag treemacs-evil
              treemacs-nerd-icons treemacs-perspective
              treemacs-projectile vertico vterm wakatime-mode)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
