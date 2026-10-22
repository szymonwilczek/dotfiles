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

  (define-key evil-normal-state-map [escape] #'evil-ex-nohighlight)
  (define-key evil-normal-state-map "zc" 'hs-toggle-hiding)
  (define-key evil-normal-state-map "za" 'hs-show-block)

  ;; Window navigation without the C-w prefix
  (define-key evil-normal-state-map (kbd "C-h") #'evil-window-left)
  (define-key evil-normal-state-map (kbd "C-j") #'evil-window-down)
  (define-key evil-normal-state-map (kbd "C-k") #'evil-window-up)
  (define-key evil-normal-state-map (kbd "C-l") #'evil-window-right)

  ;; Avy jumps
  (define-key evil-normal-state-map "s" #'evil-avy-goto-char-2)
  (define-key evil-visual-state-map "s" #'evil-avy-goto-char-2)
  (define-key evil-operator-state-map "z" #'my/evil-avy-goto-char-2)
  (define-key evil-motion-state-map "gl" #'my/evil-avy-goto-line)

  ;; Number increment / decrement, repeating while held
  (dolist (map (list evil-normal-state-map evil-visual-state-map))
    (define-key map "+" #'evil-numbers/inc-at-pt)
    (define-key map "-" #'evil-numbers/dec-at-pt))

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
    "m" '(my/window-maximize-toggle :which-key "Maximize Window / Restore")

    ;; Buffer management
    "q" '(kill-current-buffer :which-key "Close Buffer")

    ;; Elisp Eval
    "e" '(:ignore t :which-key "Eval/Reload")
    "eb" '(eval-buffer :which-key "Eval Buffer (Live Reload)")
    "ee" '(eval-last-sexp :which-key "Eval Expression")
    "er" '(eval-region :which-key "Eval Region")
    "ed" '(eval-defun :which-key "Eval Defun/Function")))

(defun my/evil-collection-free-window-keys (mode &rest _)
  "Give C-j and C-k back to window navigation after MODE is set up."
  (when (eq mode 'outline)
    (let ((map (evil-get-auxiliary-keymap outline-mode-map 'normal)))
      (define-key map (kbd "C-j") nil t)
      (define-key map (kbd "C-k") nil t))))

(add-hook 'evil-collection-setup-hook #'my/evil-collection-free-window-keys)

(defun my/window-maximize-toggle ()
  "Show the selected window alone, or bring back the layout it left.
The layout is kept per frame, so each frame restores its own."
  (interactive)
  (let ((saved (frame-parameter nil 'my/maximize-layout)))
    (cond
     (saved
      (set-frame-parameter nil 'my/maximize-layout nil)
      (set-window-configuration saved))
     ((one-window-p)
      (message "Only one window"))
     (t
      (set-frame-parameter nil 'my/maximize-layout (current-window-configuration))
      (delete-other-windows)))))

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

;; Tree-sitter motions
(defmacro my/define-tree-sitter-motion (name group previous end)
  "Define the evil motion NAME to the start or END of the GROUP text object.
PREVIOUS searches backward instead of forward."
  `(evil-define-motion ,name (count)
     ,(format "Go to the %s of the %s %s, COUNT times."
              (if end "end" "start")
              (if previous "previous" "next")
              group)
     :jump t
     :type ,(if end 'inclusive 'exclusive)
     (dotimes (_ (or count 1))
       (evil-textobj-tree-sitter-goto-textobj ,group ,previous ,end))))

(my/define-tree-sitter-motion my/next-function-start "function.outer" nil nil)
(my/define-tree-sitter-motion my/previous-function-start "function.outer" t nil)
(my/define-tree-sitter-motion my/next-function-end "function.outer" nil t)
(my/define-tree-sitter-motion my/previous-function-end "function.outer" t t)
(my/define-tree-sitter-motion my/next-argument "parameter.inner" nil nil)
(my/define-tree-sitter-motion my/previous-argument "parameter.inner" t nil)
(my/define-tree-sitter-motion my/next-loop "loop.outer" nil nil)
(my/define-tree-sitter-motion my/previous-loop "loop.outer" t nil)

(with-eval-after-load 'evil
  (evil-define-key '(normal visual operator) 'global
    "]f" #'my/next-function-start
    "[f" #'my/previous-function-start
    "]F" #'my/next-function-end
    "[F" #'my/previous-function-end
    "]a" #'my/next-argument
    "[a" #'my/previous-argument
    "]l" #'my/next-loop
    "[l" #'my/previous-loop))

(with-eval-after-load 'evil-collection-unimpaired
  (evil-define-key 'normal evil-collection-unimpaired-mode-map
    "]l" #'my/next-loop
    "[l" #'my/previous-loop))

;; which-key names for evil because what the fuck am I supposed to
;; know by this cluttered dashboard
(defvar my/which-key-evil-labels
  '(;; g
    ("evil-goto-first-line" . "First Line")
    ("evil-goto-last-change" . "Last Change")
    ("evil-goto-last-change-reverse" . "Newer Change")
    ("evil-goto-definition" . "Definition")
    ("xref-find-definitions" . "Definition")
    ("xref-find-references" . "References")
    ("eglot-find-declaration" . "Declaration")
    ("eglot-find-implementation" . "Implementation")
    ("evil-next-visual-line" . "Down a Screen Line")
    ("evil-previous-visual-line" . "Up a Screen Line")
    ("evil-beginning-of-visual-line" . "Start of Screen Line")
    ("evil-end-of-visual-line" . "End of Screen Line")
    ("evil-first-non-blank-of-visual-line" . "First Char of Screen Line")
    ("evil-middle-of-visual-line" . "Middle of Screen Line")
    ("evil-last-non-blank" . "Last Char of Line")
    ("evil-percentage-of-line" . "Go to % of Line")
    ("evil-goto-char" . "Go to Char Offset")
    ("evil-backward-word-end" . "End of Previous word")
    ("evil-backward-WORD-end" . "End of Previous WORD")
    ("evil-search-unbounded-word-forward" . "Search Word Part Forward")
    ("evil-search-unbounded-word-backward" . "Search Word Part Backward")
    ("evil-next-match" . "Select Next Match")
    ("evil-previous-match" . "Select Previous Match")
    ("evil-visual-restore" . "Reselect Last Selection")
    ("evil-insert-0-line" . "Insert at Column 0")
    ("evil-join-whitespace" . "Join Without Space")
    ("evil-paste-after-cursor-after" . "Paste After, Cursor Past It")
    ("evil-paste-before-cursor-after" . "Paste Before, Cursor Past It")
    ("evil-upcase" . "Uppercase")
    ("evil-downcase" . "Lowercase")
    ("evil-invert-case" . "Swap Case")
    ("evil-fill" . "Rewrap")
    ("evil-fill-and-move" . "Rewrap and Move")
    ("evil-commentary" . "Comment")
    ("evil-commentary-yank" . "Yank and Comment")
    ("evil-ex-repeat-global-substitute" . "Repeat :s on Every Line")
    ("find-file-at-point" . "Open File at Point")
    ("evil-find-file-at-point-with-line" . "Open File at Point, at Line")
    ("browse-url-at-point" . "Open URL at Point")
    ("my/evil-avy-goto-line" . "Jump to Line (avy)")
    ("evil-collection-elisp-mode-ielm-repl" . "Elisp REPL")
    ;; z
    ("evil-scroll-line-to-top" . "Line to Top")
    ("evil-scroll-line-to-center" . "Line to Center")
    ("evil-scroll-line-to-bottom" . "Line to Bottom")
    ("hs-toggle-hiding" . "Toggle Fold")
    ("hs-show-block" . "Unfold Block")
    ("hs-hide-level" . "Fold Children")
    ("evil-open-fold" . "Unfold")
    ("evil-open-fold-rec" . "Unfold Recursively")
    ("evil-open-folds" . "Unfold All")
    ("evil-close-folds" . "Fold All")
    ("ispell-word" . "Spelling of Word")
    ;; [ and ]
    ("bufferline-prev-tab" . "Previous Tab")
    ("bufferline-next-tab" . "Next Tab")
    ("bufferline-move-tab-to-window-left" . "Tab to Left Window")
    ("bufferline-move-tab-to-window-right" . "Tab to Right Window")
    ("my/previous-function-start" . "Previous Function")
    ("my/next-function-start" . "Next Function")
    ("my/previous-function-end" . "Previous Function End")
    ("my/next-function-end" . "Next Function End")
    ("my/previous-argument" . "Previous Argument")
    ("my/next-argument" . "Next Argument")
    ("my/previous-loop" . "Previous Loop")
    ("my/next-loop" . "Next Loop")
    ("my/goto-prev-diagnostic" . "Previous Diagnostic")
    ("my/goto-next-diagnostic" . "Next Diagnostic")
    ("git-gutter:previous-hunk" . "Previous Git Hunk")
    ("git-gutter:next-hunk" . "Next Git Hunk")
    ("my/git-conflict-prev" . "Previous Conflict")
    ("my/git-conflict-next" . "Next Conflict")
    ("evil-prev-flyspell-error" . "Previous Misspelling")
    ("evil-next-flyspell-error" . "Next Misspelling")
    ("evil-previous-mark" . "Previous Mark")
    ("evil-next-mark" . "Next Mark")
    ("evil-previous-open-paren" . "Enclosing (")
    ("evil-next-close-paren" . "Enclosing )")
    ("evil-previous-open-brace" . "Enclosing {")
    ("evil-next-close-brace" . "Enclosing }")
    ("evil-collection-unimpaired-insert-newline-above" . "Blank Line Above")
    ("evil-collection-unimpaired-insert-newline-below" . "Blank Line Below")
    ("evil-collection-unimpaired-paste-above" . "Paste Line Above")
    ("evil-collection-unimpaired-paste-below" . "Paste Line Below")
    ("evil-collection-unimpaired-move-text-up" . "Move Line Up")
    ("evil-collection-unimpaired-move-text-down" . "Move Line Down")
    ("evil-collection-unimpaired-previous-error" . "Previous Error")
    ("evil-collection-unimpaired-next-error" . "Next Error")
    ("evil-collection-unimpaired-first-error" . "First Error")
    ("evil-collection-unimpaired-last-error" . "Last Error"))
  "Short which-key names for evil commands, by command name.")

(defvar my/which-key-evil-hidden
  '(;; duplicates of keys listed under another name
    "evil-scroll-line-to-top-first-non-blank"
    "evil-scroll-line-to-center-first-non-blank"
    "evil-scroll-line-to-bottom-first-non-blank"
    "evil-collection-unimpaired-previous-SCM-conflict-marker"
    "evil-collection-unimpaired-next-SCM-conflict-marker"
    "evil-previous-mark-line"
    "evil-next-mark-line"
    ;; horizontal scrolling, wrapped lines never need it
    "evil-scroll-column-left" "evil-scroll-column-right"
    "evil-scroll-left" "evil-scroll-right"
    "evil-scroll-start-column" "evil-scroll-end-column"
    "evil-scroll-bottom-line-to-top" "evil-scroll-top-line-to-bottom"
    ;; tab-bar and tags, unused next to bufferline and xref
    "evil-tab-next" "tab-bar-switch-to-prev-tab" "evil-jump-to-tag"
    "evil-backward-section-begin" "evil-backward-section-end"
    "evil-forward-section-begin" "evil-forward-section-end"
    "evil-rot13" "what-cursor-position"
    "evil-collection-unimpaired-b64-encode" "evil-collection-unimpaired-b64-decode"
    "evil-collection-unimpaired-url-encode" "evil-collection-unimpaired-url-decode")
  "Evil commands which-key leaves out of its popup.")

(with-eval-after-load 'which-key
  (setq which-key-replacement-alist
        (append
         (mapcar (lambda (label)
                   (cons (cons nil (concat "\\`" (regexp-quote (car label)) "\\'"))
                         (cons nil (cdr label))))
                 my/which-key-evil-labels)
         (mapcar (lambda (command)
                   (cons (cons nil (concat "\\`" (regexp-quote command) "\\'")) t))
                 my/which-key-evil-hidden)
         ;; anything left keeps its name without the package prefix
         '(((nil . "\\`evil-collection-unimpaired-") . (nil . ""))
           ((nil . "\\`evil-") . (nil . "")))
         which-key-replacement-alist)))

(provide 'evil-keys)
