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

  ;; Avy jumps
  (define-key evil-normal-state-map "s" #'evil-avy-goto-char-2)
  (define-key evil-visual-state-map "s" #'evil-avy-goto-char-2)
  (define-key evil-operator-state-map "z" #'my/evil-avy-goto-char-2)
  (define-key evil-motion-state-map "gl" #'my/evil-avy-goto-line)

  ;; Window navigation
  (define-key evil-normal-state-map (kbd "C-w h") 'evil-window-left)
  (define-key evil-normal-state-map (kbd "C-w j") 'evil-window-down)
  (define-key evil-normal-state-map (kbd "C-w k") 'evil-window-up)
  (define-key evil-normal-state-map (kbd "C-w l") 'evil-window-right)

  ;; Number increment / decrement
  (define-key evil-normal-state-map (kbd "C-c +") #'evil-numbers/inc-at-pt)
  (define-key evil-normal-state-map (kbd "C-c =") #'evil-numbers/inc-at-pt)
  (define-key evil-normal-state-map (kbd "C-c -") #'evil-numbers/dec-at-pt)
  (define-key evil-visual-state-map (kbd "C-c +") #'evil-numbers/inc-at-pt)
  (define-key evil-visual-state-map (kbd "C-c =") #'evil-numbers/inc-at-pt)
  (define-key evil-visual-state-map (kbd "C-c -") #'evil-numbers/dec-at-pt)

  ;; Ctrl+Backspace to delete whole word backward
  (global-set-key (kbd "C-<backspace>") #'backward-kill-word)
  (global-set-key [C-backspace]         #'backward-kill-word)
  (global-set-key (kbd "<C-backspace>") #'backward-kill-word)

  (dolist (state '(insert normal visual motion emacs replace))
    (evil-global-set-key state (kbd "C-<backspace>") #'backward-kill-word)
    (evil-global-set-key state [C-backspace]         #'backward-kill-word)
    (evil-global-set-key state (kbd "<C-backspace>") #'backward-kill-word))

  (define-key minibuffer-local-map (kbd "C-<backspace>") #'backward-kill-word)
  (define-key minibuffer-local-map [C-backspace]         #'backward-kill-word)

  ;; Base Leader Bindings
  (my-leader-def
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

(defun my/evil-avy-jump-or-abort (motion count)
  "Run the avy MOTION with COUNT, signalling an error when it does not jump.
Otherwise an operator would act on the text at point when there is no
match or the labels are dismissed."
  (let ((start (point))
        (window (selected-window)))
    (funcall motion count)
    (when (and (= (point) start) (eq (selected-window) window))
      (user-error "No jump"))))

(evil-define-motion my/evil-avy-goto-char-2 (count)
  "Like `evil-avy-goto-char-2', but abort when avy does not jump."
  :type inclusive
  :jump t
  :repeat abort
  (my/evil-avy-jump-or-abort #'evil-avy-goto-char-2 count))

(evil-define-motion my/evil-avy-goto-line (count)
  "Like `evil-avy-goto-line', but abort when avy does not jump."
  :type line
  :jump t
  :repeat abort
  (my/evil-avy-jump-or-abort #'evil-avy-goto-line count))

(defun my/indent-or-insert-tab ()
  "Indent the current line, or insert a tab when it is already indented."
  (interactive)
  (if (use-region-p)
      (call-interactively #'indent-for-tab-command)
    (let ((tick (buffer-chars-modified-tick))
          (pt (point)))
      (call-interactively #'indent-for-tab-command)
      (when (and (= tick (buffer-chars-modified-tick)) (= pt (point)))
        (if (and indent-tabs-mode
                 (save-excursion (skip-chars-backward " \t") (bolp)))
            (insert "\t")
          (let ((width (if (or indent-tabs-mode (not (boundp 'evil-shift-width)))
                           tab-width
                         evil-shift-width)))
            (insert (make-string (- width (% (current-column) width)) ?\s))))))))

(global-set-key [remap indent-for-tab-command] #'my/indent-or-insert-tab)
(evil-define-text-object my/evil-an-argument (count &optional beg end type)
  "Select an argument together with the comma separating it from the next.
The last argument takes the comma before it instead."
  (let* ((range (evil-textobj-tree-sitter-function--parameter.inner
                 count beg end type))
         (beg (evil-range-beginning range))
         (end (evil-range-end range)))
    (save-excursion
      (goto-char end)
      (skip-chars-forward " \t")
      (if (eq (char-after) ?,)
          (progn
            (forward-char)
            (skip-chars-forward " \t")
            (setq end (point)))
        (goto-char beg)
        (skip-chars-backward " \t\n")
        (when (eq (char-before) ?,)
          (setq beg (1- (point))))))
    (evil-range beg end)))

;; Tree-sitter text objects after a or i
(with-eval-after-load 'evil-textobj-tree-sitter
  (define-key evil-outer-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.outer"))
  (define-key evil-inner-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.inner"))
  (define-key evil-inner-text-objects-map "a" (evil-textobj-tree-sitter-get-textobj "parameter.inner"))
  (define-key evil-outer-text-objects-map "a" #'my/evil-an-argument)
  (define-key evil-outer-text-objects-map "c" (evil-textobj-tree-sitter-get-textobj "class.outer"))
  (define-key evil-inner-text-objects-map "c" (evil-textobj-tree-sitter-get-textobj "class.inner"))
  (define-key evil-outer-text-objects-map "l" (evil-textobj-tree-sitter-get-textobj "loop.outer"))
  (define-key evil-inner-text-objects-map "l" (evil-textobj-tree-sitter-get-textobj "loop.inner"))
  (define-key evil-outer-text-objects-map "i" (evil-textobj-tree-sitter-get-textobj "conditional.outer"))
  (define-key evil-inner-text-objects-map "i" (evil-textobj-tree-sitter-get-textobj "conditional.inner"))
  (define-key evil-outer-text-objects-map "/" (evil-textobj-tree-sitter-get-textobj "comment.outer")))

(provide 'evil-keys)
