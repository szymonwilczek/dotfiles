;;; AI Agents integration -*- lexical-binding: t; -*-

(require 'cl-lib)

(defvar my/agent-split-ratio 0.60
  "Ratio of the main (left) window width when opening an AI agent split.")

(defvar my/agent-active-name "Antigravity"
  "Name of the last activated AI agent.")

(defvar-local my/agent-buffer-p nil
  "Non-nil when current buffer is an AI agent terminal.")

(defun my/agent--display-buffer-condition (buf-name action)
  (and (not (string-prefix-p " " buf-name))
       (not (string-match-p "\\`\\*agent" buf-name))
       (not (assq 'side (cdr action)))
       (with-current-buffer (window-buffer (selected-window))
         (or (bound-and-true-p my/agent-buffer-p)
             (string-match-p "\\`\\*agent-" (buffer-name))))))

(add-to-list 'display-buffer-alist
             '(my/agent--display-buffer-condition
               (display-buffer-reuse-window display-buffer-use-some-window display-buffer-pop-up-window)
               (inhibit-same-window . t)))

(defun my/agent-get-or-create-window ()
  (let* ((all-wins (window-list nil 'no-minibuf))
         (agent-win (cl-find-if (lambda (w)
                                  (and (window-dedicated-p w)
                                       (let ((b (window-buffer w)))
                                         (or (buffer-local-value 'my/agent-buffer-p b)
                                             (string-match-p "\\`\\*agent-" (buffer-name b))))))
                                all-wins)))
    (if (and agent-win (not (one-window-p nil 'no-minibuf)))
        agent-win
      (when (one-window-p nil 'no-minibuf)
        (let ((sole-win (car all-wins)))
          (when (or (buffer-local-value 'my/agent-buffer-p (window-buffer sole-win))
                    (string-match-p "\\`\\*agent-" (buffer-name (window-buffer sole-win))))
            (set-window-dedicated-p sole-win nil)
            (set-window-parameter sole-win 'tab-line-format nil)
            (let ((fallback (or (cl-find-if (lambda (b)
                                              (and (not (string-prefix-p " " (buffer-name b)))
                                                   (not (string-match-p "\\`\\*agent-" (buffer-name b)))
                                                   (not (string-match-p "\\`\\*ghostel-bottom" (buffer-name b)))))
                                            (buffer-list))
                                (get-buffer-create "*scratch*"))))
              (set-window-buffer sole-win fallback)))))
      (let* ((root (frame-root-window))
             (target-width (max 20 (floor (* (window-total-width root) my/agent-split-ratio))))
             (new-win (split-window root target-width 'right)))
        (set-window-parameter new-win 'tab-line-format 'none)
        new-win))))

(defun my/agent--ghostel-buffer-name-fn (title)
  "Prevent ghostel from renaming agent buffers (*agent-*) on terminal TITLE updates."
  (if (or (bound-and-true-p my/agent-buffer-p)
          (string-prefix-p "*agent-" (buffer-name)))
      nil
    (and (fboundp 'ghostel-buffer-name-by-title)
         (ghostel-buffer-name-by-title title))))

(with-eval-after-load 'ghostel
  (setq ghostel-buffer-name-function #'my/agent--ghostel-buffer-name-fn))

(defun my/agent-buffer-name (name)
  "Return the buffer name of agent NAME for the current perspective.
Each perspective gets its own agent; without `persp-mode' there is one."
  (let ((base (downcase (replace-regexp-in-string "[^a-zA-Z0-9]" "-" name))))
    (if (bound-and-true-p persp-mode)
        (format "*agent-%s<%s>*" base (persp-current-name))
      (format "*agent-%s*" base))))

(defun my/agent-open (name command-name &optional args)
  "Open or switch to an agent buffer with NAME running COMMAND-NAME with ARGS.
Working directory is automatically set to the project root of the current buffer."
  (require 'ghostel)
  (setq my/agent-active-name name)
  (let* ((target-dir (my/project-root-dwim default-directory))
         (buf-name (my/agent-buffer-name name))
         (cmd (or (executable-find command-name)
                  (executable-find (expand-file-name command-name "~/.local/bin"))
                  (executable-find (expand-file-name command-name "~/.npm-global/bin"))
                  command-name))
         (existing (get-buffer buf-name))
         (right-win (my/agent-get-or-create-window)))
    (set-window-parameter right-win 'tab-line-format 'none)
    (set-window-dedicated-p right-win nil)
    (select-window right-win)
    (if (and existing
             (buffer-live-p existing)
             (or (get-buffer-process existing)
                 (with-current-buffer existing
                   (and (boundp 'ghostel--process) (process-live-p ghostel--process)))))
        (progn
          (set-window-buffer right-win existing)
          (set-window-dedicated-p right-win t))
      (let ((buf (get-buffer-create buf-name)))
        (set-window-buffer right-win buf)
        (with-current-buffer buf
          (setq default-directory target-dir)
          (setq-local ghostel-buffer-name-function nil)
          (setq-local my/agent-buffer-p t)
          (setq-local my/agent-type (downcase name))
          (setq-local display-line-numbers nil)
          (display-line-numbers-mode -1))
        (let ((process-environment (append '("TERM=xterm-256color") process-environment))
              (exec-path (append (list (expand-file-name "~/.local/bin")
                                       (expand-file-name "~/.npm-global/bin"))
                                 exec-path)))
          (ghostel-exec buf cmd args))
        (with-current-buffer buf
          (setq-local ghostel-buffer-name-function nil)
          (setq-local my/agent-buffer-p t)
          (setq-local my/agent-type (downcase name))
          (setq-local display-line-numbers nil)
          (display-line-numbers-mode -1)
          (unless (string= (buffer-name) buf-name)
            (rename-buffer buf-name t)))
        (set-window-dedicated-p right-win t)))
    (my/agent-update-usage-async)))

(defun my/agent-cleanup-on-exit (buf _event)
  (when (and buf (buffer-live-p buf))
    (when (or (buffer-local-value 'my/agent-buffer-p buf)
              (string-match-p "\\*agent-" (buffer-name buf)))
      (let ((win (get-buffer-window buf t)))
        (run-at-time 0 nil
                     (lambda ()
                       (when (and win (window-live-p win) (not (one-window-p t)))
                         (set-window-dedicated-p win nil)
                         (delete-window win))
                       (when (and buf (buffer-live-p buf))
                         (kill-buffer buf))))))))

(with-eval-after-load 'ghostel
  (add-hook 'ghostel-exit-functions #'my/agent-cleanup-on-exit))

(defun my/agent-shell-gemini ()
  "Start or switch to Antigravity in right split."
  (interactive)
  (my/agent-open "Antigravity" "agy"))

(defun my/agent-shell-claude ()
  "Start or switch to Claude Code in right split.
It runs with the inline renderer, so its output stays in the buffer's
scrollback; the fullscreen one from the settings is left for real
terminals."
  (interactive)
  (my/agent-open "Claude" "claude" '("--settings" "{\"tui\":\"default\"}")))

(defun my/agent-shell-select ()
  "Interactively choose from the AI agents and open in right split."
  (interactive)
  (let* ((choices '("Antigravity" "Claude Code"))
         (choice (completing-read "Select AI Agent: " choices nil t)))
    (pcase choice
      ("Antigravity" (my/agent-shell-gemini))
      ("Claude Code" (my/agent-shell-claude)))))

(defun my/agent-shell-toggle ()
  (interactive)
  (let* ((all-wins (window-list nil 'no-minibuf))
         (agent-win (cl-find-if (lambda (w)
                                  (and (window-dedicated-p w)
                                       (let ((b (window-buffer w)))
                                         (or (buffer-local-value 'my/agent-buffer-p b)
                                             (string-match-p "\\`\\*agent-" (buffer-name b))))))
                                all-wins)))
    (cond
     ((and agent-win (one-window-p nil 'no-minibuf))
      (set-window-dedicated-p agent-win nil)
      (set-window-parameter agent-win 'tab-line-format nil)
      (let ((fallback (or (cl-find-if (lambda (b)
                                        (and (not (string-prefix-p " " (buffer-name b)))
                                             (not (string-match-p "\\`\\*agent-" (buffer-name b)))
                                             (not (string-match-p "\\`\\*ghostel-bottom" (buffer-name b)))))
                                      (buffer-list))
                          (get-buffer-create "*scratch*"))))
        (set-window-buffer agent-win fallback)))
     (agent-win
      (set-window-dedicated-p agent-win nil)
      (delete-window agent-win))
     (t
      (pcase my/agent-active-name
        ("Claude" (my/agent-shell-claude))
        (_        (my/agent-shell-gemini)))))))

(defun my/agent-edit-prompt ()
  "Draft a prompt in a dedicated bottom split under the agent chat window.
Leaves the chat history visible above. Resizable via mouse / window splits.
Press C-c C-c to submit to the agent, or C-c C-k to cancel."
  (interactive)
  (let* ((orig-buf (current-buffer))
         (agent-win (selected-window)))
    (unless (or (buffer-local-value 'my/agent-buffer-p orig-buf)
                (string-match-p "\\*agent-" (buffer-name orig-buf)))
      (user-error "Current buffer is not an AI agent terminal"))
    ;; if prompt window is already open -> focus it
    (let* ((existing-buf (get-buffer "*agent-prompt*"))
           (existing-win (and existing-buf (get-buffer-window existing-buf t))))
      (if (and existing-win (window-live-p existing-win))
          (select-window existing-win)
        (let* ((split-height (max 7 (floor (* (window-total-height agent-win) 0.35))))
               (prompt-win (split-window agent-win (- split-height) 'below))
               (prompt-buf (get-buffer-create "*agent-prompt*")))
          (with-current-buffer prompt-buf
            (erase-buffer)
            (text-mode)
            (setq-local header-line-format
                        (propertize " [Prompt] C-c C-c: Submit | C-c C-k: Cancel | Drag border to resize "
                                    'face '(:weight bold :foreground "#268bd2")))
            (local-set-key (kbd "C-c C-c")
                           (lambda ()
                             (interactive)
                             (let ((text (buffer-string)))
                               (when (window-live-p (selected-window))
                                 (delete-window (selected-window)))
                               (when (get-buffer "*agent-prompt*")
                                 (kill-buffer "*agent-prompt*"))
                               (when (and (window-live-p agent-win) (buffer-live-p orig-buf))
                                 (select-window agent-win)
                                 (with-current-buffer orig-buf
                                   (when (and text (not (string-blank-p text)))
                                     (ghostel-paste-string (string-trim text))
                                     (ghostel--send-encoded "enter" "")))))))
            (local-set-key (kbd "C-c C-k")
                           (lambda ()
                             (interactive)
                             (when (window-live-p (selected-window))
                               (delete-window (selected-window)))
                             (when (get-buffer "*agent-prompt*")
                               (kill-buffer "*agent-prompt*"))
                             (when (and (window-live-p agent-win) (buffer-live-p orig-buf))
                               (select-window agent-win)))))
          (set-window-buffer prompt-win prompt-buf)
          (select-window prompt-win)
          (when (fboundp 'evil-insert-state)
            (evil-insert-state 1)))))))

(defvar-local my/agent-type nil
  "Type of the AI agent running in this buffer ('claude, 'antigravity).")

(defvar my/agent-claude-quota-data nil
  "Alist of Claude quota data: ((5h-util . N) (5h-reset . S) (7d-util . N) (7d-reset . S)).")

(defvar my/agent-antigravity-quota-data nil
  "Alist of Antigravity quota data for Gemini and 3P models.")

(defvar my/agent-usage-timer nil
  "Timer that refreshes agent usage every minute.")

(defun my/agent-buffer-type (&optional buffer)
  "Return agent type symbol for BUFFER ('claude, 'antigravity, etc.)."
  (let* ((buf (or buffer (current-buffer)))
         (name (downcase (buffer-name buf))))
    (with-current-buffer buf
      (or (and (bound-and-true-p my/agent-type) (intern (downcase (format "%s" my/agent-type))))
          (cond
           ((string-match-p "claude" name) 'claude)
           ((string-match-p "antigravity\\|agy" name) 'antigravity)
           ((or (bound-and-true-p my/agent-buffer-p)
                (string-match-p "\\*agent-" name))
            'generic)
           (t nil))))))


(defun my/agent--live-buffer-p (type)
  "Return non-nil if an agent buffer of TYPE ('claude, 'antigravity) is open with a live process."
  (cl-some (lambda (b)
             (when (eq (my/agent-buffer-type b) type)
               (and (buffer-live-p b)
                    (or (get-buffer-process b)
                        (with-current-buffer b
                          (and (boundp 'ghostel--process)
                               (process-live-p ghostel--process)))))))
           (buffer-list)))

(defun my/agent--get-claude-token ()
  "Extract current OAuth accessToken from ~/.claude/.credentials.json."
  (let ((cred-file (expand-file-name "~/.claude/.credentials.json")))
    (when (file-readable-p cred-file)
      (ignore-errors
        (let* ((json (json-parse-string (with-temp-buffer
                                          (insert-file-contents cred-file)
                                          (buffer-string))
                                        :object-type 'alist))
               (oauth (alist-get 'claudeAiOauth json)))
          (alist-get 'accessToken oauth))))))

(defun my/agent-claude-update-usage-async ()
  "Asynchronously fetch 5h and weekly usage from official Anthropic API."
  (when (and (my/agent--live-buffer-p 'claude)
             (not (process-live-p (get-process "agent-claude-usage-fetch"))))
    (let ((token (my/agent--get-claude-token)))
      (when token
        (make-process
         :name "agent-claude-usage-fetch"
         :buffer (generate-new-buffer " *agent-claude-usage-temp*")
         :command (list "curl" "-s" "-m" "5"
                        "-H" (format "Authorization: Bearer %s" token)
                        "-H" "User-Agent: claude-code"
                        "https://api.anthropic.com/api/oauth/usage")
         :sentinel (lambda (proc _event)
                     (when (eq (process-status proc) 'exit)
                       (unwind-protect
                           (when (= (process-exit-status proc) 0)
                             (with-current-buffer (process-buffer proc)
                               (goto-char (point-min))
                               (ignore-errors
                                 (let* ((json (json-parse-buffer :object-type 'alist :array-type 'list))
                                        (fh (alist-get 'five_hour json))
                                        (sd (alist-get 'seven_day json))
                                        (u5 (and fh (alist-get 'utilization fh)))
                                        (r5 (and fh (alist-get 'resets_at fh)))
                                        (u7 (and sd (alist-get 'utilization sd)))
                                        (r7 (and sd (alist-get 'resets_at sd))))
                                   (when (and u5 u7)
                                     (setq my/agent-claude-quota-data
                                           `((5h-util . ,(round u5))
                                             (5h-reset . ,r5)
                                             (7d-util . ,(round u7))
                                             (7d-reset . ,r7)))
                                     (force-mode-line-update t))))))
                         (when (buffer-live-p (process-buffer proc))
                           (kill-buffer (process-buffer proc)))))))))))

(defun my/agent-update-usage-async ()
  "Dispatch usage update for active agent types if any agent buffer is open."
  (when (my/agent--live-buffer-p 'claude)
    (my/agent-claude-update-usage-async)))

(unless my/agent-usage-timer
  (setq my/agent-usage-timer
        (run-with-timer 0 60 #'my/agent-update-usage-async)))

(defvar my/agent--last-focus-update-time 0
  "Timestamp of the last focus-triggered quota update to prevent flooding.")

(defun my/agent--on-focus-change (&optional frame-or-window)
  "Trigger instant single-shot quota refresh when focusing an agent buffer."
  (let* ((win (if (windowp frame-or-window) frame-or-window (selected-window)))
         (buf (and (window-live-p win) (window-buffer win)))
         (type (and buf (my/agent-buffer-type buf)))
         (now (float-time)))
    (when (and (eq type 'claude)
               (eq win (selected-window))
               (> (- now my/agent--last-focus-update-time) 2.0))
      (setq my/agent--last-focus-update-time now)
      (my/agent-claude-update-usage-async))))

(add-hook 'window-selection-change-functions #'my/agent--on-focus-change)

(defun my/agent-prevent-sole-ordinary-window-deletion (&optional window)
  (let ((win (or window (selected-window))))
    (unless (window-dedicated-p win)
      (let* ((all-wins (window-list nil 'no-minibuf))
             (has-dedicated (cl-some #'window-dedicated-p all-wins)))
        (when has-dedicated
          (let ((ordinary-wins (seq-filter (lambda (w) (not (window-dedicated-p w)))
                                           all-wins)))
            (when (and (memq win ordinary-wins)
                       (null (cdr ordinary-wins)))
              (user-error "Cannot delete sole ordinary window"))))))))

(advice-add 'delete-window :before #'my/agent-prevent-sole-ordinary-window-deletion)

(defun my/agent-prevent-dedicated-delete-other-windows (&optional window)
  (let ((win (or window (selected-window))))
    (when (window-dedicated-p win)
      (user-error "Cannot delete other windows from a dedicated window"))))

(advice-add 'delete-other-windows :before #'my/agent-prevent-dedicated-delete-other-windows)

(defun my/agent-skip-in-ordinary-windows (window buffer _bury-or-kill)
  (and (not (window-dedicated-p window))
       (or (buffer-local-value 'my/agent-buffer-p buffer)
           (string-match-p "\\`\\*agent-" (buffer-name buffer))
           (string-match-p "\\`\\*ghostel-bottom" (buffer-name buffer)))))

(setq switch-to-prev-buffer-skip #'my/agent-skip-in-ordinary-windows)

(require 'agent-keys)

(provide 'agent-mod)
