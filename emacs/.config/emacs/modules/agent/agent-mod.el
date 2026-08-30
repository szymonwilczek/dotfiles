;;; AI Agents integration -*- lexical-binding: t; -*-

(require 'cl-lib)

(defvar my/agent-split-ratio 0.55
  "Ratio of the main (left) window width when opening an AI agent split.")

(defvar my/agent-active-name "Antigravity"
  "Name of the last activated AI agent.")

(defvar-local my/agent-buffer-p nil
  "Non-nil when current buffer is an AI agent terminal.")

(defun my/agent-get-or-create-window ()
  "Get or create a dedicated right-hand split window."
  (let* ((all-wins (window-list))
         (agent-win (cl-find-if (lambda (w)
                                  (let ((b (window-buffer w)))
                                    (or (buffer-local-value 'my/agent-buffer-p b)
                                        (string-match-p "\\*agent-" (buffer-name b)))))
                                all-wins)))
    (or agent-win
        (let* ((root (frame-root-window))
               (target-width (max 20 (floor (* (window-total-width root) my/agent-split-ratio))))
               (new-win (split-window root target-width 'right)))
          new-win))))

(defun my/agent-open (name command-name &optional args)
  "Open or switch to AI agent NAME running COMMAND-NAME in right split."
  (require 'ghostel)
  (setq my/agent-active-name name)
  (let* ((buf-name (format "*agent-%s*" (downcase (replace-regexp-in-string "[^a-zA-Z0-9]" "-" name))))
         (cmd (or (executable-find command-name)
                  (executable-find (expand-file-name command-name "~/.local/bin"))
                  (executable-find (expand-file-name command-name "~/.npm-global/bin"))
                  command-name))
         (existing (get-buffer buf-name))
         (right-win (my/agent-get-or-create-window)))
    (select-window right-win)
    (if (and existing (buffer-live-p existing) (get-buffer-process existing))
        (switch-to-buffer existing)
      (let ((buf (get-buffer-create buf-name)))
        (switch-to-buffer buf)
        (let ((process-environment (append '("TERM=xterm-256color") process-environment))
              (exec-path (append (list (expand-file-name "~/.local/bin")
                                       (expand-file-name "~/.npm-global/bin"))
                                 exec-path)))
          (ghostel-exec buf cmd args))
        (with-current-buffer buf
          (setq-local my/agent-buffer-p t)
          (setq-local ghostel-buffer-name-function nil)
          (setq-local display-line-numbers nil)
          (display-line-numbers-mode -1))))))

;; Auto-close split window on agent exit
(defun my/agent-cleanup-on-exit (buf _event)
  "Close the agent split window when process exits."
  (when (and buf (buffer-live-p buf))
    (when (or (buffer-local-value 'my/agent-buffer-p buf)
              (string-match-p "\\*agent-" (buffer-name buf)))
      (let ((win (get-buffer-window buf t)))
        (run-at-time 0 nil
                     (lambda ()
                       ;; Delete window
                       (when (and win (window-live-p win) (not (one-window-p t)))
                         (delete-window win))
                       ;; Kill the agent buffer cleanly
                       (when (and buf (buffer-live-p buf))
                         (kill-buffer buf))))))))

(with-eval-after-load 'ghostel
  (add-hook 'ghostel-exit-functions #'my/agent-cleanup-on-exit))

(defun my/agent-shell-gemini ()
  "Start or switch to Antigravity in right split."
  (interactive)
  (my/agent-open "Antigravity" "agy"))

(defun my/agent-shell-claude ()
  "Start or switch to Claude Code in right split."
  (interactive)
  (my/agent-open "Claude" "claude"))

(defun my/agent-shell-codex ()
  "Start or switch to OpenAI Codex in right split."
  (interactive)
  (my/agent-open "Codex" "codex"))

(defun my/agent-shell-select ()
  "Interactively choose from the AI agents and open in right split."
  (interactive)
  (let* ((choices '("Antigravity" "Claude Code" "OpenAI Codex"))
         (choice (completing-read "Select AI Agent: " choices nil t)))
    (pcase choice
      ("Antigravity"  (my/agent-shell-gemini))
      ("Claude Code"  (my/agent-shell-claude))
      ("OpenAI Codex" (my/agent-shell-codex)))))

(defun my/agent-shell-toggle ()
  "Toggle visibility of active agent split."
  (interactive)
  (let* ((all-wins (window-list))
         (agent-win (cl-find-if (lambda (w)
                                  (let ((b (window-buffer w)))
                                    (or (buffer-local-value 'my/agent-buffer-p b)
                                        (string-match-p "\\*agent-" (buffer-name b)))))
                                all-wins)))
    (if agent-win
        (delete-window agent-win)
      (pcase my/agent-active-name
        ("Claude"   (my/agent-shell-claude))
        ("Codex"    (my/agent-shell-codex))
        (_          (my/agent-shell-gemini))))))

(require 'agent-keys)

(provide 'agent-mod)
