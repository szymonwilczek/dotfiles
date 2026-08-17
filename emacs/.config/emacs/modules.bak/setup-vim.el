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
  (define-key evil-normal-state-map [escape] 'evil-ex-nohighlight)
  )

(defun my/toggle-relative-line-numbers ()
  (interactive)
  (if (eq display-line-numbers 'relative)
      (setq display-line-numbers t)
    (setq display-line-numbers 'relative)))

(defvar my/cursor-hidden-p nil
  "Whether the cursor is currently hidden.")

(defun my/toggle-cursor-visibility ()
  "Toggle cursor and cursorline highlights."
  (interactive)
  (if my/cursor-hidden-p
      (progn
        (setq-local cursor-type t)
        (hl-line-mode 1)
        (setq my/cursor-hidden-p nil))
    (progn
      (setq-local cursor-type nil)
      (hl-line-mode -1)
      (setq my/cursor-hidden-p t))))

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

  (general-define-key
    :states '(normal motion)
    "C-S-h" 'evil-window-move-far-left
    "C-S-l" 'evil-window-move-far-right)

  (general-create-definer my-leader-def
    :states '(normal motion visual)
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "M-SPC")

  (my-leader-def
    "r" 'my/toggle-relative-line-numbers
    "s" 'evil-window-vsplit
    "d" '(:ignore t :which-key "Diagnostics")
    "d q" 'flymake-show-buffer-diagnostics
    "t v" 'my/toggle-cursor-visibility))

(provide 'setup-vim)
