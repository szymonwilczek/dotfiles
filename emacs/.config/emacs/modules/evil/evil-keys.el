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

  (defun my/evil-escape-dwim ()
    "Clear evil-mc cursors if active, otherwise clear search highlight."
    (interactive)
    (if (and (fboundp 'evil-mc-has-cursors-p) (evil-mc-has-cursors-p))
        (evil-mc-undo-all-cursors)
      (evil-ex-nohighlight)))

  (define-key evil-normal-state-map [escape] #'my/evil-escape-dwim)
  (define-key evil-normal-state-map (kbd "C-u") 'evil-scroll-up)
  (define-key evil-visual-state-map (kbd "C-u") 'evil-scroll-up)
  (define-key evil-normal-state-map "zc" 'hs-toggle-hiding)
  (define-key evil-normal-state-map "za" 'hs-show-block)

  ;; Multicursor shortcuts
  (define-key evil-normal-state-map (kbd "M-j") #'evil-mc-make-cursor-move-next-line)
  (define-key evil-visual-state-map (kbd "M-j") #'evil-mc-make-cursor-move-next-line)
  (define-key evil-normal-state-map (kbd "M-k") #'evil-mc-make-cursor-move-prev-line)
  (define-key evil-visual-state-map (kbd "M-k") #'evil-mc-make-cursor-move-prev-line)
  (define-key evil-normal-state-map (kbd "M-d") #'evil-mc-make-and-goto-next-match)
  (define-key evil-visual-state-map (kbd "M-d") #'evil-mc-make-and-goto-next-match)
  (define-key evil-normal-state-map (kbd "M-D") #'evil-mc-skip-and-goto-next-match)
  (define-key evil-visual-state-map (kbd "M-D") #'evil-mc-skip-and-goto-next-match)

  ;; Window navigation
  (define-key evil-normal-state-map (kbd "C-w h") 'evil-window-left)
  (define-key evil-normal-state-map (kbd "C-w j") 'evil-window-down)
  (define-key evil-normal-state-map (kbd "C-w k") 'evil-window-up)
  (define-key evil-normal-state-map (kbd "C-w l") 'evil-window-right)

  ;; Base Leader Bindings
  (my-leader-def
    "u" '(vundo :which-key "Undo Tree")

    ;; Multicursor Leader bindings
    "m"  '(:ignore t :which-key "Multicursor")
    "mj" '(evil-mc-make-cursor-move-next-line :which-key "Cursor Down")
    "mk" '(evil-mc-make-cursor-move-prev-line :which-key "Cursor Up")
    "md" '(evil-mc-make-and-goto-next-match :which-key "Match Next")
    "mD" '(evil-mc-skip-and-goto-next-match :which-key "Skip Match")
    "ma" '(evil-mc-make-all-cursors :which-key "Match All in Buffer")
    "mu" '(evil-mc-undo-all-cursors :which-key "Clear All Cursors")
    "mq" '(evil-mc-pause-cursors :which-key "Pause/Resume Cursors")

    ;; Window splits
    "s" '(evil-window-vsplit :which-key "Split Vertical")
    "v" '(evil-window-split :which-key "Split Horizontal")

    ;; Buffer management
    "q" '(kill-current-buffer :which-key "Close Buffer")

    ;; Elisp Eval
    "e" '(:ignore t :which-key "Eval/Reload")
    "eb" '(eval-buffer :which-key "Eval Buffer (Live Reload)")
    "ee" '(eval-last-sexp :which-key "Eval Expression")
    "er" '(eval-region :which-key "Eval Region")
    "ed" '(eval-defun :which-key "Eval Defun/Function")))

(provide 'evil-keys)
