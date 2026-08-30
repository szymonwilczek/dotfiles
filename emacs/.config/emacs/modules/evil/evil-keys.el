;;; Evil keybindings and Leader definitions -*- lexical-binding: t; -*-

(use-package general
  :after evil
  :demand t
  :config
  (general-evil-setup)

  ;; Global Leader SPC definer
  (general-create-definer my-leader-def
    :states '(normal motion visual)
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "M-SPC")

  ;; Core motion & normal state overrides
  (with-eval-after-load 'evil-maps
    (define-key evil-motion-state-map (kbd "SPC") nil)
    (define-key evil-normal-state-map (kbd "SPC") nil)
    (define-key evil-visual-state-map (kbd "SPC") nil))

  ;; Vim mappings
  (define-key evil-normal-state-map (kbd ";") 'evil-ex)
  (define-key evil-visual-state-map (kbd ";") 'evil-ex)
  (define-key evil-normal-state-map [escape] 'evil-ex-nohighlight)
  (define-key evil-normal-state-map (kbd "C-u") 'evil-scroll-up)
  (define-key evil-visual-state-map (kbd "C-u") 'evil-scroll-up)
  (define-key evil-normal-state-map "zc" 'hs-toggle-hiding)
  (define-key evil-normal-state-map "za" 'hs-show-block)

  ;; Window navigation
  (define-key evil-normal-state-map (kbd "C-w h") 'evil-window-left)
  (define-key evil-normal-state-map (kbd "C-w j") 'evil-window-down)
  (define-key evil-normal-state-map (kbd "C-w k") 'evil-window-up)
  (define-key evil-normal-state-map (kbd "C-w l") 'evil-window-right)

  ;; Base Leader Bindings
  (my-leader-def
    "u" '(vundo :which-key "Undo Tree")

    ;; Window splits
    "s" '(evil-window-vsplit :which-key "Split Vertical")
    "v" '(evil-window-split :which-key "Split Horizontal")

    ;; Buffer management
    "q" '(kill-current-buffer :which-key "Close Buffer")
    "b" '(:ignore t :which-key "Buffers")
    "bn" '((lambda () (interactive) (switch-to-buffer (generate-new-buffer "untitled"))) :which-key "New Buffer")

    ;; Elisp Eval
    "e" '(:ignore t :which-key "Eval/Reload")
    "eb" '(eval-buffer :which-key "Eval Buffer (Live Reload)")
    "ee" '(eval-last-sexp :which-key "Eval Expression")
    "er" '(eval-region :which-key "Eval Region")
    "ed" '(eval-defun :which-key "Eval Defun/Function")))

(provide 'evil-keys)
