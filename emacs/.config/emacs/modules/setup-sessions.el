(require 'use-package)

;; ========================
;; PERSPECTIVE & PROJECTILE
;; ========================
(use-package perspective
  :ensure t
  :custom
  (persp-mode-prefix-key (kbd "C-c M-p"))
  (persp-kill-foreign-buffer t)
  :init
  (persp-mode 1))

(use-package persp-projectile
  :ensure t
  :after (perspective projectile))

;; ========================
;;         TREEMACS
;; ========================
(use-package treemacs
  :ensure t
  :defer t
  :commands (treemacs treemacs-toggle)
  :config (setq treemacs-persist-file nil))

(use-package treemacs-perspective
  :ensure t
  :after (treemacs perspective)
  :config (treemacs-set-scope-type 'Perspectives))

(use-package treemacs-projectile
  :ensure t
  :after (treemacs projectile))

(provide 'setup-sessions)
