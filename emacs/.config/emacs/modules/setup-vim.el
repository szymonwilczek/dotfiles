(use-package evil
  :demand t
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  :config
  (evil-mode 1)
  (setq evil-ex-complete-emacs-commands nil)
  (with-eval-after-load 'evil-maps
    (define-key evil-motion-state-map (kbd "SPC") nil)
    (define-key evil-normal-state-map (kbd "SPC") nil)
    (define-key evil-visual-state-map (kbd "SPC") nil)
    (define-key evil-insert-state-map (kbd "SPC") (lambda () (interactive) (insert " "))))

  (define-key evil-normal-state-map (kbd "C-u") 'evil-scroll-up)
  (define-key evil-visual-state-map (kbd "C-u") 'evil-scroll-up)
  (define-key evil-normal-state-map (kbd "C-w w") 'other-window)
  (define-key evil-normal-state-map (kbd "C-w h") 'evil-window-left)
  (define-key evil-normal-state-map (kbd "C-w l") 'evil-window-right)

  (define-key evil-normal-state-map (kbd ";") 'evil-ex)
  (define-key evil-visual-state-map (kbd ";") 'evil-ex)
  )

(defun my/toggle-relative-line-numbers ()
  (interactive)
  (if (eq display-line-numbers 'relative)
    (setq display-line-numbers t)
    (setq display-line-numbers 'relative)))

(use-package evil-collection
  :after evil
  :config (evil-collection-init))

(use-package general
  :after evil
  :demand t
  :config
  (general-evil-setup)
  (general-define-key
    :states 'normal
    "TAB" 'tab-line-switch-to-next-tab
    "<tab>" 'tab-line-switch-to-next-tab      ; :BufferLineCycleNext
    "<backtab>" 'tab-line-switch-to-prev-tab  ; :BufferLineCyclePrev
    "S-<tab>" 'tab-line-switch-to-prev-tab)
  
  (general-define-key
    :states '(normal motion visual insert)
    "C-n" 'treemacs)

  (general-create-definer my-leader-def
    :states '(normal motion visual)
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "M-SPC")

  (my-leader-def
    "r n" 'my/toggle-relative-line-numbers))

(provide 'setup-vim)
