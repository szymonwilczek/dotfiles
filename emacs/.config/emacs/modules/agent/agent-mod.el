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
  "Open or switch to AI agent NAME running COMMAND-NAME in right split.
Working directory is automatically set to the project root of the current buffer."
  (require 'ghostel)
  (setq my/agent-active-name name)
  (let* ((target-dir (my/project-root-dwim default-directory))
         (buf-name (format "*agent-%s*" (downcase (replace-regexp-in-string "[^a-zA-Z0-9]" "-" name))))
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
        (with-current-buffer buf
          (setq default-directory target-dir)
          (setq-local my/agent-buffer-p t)
          (setq-local my/agent-type (downcase name))
          (setq-local ghostel-buffer-name-function nil)
          (setq-local display-line-numbers nil)
          (display-line-numbers-mode -1))
        (let ((process-environment (append '("TERM=xterm-256color") process-environment))
              (exec-path (append (list (expand-file-name "~/.local/bin")
                                       (expand-file-name "~/.npm-global/bin"))
                                 exec-path)))
          (ghostel-exec buf cmd args))))
    (my/agent-update-usage-async)))

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
  "Type of the AI agent running in this buffer ('claude, 'antigravity, 'codex).")

(defvar my/agent-claude-quota-data nil
  "Alist of Claude quota data: ((5h-util . N) (5h-reset . S) (7d-util . N) (7d-reset . S)).")

(defvar my/agent-antigravity-quota-data nil
  "Alist of Antigravity quota data for Gemini and 3P models.")

(defvar my/agent-usage-timer nil
  "Timer that refreshes agent usage every minute.")

