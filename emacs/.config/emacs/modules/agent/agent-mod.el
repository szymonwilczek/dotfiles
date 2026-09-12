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

(defun my/agent--ghostel-buffer-name-fn (title)
  "Prevent ghostel from renaming agent buffers (*agent-*) on terminal TITLE updates."
  (if (or (bound-and-true-p my/agent-buffer-p)
          (string-prefix-p "*agent-" (buffer-name)))
      nil
    (and (fboundp 'ghostel-buffer-name-by-title)
         (ghostel-buffer-name-by-title title))))

(with-eval-after-load 'ghostel
  (setq ghostel-buffer-name-function #'my/agent--ghostel-buffer-name-fn))

(defun my/agent-open (name command-name &optional args)
  "Open or switch to an agent buffer with NAME running COMMAND-NAME with ARGS.
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
    (if (and existing
             (buffer-live-p existing)
             (or (get-buffer-process existing)
                 (with-current-buffer existing
                   (and (boundp 'ghostel--process) (process-live-p ghostel--process)))))
        (switch-to-buffer existing)
      (let ((buf (get-buffer-create buf-name)))
        (switch-to-buffer buf)
        (with-current-buffer buf
          (setq default-directory target-dir)
          (setq-local ghostel-buffer-name-function nil)
          (setq-local ghostel-set-title-function nil)
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
          (setq-local ghostel-set-title-function nil)
          (setq-local my/agent-buffer-p t)
          (setq-local my/agent-type (downcase name))
          (setq-local display-line-numbers nil)
          (display-line-numbers-mode -1)
          (unless (string= (buffer-name) buf-name)
            (rename-buffer buf-name t)))))
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

(defun my/agent-shell-select ()
  "Interactively choose from the AI agents and open in right split."
  (interactive)
  (let* ((choices '("Antigravity" "Claude Code"))
         (choice (completing-read "Select AI Agent: " choices nil t)))
    (pcase choice
      ("Antigravity" (my/agent-shell-gemini))
      ("Claude Code" (my/agent-shell-claude)))))

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
        ("Claude" (my/agent-shell-claude))
        (_        (my/agent-shell-gemini))))))

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

(defun my/agent--find-agy-pids ()
  "Return list of PIDs of running `agy` processes via /proc."
  (let (pids)
    (dolist (f (directory-files "/proc" nil "^[0-9]+$"))
      (let ((cmd-file (format "/proc/%s/cmdline" f)))
        (when (and (not (string= f (number-to-string (emacs-pid))))
                   (file-readable-p cmd-file))
          (with-temp-buffer
            (insert-file-contents cmd-file nil 0 128)
            (let* ((cmd-str (buffer-string))
                   (first-arg (car (split-string cmd-str "\0" t))))
              (when (and first-arg
                         (or (string= first-arg "agy")
                             (string-suffix-p "/agy" first-arg)))
                (push f pids)))))))
    (nreverse pids)))

(defun my/agent--bytes-to-uint64 (str &optional offset)
  "Convert 8 bytes in STR at OFFSET to 64-bit integer."
  (let ((off (or offset 0))
        (val 0))
    (dotimes (i 8)
      (setq val (logior val (ash (aref str (+ off i)) (* 8 i)))))
    val))

(defun my/agent--uint64-to-bytes (n)
  "Convert 64-bit integer N to 8-byte little-endian string."
  (let ((bytes (make-string 8 0)))
    (dotimes (i 8)
      (aset bytes i (logand (ash n (* -8 i)) #xff)))
    bytes))

(defvar my/agent--agy-csrf-cache nil
  "Cached cons (PID . CSRF-TOKEN) for running Antigravity process.")

(defun my/agent--get-agy-csrf-token (&optional target-pid)
  "Extract CSRF token from running Antigravity process memory in pure Elisp.
If TARGET-PID is nil, the first running `agy` PID is used.
Caches the token in `my/agent--agy-csrf-cache` while the process is alive."
  (if (and my/agent--agy-csrf-cache
           (or (null target-pid)
               (equal (car my/agent--agy-csrf-cache) (format "%s" target-pid)))
           (file-exists-p (format "/proc/%s" (car my/agent--agy-csrf-cache))))
      (cdr my/agent--agy-csrf-cache)
    (let* ((pid (or (and target-pid (format "%s" target-pid))
                    (car (my/agent--find-agy-pids))))
           (mem-file (and pid (format "/proc/%s/mem" pid)))
           (maps-file (and pid (format "/proc/%s/maps" pid))))
      (when (and pid (file-readable-p mem-file) (file-readable-p maps-file))
        (let (base-addr rw-regions)
          (with-temp-buffer
            (insert-file-contents maps-file)
            (goto-char (point-min))
            (while (re-search-forward "^\\([0-9a-f]+\\)-\\([0-9a-f]+\\)[ \t]+\\([^ \t\n]+\\)[ \t]+[^ \t\n]+[ \t]+[^ \t\n]+[ \t]+[^ \t\n]+[ \t]*\\(.*\\)$" nil t)
              (let ((start (string-to-number (match-string 1) 16))
                    (end (string-to-number (match-string 2) 16))
                    (perms (match-string 3))
                    (path (match-string 4)))
                (when (and (not base-addr)
                           (string-match-p "r-xp" perms)
                           (string-match-p "agy" path))
                  (setq base-addr start))
                (when (and (string-match-p "rw" perms)
                           (not (string-match-p "shm" path))
                           (not (string-match-p "\\.so" path)))
                  (push (cons start end) rw-regions)))))
          (when base-addr
            (let* ((targets (list (+ base-addr #x78fd720)   ; WrapUnary.func1
                                  (+ base-addr #x78fd300))) ; WrapStreamingHandler.func1
                   (needles (mapcar #'my/agent--uint64-to-bytes targets))
                   (chunk-size (* 8 1024 1024))
                   token)
              (with-temp-buffer
                (set-buffer-multibyte nil)
                (catch 'found
                  (dolist (region (nreverse rw-regions))
                    (let ((r-start (car region))
                          (r-end (cdr region)))
                      (while (< r-start r-end)
                        (let ((cur-end (min (+ r-start chunk-size) r-end)))
                          (erase-buffer)
                          (condition-case nil
                              (insert-file-contents mem-file nil r-start cur-end)
                            (error nil))
                          (dolist (needle needles)
                            (goto-char (point-min))
                            (while (search-forward needle nil t)
                              (when (<= (+ (point) 8) (point-max))
                                (let* ((x0-bytes (buffer-substring-no-properties (point) (+ (point) 8)))
                                       (x0-addr (my/agent--bytes-to-uint64 x0-bytes)))
                                  (when (> x0-addr 0)
                                    (with-temp-buffer
                                      (set-buffer-multibyte nil)
                                      (condition-case nil
                                          (progn
                                            (insert-file-contents mem-file nil x0-addr (+ x0-addr 16))
                                            (let* ((inter (buffer-string))
                                                   (str-addr (my/agent--bytes-to-uint64 inter 0))
                                                   (str-len (my/agent--bytes-to-uint64 inter 8)))
                                              (when (and (= str-len 36) (> str-addr 0))
                                                (erase-buffer)
                                                (insert-file-contents mem-file nil str-addr (+ str-addr 36))
                                                (let ((candidate (buffer-string)))
                                                  (when (and (= (length candidate) 36)
                                                             (= (cl-count ?- candidate) 4))
                                                    (setq token candidate)
                                                    (throw 'found token))))))
                                        (error nil))))))))
                          (setq r-start cur-end))))))
                (when token
                  (setq my/agent--agy-csrf-cache (cons pid token))
                  token)))))))))

(defun my/agent--find-agy-ports ()
  "Find candidate local TCP listening ports for running `agy` processes via /proc."
  (let* ((pids (my/agent--find-agy-pids))
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
  (when (my/agent--live-buffer-p 'antigravity)
    (let ((token (my/agent--get-agy-csrf-token)))
      (when token
        (let ((ports (my/agent--find-agy-ports)))
          (dolist (port ports)
            (let ((proc-name (format "agent-agy-usage-fetch-%d" port)))
              (unless (process-live-p (get-process proc-name))
                (make-process
                 :name proc-name
                 :buffer (generate-new-buffer (format " *agent-agy-usage-temp-%d*" port))
                 :command (list "curl" "-s" "-m" "1"
                                "-H" "Content-Type: application/json"
                                "-H" "Connect-Protocol-Version: 1"
                                "-H" (format "x-codeium-csrf-token: %s" token)
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
                                   (kill-buffer (process-buffer proc)))))))))))))))

(defun my/agent-update-usage-async ()
  "Dispatch usage update for all active agent types if any agent buffer is open."
  (when (my/agent--live-buffer-p 'claude)
    (my/agent-claude-update-usage-async))
  (when (my/agent--live-buffer-p 'antigravity)
    (my/agent-antigravity-update-usage-async)))

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
    (when (and (memq type '(claude antigravity))
               (eq win (selected-window))
               (> (- now my/agent--last-focus-update-time) 2.0))
      (setq my/agent--last-focus-update-time now)
      (cond
       ((eq type 'claude) (my/agent-claude-update-usage-async))
       ((eq type 'antigravity) (my/agent-antigravity-update-usage-async))))))

(add-hook 'window-selection-change-functions #'my/agent--on-focus-change)

(require 'agent-keys)

(provide 'agent-mod)
