;;; Ghostel terminal configuration with libghostty -*- lexical-binding: t; -*-

(let ((ghostel-lisp (expand-file-name "elpa/ghostel/lisp" user-emacs-directory))
      (evil-ghostel-dir (expand-file-name "elpa/ghostel/extensions/evil-ghostel" user-emacs-directory)))
  (when (file-directory-p ghostel-lisp)
    (add-to-list 'load-path ghostel-lisp))
  (when (file-directory-p evil-ghostel-dir)
    (add-to-list 'load-path evil-ghostel-dir)))

(defun my/ghostel-paste-clipboard ()
  "Paste system clipboard into Ghostel terminal using bracketed paste."
  (interactive)
  (let ((text (or (gui-get-selection 'CLIPBOARD)
                  (gui-get-primary-selection)
                  (current-kill 0 t))))
    (when text
      (ghostel-paste-string text))))

(defvar my/ghostel-double-escape-timeout 0.35
  "Timeout in seconds to distinguish single ESC (terminal) from double ESC (evil normal).")

(defvar-local my/ghostel-last-escape-time 0
  "Timestamp of the last ESC keystroke in the buffer.")

(defun my/ghostel-escape-dwim ()
  "If pressed once, send ESC to terminal; if pressed twice quickly, enter Evil Normal mode."
  (interactive)
  (let ((now (float-time)))
    (if (< (- now my/ghostel-last-escape-time) my/ghostel-double-escape-timeout)
        (progn
          (setq my/ghostel-last-escape-time 0)
          (evil-normal-state)
          (message "-- NORMAL --"))
      (setq my/ghostel-last-escape-time now)
      (ghostel--on-user-input)
      (ghostel--send-encoded "escape" ""))))

(use-package ghostel
  :ensure nil
  :commands (ghostel ghostel-project)
  :init
  ;; so window switching and toggle work in all states
  (with-eval-after-load 'ghostel
    (dolist (key '("C-w" "M-f"))
      (unless (member key ghostel-keymap-exceptions)
        (setq ghostel-keymap-exceptions (append (list key) ghostel-keymap-exceptions)))))
  :config
  (setq ghostel-color-palette nil)
  (setq ghostel-scrollback-size 10000)

  ;; Rebuild semi-char map with exceptions
  (ghostel--rebuild-semi-char-keymap)

  ;; Window switching inside ghostel terminal
  (with-eval-after-load 'evil
    (define-key ghostel-mode-map (kbd "C-w") evil-window-map)
    (define-key ghostel-semi-char-mode-map (kbd "C-w") evil-window-map))

  ;; Clipboard paste via Ctrl+Shift+V in all terminal maps
  (dolist (map (list ghostel-mode-map ghostel-semi-char-mode-map))
    (define-key map (kbd "C-S-v") #'my/ghostel-paste-clipboard)
    (define-key map (kbd "C-S-V") #'my/ghostel-paste-clipboard)
    (define-key map [C-S-v]       #'my/ghostel-paste-clipboard)
    (define-key map [C-S-V]       #'my/ghostel-paste-clipboard))

  ;; Clean terminal buffer setup
  (add-hook 'ghostel-mode-hook
            (lambda ()
              (display-line-numbers-mode -1)
              (setq-local global-hl-line-mode nil)
              (setq-local scroll-margin 0)
              (when-let* ((proc (get-buffer-process (current-buffer))))
                (set-process-query-on-exit-flag proc nil))))

  ;; Auto-close window when shell process terminates
  (defun my/ghostel-auto-close-on-exit (buf _event)
    "Close terminal buffer and split window when process exits."
    (when (and buf (buffer-live-p buf))
      (unless (or (buffer-local-value 'my/agent-buffer-p buf)
                  (string-match-p "\\*agent-" (buffer-name buf)))
        (let ((win (get-buffer-window buf t)))
          (run-at-time 0 nil
                       (lambda ()
                         (when (and win (window-live-p win) (not (one-window-p t)))
                           (delete-window win))
                         (when (and buf (buffer-live-p buf))
                           (kill-buffer buf))))))))

  (add-hook 'ghostel-exit-functions #'my/ghostel-auto-close-on-exit))

;; Evil integration for Ghostel
(defun my/ghostel-insert-dwim ()
  "Enter insert state at point, driving the terminal cursor to match across multiple lines."
  (interactive)
  (let ((target (point)))
    (when (and (derived-mode-p 'ghostel-mode)
               (bound-and-true-p ghostel--term)
               (bound-and-true-p ghostel--cursor-pos))
      (evil-ghostel-goto-input-position target))
    (evil-insert-state 1)))

(defun my/ghostel-append-dwim ()
  "Append after point, driving the terminal cursor to match across multiple lines."
  (interactive)
  (let ((target (save-excursion
                  (if (eolp) (point) (min (1+ (point)) (line-end-position))))))
    (when (and (derived-mode-p 'ghostel-mode)
               (bound-and-true-p ghostel--term)
               (bound-and-true-p ghostel--cursor-pos))
      (evil-ghostel-goto-input-position target))
    (evil-insert-state 1)))

(defun my/ghostel-insert-line-dwim ()
  "Move to start of current line and enter insert."
  (interactive)
  (let ((target (save-excursion
                  (back-to-indentation)
                  (point))))
    (when (and (derived-mode-p 'ghostel-mode)
               (bound-and-true-p ghostel--term)
               (bound-and-true-p ghostel--cursor-pos))
      (evil-ghostel-goto-input-position target))
    (evil-insert-state 1)))

(defun my/ghostel-append-line-dwim ()
  "Move to end of current line and enter insert."
  (interactive)
  (let ((target (save-excursion
                  (end-of-line)
                  (skip-chars-backward " \t" (line-beginning-position))
                  (point))))
    (when (and (derived-mode-p 'ghostel-mode)
               (bound-and-true-p ghostel--term)
               (bound-and-true-p ghostel--cursor-pos))
      (evil-ghostel-goto-input-position target))
    (evil-insert-state 1)))

(use-package evil-ghostel
  :ensure nil
  :after (ghostel evil)
  :hook (ghostel-mode . evil-ghostel-mode)
  :config
  (setq evil-ghostel-initial-state 'insert)
  (evil-set-initial-state 'ghostel-mode 'insert)

  ;; Window switching in evil-ghostel states
  (evil-define-key* '(insert normal visual motion emacs) evil-ghostel-mode-map
    (kbd "C-w") evil-window-map)

  ;; Ctrl+Shift+V for pasting
  (evil-define-key* '(insert normal visual motion emacs) evil-ghostel-mode-map
    (kbd "C-S-v") #'my/ghostel-paste-clipboard
    (kbd "C-S-V") #'my/ghostel-paste-clipboard
    [C-S-v]       #'my/ghostel-paste-clipboard
    [C-S-V]       #'my/ghostel-paste-clipboard)

  ;; Double-ESC in insert state
  (evil-define-key* 'insert evil-ghostel-mode-map
    (kbd "<escape>") #'my/ghostel-escape-dwim
    [escape]         #'my/ghostel-escape-dwim)

  ;; Multiline-aware cursor positioning
  (evil-define-key* '(normal visual motion) evil-ghostel-mode-map
    [remap evil-insert]      #'my/ghostel-insert-dwim
    [remap evil-append]      #'my/ghostel-append-dwim
    [remap evil-insert-line] #'my/ghostel-insert-line-dwim
    [remap evil-append-line] #'my/ghostel-append-line-dwim
    "i"                      #'my/ghostel-insert-dwim
    "a"                      #'my/ghostel-append-dwim
    "I"                      #'my/ghostel-insert-line-dwim
    "A"                      #'my/ghostel-append-line-dwim)

  ;; Fix upstream evil-ghostel nil cursor position bug
  ;; and prevent snapping back to cursor row
  (defun my/evil-ghostel-safe-insert-state-entry (_orig-fn &rest _args)
    "Safely drive terminal cursor to target point without snapping back to end of buffer."
    (when (and (derived-mode-p 'ghostel-mode)
               (bound-and-true-p ghostel--cursor-pos)
               (cdr ghostel--cursor-pos)
               (numberp (cdr ghostel--cursor-pos)))
      (evil-ghostel-goto-input-position (point))))

  (advice-add 'evil-ghostel--insert-state-entry :around #'my/evil-ghostel-safe-insert-state-entry))

;; Dedicated bottom popup terminal
(defvar my/ghostel-bottom-buffer-name "*ghostel-bottom*"
  "Buffer name used for the dedicated bottom popup terminal.")

(defvar-local my/ghostel-bottom-buffer-p nil
  "Non-nil when current buffer is the dedicated bottom popup terminal.")

(defun my/ghostel-get-bottom-buffer ()
  "Return the dedicated bottom Ghostel buffer if live, otherwise nil.
If the buffer exists but its process died, kill the stale buffer."
  (let ((buf (get-buffer my/ghostel-bottom-buffer-name)))
    (when (and buf (buffer-live-p buf))
      (let ((proc (get-buffer-process buf)))
        (if (and proc (process-live-p proc))
            buf
          (kill-buffer buf)
          nil)))))

(defun my/ghostel-create-bottom-buffer ()
  "Create, configure, and start a fresh Ghostel process for the bottom terminal."
  (when-let* ((old (get-buffer my/ghostel-bottom-buffer-name)))
    (when (buffer-live-p old)
      (kill-buffer old)))
  (let ((buf (get-buffer-create my/ghostel-bottom-buffer-name)))
    (with-current-buffer buf
      (setq-local my/ghostel-bottom-buffer-p t)
      (setq-local ghostel-buffer-name-function nil)
      (setq-local display-line-numbers nil)
      (display-line-numbers-mode -1)
      (setq-local global-hl-line-mode nil)
      (setq-local scroll-margin 0))
    (let ((process-environment (append '("TERM=xterm-256color") process-environment)))
      (ghostel-exec buf (or (getenv "SHELL") "/bin/bash")))
    (with-current-buffer buf
      (setq-local my/ghostel-bottom-buffer-p t)
      (when-let* ((proc (get-buffer-process buf)))
        (set-process-query-on-exit-flag proc nil)))
    buf))

(defun my/ghostel-toggle-bottom ()
  "Toggle Ghostel terminal window."
  (interactive)
  (let* ((bot-buf (my/ghostel-get-bottom-buffer))
         (bot-win (and bot-buf (get-buffer-window bot-buf t))))
    (cond
     ;; Bottom terminal window is currently focused -> hide it
     ((and bot-win (eq bot-win (selected-window)))
      (delete-window bot-win))

     ;; Bottom terminal window is visible but not focused -> focus it
     (bot-win
      (select-window bot-win)
      (when (fboundp 'evil-insert-state)
        (evil-insert-state 1)))

     ;; Bottom terminal buffer exists and is live -> display it at bottom
     (bot-buf
      (let ((new-win (display-buffer-at-bottom bot-buf '((window-height . 0.38)))))
        (when new-win
          (select-window new-win)
          (when (fboundp 'evil-insert-state)
            (evil-insert-state 1)))))

     ;; No live bottom terminal -> spawn fresh process and display at bottom
     (t
      (let* ((new-buf (my/ghostel-create-bottom-buffer))
             (new-win (display-buffer-at-bottom new-buf '((window-height . 0.38)))))
        (when new-win
          (select-window new-win)
          (when (fboundp 'evil-insert-state)
            (evil-insert-state 1))))))))

(defun my/ghostel-open-full-buffer ()
  "Open Ghostel as a dedicated full buffer."
  (interactive)
  (let ((buf (ghostel t)))
    (switch-to-buffer buf)))

(require 'terminal-keys)

(provide 'terminal-mod)
