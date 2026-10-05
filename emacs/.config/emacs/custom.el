;;; custom.el --- Emacs customization file -*- lexical-binding: t; -*-
;; This file is managed by Emacs Custom — do NOT edit by hand if using M-x customize.
;; It is intentionally separate from init.el to prevent pollution of tracked dotfiles.

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(c-ts-indent-offset 8 nil nil "Customized with use-package c-ts-mode")
 '(global-wakatime-mode t)
 '(package-selected-packages
   '(au-themes bufferline citar citar-org colorful-mode company consult
               ef-themes evil evil-collection evil-commentary
               evil-matchit evil-numbers evil-surround general
               gh-radar ghostel git-gutter git-gutter-fringe jot magit
               marginalia nerd-icons nerd-icons-completion
               nerd-icons-dired olivetti orderless persp-projectile
               perspective plan-polsl projectile rainbow-mode rere
               treemacs treemacs-evil treemacs-nerd-icons
               treemacs-perspective treemacs-projectile vertico
               wakatime-mode))
 '(package-vc-selected-packages
   '((jot :url "https://github.com/szymonwilczek/jot.el" :branch "main")
     (bufferline :url "https://github.com/szymonwilczek/bufferline.el"
                 :branch "main")
     (rere :url "https://github.com/szymonwilczek/rere.el" :branch
           "main")
     (gh-radar :url "https://github.com/szymonwilczek/gh-radar.el"
               :branch "main")
     (au-themes :url "https://github.com/szymonwilczek/au-themes"
                :branch "main")
     (plan-polsl :url "https://github.com/szymonwilczek/plan-polsl.el"
                 :branch "main")
     (astro-ts-mode :url "https://github.com/Sorixelle/astro-ts-mode"
                    :branch "master")))
 '(tramp-use-connection-share t nil nil "Customized with use-package tramp"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