(defun my/agent-buffer-type (&optional buffer)
  "Return agent type symbol for BUFFER ('claude, 'antigravity, 'codex, etc.)."
  (let* ((buf (or buffer (current-buffer)))
         (name (downcase (buffer-name buf))))
    (with-current-buffer buf
      (or (and (bound-and-true-p my/agent-type) (intern (downcase (format "%s" my/agent-type))))
          (cond
           ((string-match-p "claude" name) 'claude)
           ((string-match-p "antigravity\\|agy" name) 'antigravity)
           ((string-match-p "codex" name) 'codex)
           ((or (bound-and-true-p my/agent-buffer-p)
                (string-match-p "\\*agent-" name))
            'generic)
           (t nil))))))

(defun my/agent--format-reset-time (reset-str)
  "Format time remaining until RESET-STR as compact human-readable string."
  (if (or (null reset-str) (string-empty-p reset-str))
      ""
    (condition-case nil
        (let* ((target-time (parse-iso8601-time-string reset-str))
               (diff (ceiling (float-time (time-subtract target-time (current-time)))))
               (diff (max 0 diff)))
          (cond
           ((<= diff 0) "0m")
           ((< diff 3600) (format "%dm" (ceiling (/ diff 60.0))))
           ((< diff 86400)
            (let ((hours (/ diff 3600))
                  (mins (/ (% diff 3600) 60)))
              (if (> mins 0)
                  (format "%dh%dm" hours mins)
                (format "%dh" hours))))
           (t
            (let ((days (/ diff 86400))
                  (hours (/ (% diff 86400) 3600)))
              (if (> hours 0)
                  (format "%dd%dh" days hours)
                (format "%dd" days))))))
      (error ""))))

(defun my/agent--usage-face (pct)
  "Return face for usage PCT: <75 white, 75-89 yellow, >=90 red."
  (cond
   ((>= pct 90) '(:foreground "#e06c75" :weight bold))
   ((>= pct 75) '(:foreground "#e5c07b" :weight bold))
   (t '(:foreground "#ffffff" :weight bold))))

(defun my/agent--format-quota-item (label pct reset-str)
  "Format LABEL (white), PCT (threshold colored) and RESET-STR (comment face)."
  (let* ((lbl-face '(:foreground "#ffffff" :weight bold))
         (val-face (my/agent--usage-face (or pct 0)))
         (rst-str (my/agent--format-reset-time reset-str))
         (rst-part (if (string-empty-p rst-str)
                       ""
                     (concat " " (propertize (format "(%s)" rst-str)
                                             'face 'font-lock-comment-face)))))
    (concat (propertize label 'face lbl-face)
            " "
            (propertize (format "%d%%%%" (or pct 0)) 'face val-face)
            rst-part)))

(defun my/agent-render-usage (active &optional buffer)
  "Render formatted usage string for BUFFER depending on ACTIVE state."
  (let ((type (my/agent-buffer-type buffer))
        (sep (propertize " | " 'face 'font-lock-comment-face)))
    (pcase type
      ('claude
       (when my/agent-claude-quota-data
         (let* ((c-logo (propertize "󰘑" 'face (if active
                                                  '(:foreground "#da7756" :weight bold)
                                                'font-lock-comment-face)))
                (u5 (alist-get '5h-util my/agent-claude-quota-data))
                (r5 (alist-get '5h-reset my/agent-claude-quota-data))
                (u7 (alist-get '7d-util my/agent-claude-quota-data))
                (r7 (alist-get '7d-reset my/agent-claude-quota-data)))
           (concat " " c-logo sep
                   (my/agent--format-quota-item "5h:" u5 r5)
                   sep
                   (my/agent--format-quota-item "7d:" u7 r7)
                   " "))))
      ('antigravity
       (when my/agent-antigravity-quota-data
         (let* ((g-logo (propertize "󰊭" 'face (if active
                                                  '(:foreground "#4285f4" :weight bold)
                                                'font-lock-comment-face)))
                (g-5h (alist-get 'gemini-5h-util my/agent-antigravity-quota-data))
                (g-5r (alist-get 'gemini-5h-reset my/agent-antigravity-quota-data))
                (g-7d (alist-get 'gemini-7d-util my/agent-antigravity-quota-data))
                (g-7r (alist-get 'gemini-7d-reset my/agent-antigravity-quota-data)))
           (concat " " g-logo sep
                   (my/agent--format-quota-item "5h:" g-5h g-5r)
                   sep
                   (my/agent--format-quota-item "7d:" g-7d g-7r)
                   " "))))
      (_ ""))))

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
  (when (cl-some (lambda (b) (eq (my/agent-buffer-type b) 'claude)) (buffer-list))
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

(defun my/agent--find-agy-ports ()
  "Find candidate local TCP listening ports for running `agy` processes via /proc."
  (let* ((pids (delq nil (mapcar (lambda (f)
                                   (and (string-match-p "^[0-9]+$" f)
                                        (let ((cmd (expand-file-name (format "/proc/%s/cmdline" f))))
                                          (when (file-readable-p cmd)
                                            (with-temp-buffer
                                              (insert-file-contents cmd nil 0 64)
                                              (and (string-match-p "agy" (buffer-string))
                                                   f))))))
                                 (directory-files "/proc" nil "^[0-9]+$"))))
         (inodes (make-hash-table :test 'equal)))
    (dolist (pid pids)
      (let ((fd-dir (format "/proc/%s/fd" pid)))
        (when (file-directory-p fd-dir)
          (dolist (fd (ignore-errors (directory-files fd-dir t "^[0-9]+$")))
            (let ((target (ignore-errors (file-symlink-p fd))))
              (when (and target (string-match "socket:\\[\\([0-9]+\\)\\]" target))
                (puthash (match-string 1 target) t inodes)))))))
    (let (ports)
      (dolist (net-file '("/proc/net/tcp" "/proc/net/tcp6"))
        (when (file-readable-p net-file)
          (with-temp-buffer
            (insert-file-contents net-file)
            (goto-char (point-min))
            (forward-line 1)
            (while (not (eobp))
              (let* ((line (buffer-substring-no-properties (point) (line-end-position)))
                     (parts (split-string line "[ \t]+" t)))
                (when (and (>= (length parts) 10)
                           (string= (nth 3 parts) "0A") ; TCP_LISTEN
                           (gethash (nth 9 parts) inodes))
                  (let* ((addr (nth 1 parts))
                         (colon (string-search ":" addr)))
                    (when colon
                      (push (string-to-number (substring addr (1+ colon)) 16) ports)))))
              (forward-line 1)))))
      (nreverse ports))))

(defun my/agent-antigravity-update-usage-async ()
  "Fetch 5h and weekly usage for Antigravity (agy) agent asynchronously in pure Elisp."
  (when (cl-some (lambda (b) (eq (my/agent-buffer-type b) 'antigravity)) (buffer-list))
    (let ((ports (my/agent--find-agy-ports)))
      (dolist (port ports)
        (make-process
         :name (format "agent-agy-usage-fetch-%d" port)
         :buffer (generate-new-buffer (format " *agent-agy-usage-temp-%d*" port))
         :command (list "curl" "-s" "-m" "1"
                        "-H" "Content-Type: application/json"
                        "-H" "Connect-Protocol-Version: 1"
                        "-d" "{}"
                        (format "http://127.0.0.1:%d/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary" port))
         :sentinel (lambda (proc _event)
                     (when (eq (process-status proc) 'exit)
                       (unwind-protect
                           (when (= (process-exit-status proc) 0)
                             (with-current-buffer (process-buffer proc)
                               (goto-char (point-min))
                               (ignore-errors
                                 (let* ((json (json-parse-buffer :object-type 'alist :array-type 'list))
                                        gemini-5h gemini-5r gemini-7d gemini-7r
                                        tp-5h tp-5r tp-7d tp-7r)
                                   (dolist (g (alist-get 'groups (alist-get 'response json)))
                                     (let* ((name (or (alist-get 'displayName g) ""))
                                            (is-gemini (string-match-p "Gemini" name))
                                            (is-3p (string-match-p "Claude\\|GPT\\|3p" name)))
                                       (dolist (b (alist-get 'buckets g))
                                         (let* ((win (alist-get 'window b))
                                                (rem (or (alist-get 'remainingFraction b) 1.0))
                                                (rst (alist-get 'resetTime b))
                                                (used (max 0 (min 100 (round (* (- 1.0 rem) 100))))))
                                           (cond
                                            ((and is-gemini (string= win "5h"))
                                             (setq gemini-5h used gemini-5r rst))
                                            ((and is-gemini (string= win "weekly"))
                                             (setq gemini-7d used gemini-7r rst))
                                            ((and is-3p (string= win "5h"))
                                             (setq tp-5h used tp-5r rst))
                                            ((and is-3p (string= win "weekly"))
                                             (setq tp-7d used tp-7r rst)))))))
                                   (when (and gemini-5h gemini-7d)
                                     (setq my/agent-antigravity-quota-data
                                           `((gemini-5h-util . ,gemini-5h)
                                             (gemini-5h-reset . ,gemini-5r)
                                             (gemini-7d-util . ,gemini-7d)
                                             (gemini-7d-reset . ,gemini-7r)
                                             (3p-5h-util . ,(or tp-5h 0))
                                             (3p-5h-reset . ,tp-5r)
                                             (3p-7d-util . ,(or tp-7d 0))
                                             (3p-7d-reset . ,tp-7r)))
                                     (force-mode-line-update t))))))
                         (when (buffer-live-p (process-buffer proc))
                           (kill-buffer (process-buffer proc)))))))))))

(defun my/agent-update-usage-async ()
  "Dispatch usage update for all active agent types."
  (my/agent-claude-update-usage-async)
  (my/agent-antigravity-update-usage-async))

(unless my/agent-usage-timer
  (setq my/agent-usage-timer
        (run-with-timer 0 60 #'my/agent-update-usage-async)))

(require 'agent-keys)

(provide 'agent-mod)
