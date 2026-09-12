;;; custom.el --- Emacs customization file -*- lexical-binding: t; -*-
;; This file is managed by Emacs Custom — do NOT edit by hand if using M-x customize.
;; It is intentionally separate from init.el to prevent pollution of tracked dotfiles.

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(global-wakatime-mode t)
 '(helm-minibuffer-history-key "M-p")
 '(package-selected-packages
   '(citar citar-org colorful-mode company consult ef-themes evil
           evil-collection evil-surround general ghostel git-gutter
           git-gutter-fringe helm icloud-calendar magit marginalia
           nerd-icons nerd-icons-completion nerd-icons-dired olivetti
           orderless persp-projectile perspective plan-polsl
           projectile rainbow-mode vertico vundo wakatime-mode))
 '(package-vc-selected-packages
   '((plan-polsl :url "https://github.com/szymonwilczek/plan-polsl.el"
                 :branch "main")
     (astro-ts-mode :url "https://github.com/Sorixelle/astro-ts-mode"
                    :branch "main")))
 '(tramp-use-connection-share t nil nil "Customized with use-package tramp"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-block-begin-line ((t (:inherit font-lock-comment-face :slant italic))))
 '(org-block-end-line ((t (:inherit font-lock-comment-face :slant italic))))
 '(org-document-title ((t (:inherit default :weight bold :height 1.4 :underline nil))))
 '(org-level-1 ((t (:inherit default :weight bold :height 1.25))))
 '(org-level-2 ((t (:inherit default :weight bold :height 1.15))))
 '(org-level-3 ((t (:inherit default :weight bold :height 1.08))))
 '(org-level-4 ((t (:inherit default :weight semi-bold :height 1.02)))))
