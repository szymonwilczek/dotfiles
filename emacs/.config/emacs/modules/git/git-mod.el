;;; Magit, diff-hl and custom Git commands -*- lexical-binding: t; -*-

;; Custom Git Commands
;; (ported from my Lazygit config)
(defun my/magit-add-co-author (author)
  "Add Co-authored-by trailer to commit at point or HEAD."
  (interactive
   (let* ((cmd "(git log --format='%aN <%aE>'; git log --all --format='%(trailers:key=Co-authored-by,valueonly=true)') | sed '/^$/d' | sort -u")
          (authors (split-string (shell-command-to-string cmd) "\n" t))
          (chosen (completing-read "Pick Co-author: " authors nil nil)))
     (list chosen)))
  (let* ((commit (or (magit-commit-at-point) (magit-rev-parse "HEAD")))
         (head (magit-rev-parse "HEAD"))
         (branch (magit-get-current-branch)))
    (if (magit-rev-equal commit head)
        (magit-call-git "commit" "--amend" "--no-edit" (format "--trailer=Co-authored-by: %s" author))
      (if (and branch (magit-commit-p commit))
          (progn
            (magit-call-git "checkout" commit)
            (magit-call-git "commit" "--amend" "--no-edit" (format "--trailer=Co-authored-by: %s" author))
            (magit-call-git "rebase" "--onto" "HEAD" commit branch))
        (user-error "Cannot rebase without an active branch")))
    (magit-refresh)))

(defun my/magit-signoff-commit ()
  "Add Signed-off-by trailer to commit at point or HEAD."
  (interactive)
  (let* ((commit (or (magit-commit-at-point) (magit-rev-parse "HEAD")))
         (head (magit-rev-parse "HEAD"))
         (branch (magit-get-current-branch)))
    (if (magit-rev-equal commit head)
        (magit-call-git "commit" "--amend" "--no-edit" "--signoff")
      (if (and branch (magit-commit-p commit))
          (progn
            (magit-call-git "checkout" commit)
            (magit-call-git "commit" "--amend" "--no-edit" "--signoff")
            (magit-call-git "rebase" "--onto" "HEAD" commit branch))
        (user-error "Cannot rebase without an active branch")))
    (magit-refresh)))

(defun my/magit-extract-commit-files ()
  "Extract files from commit (Mixed reset + Empty commit with message).
Allowed during an active rebase at the current HEAD commit."
  (interactive)
  (unless (magit-rebase-in-progress-p)
    (user-error "Error: Rebase is not in progress"))
  (let* ((head (magit-rev-parse "HEAD"))
         (commit-at-point (magit-commit-at-point)))
    (when (and commit-at-point
               (not (magit-rev-equal commit-at-point head)))
      (user-error "Error: Cursor must be on the HEAD commit (%s)" (magit-rev-format "%h" head)))
    (magit-call-git "reset" "--mixed" "HEAD~1")
    (magit-call-git "commit" "--allow-empty" "-C" head)
    (ignore-errors (magit-call-git "add" "-N" "."))
    (magit-refresh)
    (message "Files extracted from commit %s (ready in Unstaged changes)." (magit-rev-format "%h" head))))

(defun my/magit-stage-intent ()
  "Track untracked file or all files with intent-to-add so they appear in Unstaged changes."
  (interactive)
  (let ((file (magit-file-at-point)))
    (if file
        (magit-call-git "add" "-N" "--" file)
      (magit-call-git "add" "-N" "."))
    (magit-refresh)))

(defun my/magit-remote-to-http-url (remote-url)
  "Convert SSH or HTTPS git remote URL to base HTTP browser URL."
  (let ((url (replace-regexp-in-string "\\.git\\'" "" remote-url)))
    (cond
     ((string-prefix-p "git@" url)
      (let* ((after-at (substring url 4))
             (colon-pos (string-search ":" after-at)))
        (format "https://%s/%s" (substring after-at 0 colon-pos) (substring after-at (1+ colon-pos)))))
     ((string-prefix-p "ssh://git@" url)
      (let* ((after-at (substring url 10))
             (slash-pos (string-search "/" after-at)))
        (format "https://%s/%s" (substring after-at 0 slash-pos) (substring after-at (1+ slash-pos)))))
     ((string-prefix-p "http://" url)
      (concat "https://" (substring url 7)))
     ((string-prefix-p "https://" url)
      url)
     (t (concat "https://" url)))))

(defun my/magit-browse-at-point ()
  "Open commit, branch, or repository at point in the remote web browser."
  (interactive)
  (require 'magit)
  (let* ((remote-url (or (magit-get "remote" (or (magit-get-remote) "origin") "url")
                         (magit-get "remote" "origin" "url")))
         (commit (or (magit-commit-at-point)
                     (magit-branch-or-commit-at-point)))
         (branch (magit-branch-at-point)))
    (if (not remote-url)
        (user-error "No Git remote URL found for this repository")
      (let* ((base-url (my/magit-remote-to-http-url remote-url))
             (target-url
              (cond
               (commit
                (format "%s/commit/%s" base-url commit))
               (branch
                (format "%s/tree/%s" base-url branch))
               (t
                base-url))))
        (message "Opened %s in browser." target-url)
        (browse-url target-url)))))

(defvar ghostel-shell)
(defvar ghostel-buffer-name)
(declare-function ghostel "ghostel")

(defun my/open-lazygit ()
  "Open Lazygit inside Ghostel terminal in the current project root or directory."
  (interactive)
  (require 'ghostel nil t)
  (let* ((proj-root (or (and (fboundp 'projectile-project-root) (projectile-project-root))
                        default-directory))
         (old-buf (get-buffer "*lazygit*"))
         (script-path (expand-file-name "scripts/lazygit-edit.sh" user-emacs-directory))
         (launcher-path (expand-file-name "scripts/run-lazygit.sh" user-emacs-directory))
         (override-cfg (expand-file-name ".cache/lazygit-emacs.yml" user-emacs-directory)))
    (make-directory (file-name-directory override-cfg) t)
    (with-temp-file override-cfg
      (insert (format "gui:\n  nerdFontsVersion: \"3\"\n\nos:\n  editPreset: \"\"\n  edit: \"sh %s {{filename}}\"\n  editAtLine: \"sh %s {{filename}} {{line}}\"\n  open: \"sh %s {{filename}}\"\n  suspendOnEdit: false\n"
                      script-path script-path script-path)))
    (when (and old-buf (buffer-live-p old-buf))
      (kill-buffer old-buf))
    (let* ((default-directory proj-root)
           (ghostel-shell launcher-path)
           (ghostel-buffer-name "*lazygit*")
           (buf (ghostel t)))
      (delete-other-windows)
      (switch-to-buffer buf))))

;; GPG Pinentry Configuration
(use-package pinentry
  :ensure t
  :init
  (setq epg-pinentry-mode 'loopback)
  :config
  (pinentry-start))

;; Magit Configuration
(use-package magit
  :ensure t
  :defer t
  :init
  (setq with-editor-emacsclient-executable "emacsclient")
  :custom
  (magit-diff-refine-hunk 'all)
  (magit-save-repository-buffers 'dontask)
  :config
  (setq magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  (setq epa-file-default-user-key "B8E944071CB7EB8A")

  ;; Turn off line numbers
  ;; This caused flashbangs...
  (add-hook 'git-commit-mode-hook (lambda () (display-line-numbers-mode -1)))

  ;; -s (--signoff) and -S (--gpg-sign) in Magit commit
  ;; This is the only way
  (with-eval-after-load 'magit-commit
    (when-let* ((proto (get 'magit-commit 'transient--prefix)))
      (oset proto value '("--gpg-sign=B8E944071CB7EB8A" "--signoff" "--verbose"))))

  ;; Evil scrolling
  (define-key magit-mode-map (kbd "z") nil)
  (define-key magit-mode-map (kbd "Z") #'magit-stash)
  (define-key magit-status-mode-map (kbd "z") nil)
  (define-key magit-status-mode-map (kbd "Z") #'magit-stash)

  ;; 'o' key in Magit (Open in browser)
  (define-key magit-mode-map (kbd "o") #'my/magit-browse-at-point)
  (define-key magit-status-mode-map (kbd "o") #'my/magit-browse-at-point)
  (define-key magit-log-mode-map (kbd "o") #'my/magit-browse-at-point)
  (define-key magit-revision-mode-map (kbd "o") #'my/magit-browse-at-point)

  (with-eval-after-load 'evil
    (dolist (map (list magit-mode-map magit-status-mode-map magit-log-mode-map magit-revision-mode-map))
      (evil-define-key* '(normal visual motion emacs) map "o" #'my/magit-browse-at-point)))

  ;; My Lazygit keys in Magit log & status
  (define-key magit-status-mode-map (kbd "W") #'my/magit-add-co-author)
  (define-key magit-status-mode-map (kbd "F") #'my/magit-signoff-commit)
  (define-key magit-status-mode-map (kbd "E") #'my/magit-extract-commit-files)
  (define-key magit-status-mode-map (kbd "I") #'my/magit-stage-intent)
  (define-key magit-log-mode-map (kbd "W") #'my/magit-add-co-author)
  (define-key magit-log-mode-map (kbd "F") #'my/magit-signoff-commit)
  (define-key magit-log-mode-map (kbd "E") #'my/magit-extract-commit-files)
  (define-key magit-log-mode-map (kbd "I") #'my/magit-stage-intent))

(with-eval-after-load 'evil-collection-magit
  (with-eval-after-load 'magit
    (dolist (map (list magit-mode-map magit-status-mode-map magit-log-mode-map magit-revision-mode-map))
      (evil-define-key* '(normal visual motion emacs) map "o" #'my/magit-browse-at-point))))

;; GitHub Issues and Pull Requests
(defvar my/forge-image-cache-dir
  (expand-file-name "emacs-forge-images" temporary-file-directory)
  "Temporary directory in /tmp to cache downloaded Forge images.")

(defvar-local my/forge-image-overlays nil
  "List of active inline image overlays in current buffer.")

(defun my/forge-get-github-token ()
  "Retrieve GitHub auth token from Ghub/auth-source if available."
  (and (featurep 'ghub)
       (or (condition-case nil (ghub--token "api.github.com" "szymonwilczek" 'forge) (error nil))
           (condition-case nil (ghub--token "api.github.com" user-login-name 'forge) (error nil)))))

(defun my/forge-clear-image-overlays ()
  "Remove all inline image overlays from current buffer."
  (interactive)
  (when my/forge-image-overlays
    (mapc #'delete-overlay my/forge-image-overlays)
    (setq my/forge-image-overlays nil)))

(defun my/forge-display-image-at (buf beg end file-path url)
  "Display cached image file at BEG..END in BUF."
  (when (and (buffer-live-p buf)
             (file-exists-p file-path)
             (> (file-attribute-size (file-attributes file-path)) 100))
    (with-current-buffer buf
      (save-excursion
        (let* ((win (get-buffer-window buf t))
               (win-w (if win (- (window-body-width win t) 60) 800))
               (max-w (min 850 (max 300 win-w)))
               (img (create-image file-path nil nil :max-width max-w :max-height 600))
               (ov (make-overlay beg end buf t nil)))
          (overlay-put ov 'display img)
          (overlay-put ov 'help-echo (format "%s\n(Click or RET to open in browser)" url))
          (let ((map (make-sparse-keymap)))
            (define-key map [mouse-1] (lambda () (interactive) (browse-url url)))
            (define-key map [return]  (lambda () (interactive) (browse-url url)))
            (overlay-put ov 'keymap map)
            (overlay-put ov 'pointer 'hand))
          (push ov my/forge-image-overlays))))))

(defun my/forge-fetch-and-display-image (buf beg end url)
  "Asynchronously fetch image URL into /tmp and display in BUF."
  (make-directory my/forge-image-cache-dir t)
  (let* ((cache-file (expand-file-name (md5 url) my/forge-image-cache-dir)))
    (if (and (file-exists-p cache-file)
             (> (file-attribute-size (file-attributes cache-file)) 100))
        (my/forge-display-image-at buf beg end cache-file url)
      (let* ((tok (my/forge-get-github-token))
             (auth-hdr (if (and tok (not (string-empty-p tok)))
                           (format "-H \"Authorization: token %s\"" tok)
                         ""))
             (cmd (if (string-match-p "github\\.com" url)
                      (format "LOC=$(curl -sI %s \"%s\" | grep -i '^location:' | tr -d '\r' | cut -d' ' -f2-); if [ -n \"$LOC\" ]; then curl -sL \"$LOC\" -o \"%s\"; else curl -sL %s \"%s\" -o \"%s\"; fi"
                              auth-hdr url cache-file auth-hdr url cache-file)
                    (format "curl -sL \"%s\" -o \"%s\"" url cache-file))))
        (make-process
         :name (format "forge-img-%s" (md5 url))
         :buffer nil
         :command (list "sh" "-c" cmd)
         :sentinel
         (lambda (proc event)
           (when (string-prefix-p "finished" event)
             (my/forge-display-image-at buf beg end cache-file url))))))))

(defun my/forge-render-images (&optional target-buf)
  "Scan TARGET-BUF (or current buffer) for GitHub HTML/Markdown images and render inline."
  (interactive)
  (let ((buf (or target-buf (current-buffer))))
    (when (buffer-live-p buf)
      (with-current-buffer buf
        (my/forge-clear-image-overlays)
        (save-excursion
          (save-match-data
            (goto-char (point-min))
            ;; <img ... src="url" ... />
            (while (re-search-forward "<img[ \t\n\r]+[^>]*?src=[\"']\\(https?://[^\"']+\\)[\"'][^>]*?\\(?:/?>\\|</img>\\)" nil t)
              (let ((beg (match-beginning 0))
                    (end (match-end 0))
                    (url (match-string-no-properties 1)))
                (my/forge-fetch-and-display-image buf beg end url)))

            (goto-char (point-min))
            ;; ![alt](url)
            (while (re-search-forward "!\\[\\(.*?\\)\\](\\(\\(?:https?\\)://[^)]+\\))" nil t)
              (let ((beg (match-beginning 0))
                    (end (match-end 0))
                    (url (match-string-no-properties 2)))
                (my/forge-fetch-and-display-image buf beg end url)))))))))

(defun my/forge-toggle-images ()
  "Toggle inline images in current Forge topic buffer."
  (interactive)
  (if my/forge-image-overlays
      (progn
        (my/forge-clear-image-overlays)
        (message "Forge inline images hidden"))
    (my/forge-render-images)
    (message "Forge inline images rendered")))

(use-package forge
  :ensure t
  :defer t
  :after magit
  :init
  (setq forge-add-default-bindings nil)
  :config
  (advice-add 'forge-topic-setup-buffer :after
              (lambda (&rest _)
                (run-at-time 0.2 nil (lambda (buf)
                                       (when (buffer-live-p buf)
                                         (my/forge-render-images buf)))
                             (current-buffer)))))

;; Git gutter indicators
(use-package git-gutter
  :ensure t
  :hook (prog-mode . git-gutter-mode)
  :config
  (setq git-gutter:update-interval 0)
  (add-hook 'magit-post-refresh-hook #'git-gutter:update-all-windows)
  (add-hook 'focus-in-hook           #'git-gutter:update-all-windows)
  (add-hook 'after-save-hook         #'git-gutter:update-all-windows)
  (add-hook 'after-revert-hook       #'git-gutter:update-all-windows))

(use-package git-gutter-fringe
  :ensure t
  :after git-gutter
  :config
  (define-fringe-bitmap 'git-gutter-fr:added [224] nil nil '(center repeated))
  (define-fringe-bitmap 'git-gutter-fr:modified [224] nil nil '(center repeated))
  (define-fringe-bitmap 'git-gutter-fr:deleted [128 192 224 240] nil nil 'bottom)

  ;; Sync gutter colors with active theme
  (defun my/git-gutter-sync-theme-faces (&rest _)
    "Synchronize git-gutter colors with the active theme and ensure transparent background."
    (cl-flet ((get-fg (face) (when (and (facep face) (face-foreground face nil t))
                               (face-foreground face nil t))))
      (let ((add-fg (or (get-fg 'diff-added)
                        (get-fg 'success)
                        (get-fg 'magit-diff-added-highlight)
                        (get-fg 'magit-diff-added)))
            (mod-fg (or (get-fg 'warning)
                        (get-fg 'font-lock-warning-face)
                        (get-fg 'diff-changed)
                        (get-fg 'magit-diff-modified-highlight)))
            (del-fg (or (get-fg 'error)
                        (get-fg 'diff-removed)
                        (get-fg 'magit-diff-removed-highlight)
                        (get-fg 'magit-diff-removed))))
        (when add-fg
          (set-face-attribute 'git-gutter-fr:added nil :foreground add-fg :background 'unspecified)
          (set-face-attribute 'git-gutter:added nil :foreground add-fg :background 'unspecified))
        (when mod-fg
          (set-face-attribute 'git-gutter-fr:modified nil :foreground mod-fg :background 'unspecified)
          (set-face-attribute 'git-gutter:modified nil :foreground mod-fg :background 'unspecified))
        (when del-fg
          (set-face-attribute 'git-gutter-fr:deleted nil :foreground del-fg :background 'unspecified)
          (set-face-attribute 'git-gutter:deleted nil :foreground del-fg :background 'unspecified))
        (set-face-attribute 'fringe nil :background 'unspecified))))

  (my/git-gutter-sync-theme-faces)
  (advice-add 'load-theme :after #'my/git-gutter-sync-theme-faces))

;;;; Merge conflict resolution
(defvar my/git-conflict-highlight-enabled t
  "When non-nil, Git merge conflict blocks are automatically highlighted with overlays.")

(defvar-local my/git-conflict-overlays nil
  "List of active conflict marker overlays in current buffer.")

(defun my/git-conflict-clear-overlays ()
  "Remove all conflict marker overlays and restore clean buffer state."
  (interactive)
  (when (bound-and-true-p smerge-mode)
    (smerge-mode -1))
  (when my/git-conflict-overlays
    (mapc #'delete-overlay my/git-conflict-overlays)
    (setq my/git-conflict-overlays nil))
  (when (fboundp 'font-lock-flush)
    (font-lock-flush)))

(defun my/git-conflict-toggle ()
  "Toggle automatic Git merge conflict highlighting on or off across all buffers."
  (interactive)
  (setq my/git-conflict-highlight-enabled (not my/git-conflict-highlight-enabled))
  (if my/git-conflict-highlight-enabled
      (progn
        (dolist (buf (buffer-list))
          (with-current-buffer buf
            (my/git-conflict--setup-buffer)))
        (message "Git conflict highlighting: ENABLED"))
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (remove-hook 'after-change-functions #'my/git-conflict--on-change t)
        (my/git-conflict-clear-overlays)))
    (message "Git conflict highlighting: DISABLED")))

(defun my/git-conflict-highlight-buffer (&rest _)
  "Scan buffer for valid Git merge conflict blocks and apply full-line overlays."
  (interactive)
  (when (and my/git-conflict-highlight-enabled
             (not (minibufferp))
             (not (derived-mode-p 'dired-mode 'magit-mode 'ghostel-mode))
             (not (string-match-p "\\*agent-" (buffer-name)))
             (not (string-match-p "\\*ghostel" (buffer-name))))
    (my/git-conflict-clear-overlays)
    (save-excursion
      (save-match-data
        (goto-char (point-min))
        (while (re-search-forward "^<<<<<<<[ \t\n]" nil t)
          (let* ((ours-match (match-beginning 0))
                 (ours-beg (save-excursion (goto-char ours-match) (line-beginning-position)))
                 (ours-end (save-excursion (goto-char ours-match) (min (point-max) (1+ (line-end-position)))))
                 (end-match (save-excursion
                              (goto-char ours-end)
                              (re-search-forward "^>>>>>>>[ \t\n]" nil t))))
            (when end-match
              (let* ((theirs-match (match-beginning 0))
                     (theirs-beg (save-excursion (goto-char theirs-match) (line-beginning-position)))
                     (theirs-end (save-excursion (goto-char theirs-match) (min (point-max) (1+ (line-end-position)))))
                     (sep-match (save-excursion
                                  (goto-char ours-end)
                                  (re-search-forward "^=======[ \t]*$" theirs-beg t))))
                (when sep-match
                  (let* ((sep-match-pos (match-beginning 0))
                         (sep-beg (save-excursion (goto-char sep-match-pos) (line-beginning-position)))
                         (sep-end (save-excursion (goto-char sep-match-pos) (min (point-max) (1+ (line-end-position)))))
                         (bg-ours   (or (and (fboundp 'ef-themes-get-color-value) (ef-themes-get-color-value 'bg-err))
                                        "#4a151b"))
                         (fg-ours   (or (and (fboundp 'ef-themes-get-color-value) (ef-themes-get-color-value 'err))
                                        "#ff7b72"))
                         (bg-sep    (or (and (fboundp 'ef-themes-get-color-value) (ef-themes-get-color-value 'bg-warning))
                                        "#3e2e04"))
                         (fg-sep    (or (and (fboundp 'ef-themes-get-color-value) (ef-themes-get-color-value 'warning))
                                        "#f2cc60"))
                         (bg-theirs (or (and (fboundp 'ef-themes-get-color-value) (ef-themes-get-color-value 'bg-info))
                                        "#0c2d6b"))
                         (fg-theirs (or (and (fboundp 'ef-themes-get-color-value) (ef-themes-get-color-value 'info))
                                        "#58a6ff"))
                         (ov-ours (make-overlay ours-beg ours-end))
                         (ov-sep (make-overlay sep-beg sep-end))
                         (ov-theirs (make-overlay theirs-beg theirs-end)))
                    (overlay-put ov-ours 'face `(:background ,bg-ours :foreground ,fg-ours :weight bold :extend t))
                    (overlay-put ov-ours 'priority 200)
                    (overlay-put ov-sep 'face `(:background ,bg-sep :foreground ,fg-sep :weight bold :extend t))
                    (overlay-put ov-sep 'priority 200)
                    (overlay-put ov-theirs 'face `(:background ,bg-theirs :foreground ,fg-theirs :weight bold :extend t))
                    (push ov-ours my/git-conflict-overlays)
                    (push ov-sep my/git-conflict-overlays)
                    (push ov-theirs my/git-conflict-overlays)))))))))))

(with-eval-after-load 'smerge-mode
  (setq smerge-font-lock-keywords nil)
  (dolist (face '(smerge-markers smerge-upper smerge-lower smerge-base
                                 smerge-refined-added smerge-refined-removed))
    (when (facep face)
      (set-face-attribute face nil :background 'unspecified :foreground 'unspecified :weight 'unspecified))))

(defvar-local my/git-conflict--idle-timer nil
  "Buffer-local debounce timer for Git merge conflict re-scanning.")

(defun my/git-conflict--on-change (beg end _len)
  "Debounced live update when buffer content changes (pasted conflict, edited text)."
  (when (and (bound-and-true-p my/git-conflict-highlight-enabled)
             (not (minibufferp))
             (not (derived-mode-p 'dired-mode 'magit-mode 'ghostel-mode))
             (not (string-match-p "\\*agent-" (buffer-name)))
             (not (string-match-p "\\*ghostel" (buffer-name))))

    ;; only trigger scan if buffer already has conflicts or changed region has conflict marker chars
    (when (or my/git-conflict-overlays
              (save-excursion
                (save-match-data
                  (goto-char (max (point-min) (- beg 2)))
                  (re-search-forward "^\\(<<<<<<<\\|=======\\|>>>>>>>\\)"
                                     (min (point-max) (+ end 8)) t))))
      (when (timerp my/git-conflict--idle-timer)
        (cancel-timer my/git-conflict--idle-timer))
      (setq my/git-conflict--idle-timer
            (run-with-idle-timer 0.4 nil
                                 (lambda (buf)
                                   (when (buffer-live-p buf)
                                     (with-current-buffer buf
                                       (my/git-conflict-highlight-buffer))))
                                 (current-buffer))))))

(defun my/git-conflict--setup-buffer ()
  "Enable conflict detection and highlight conflicts for current editing buffer."
  (when (and (not (minibufferp))
             (not (derived-mode-p 'dired-mode 'magit-mode 'ghostel-mode))
             (not (string-match-p "\\*agent-" (buffer-name)))
             (not (string-match-p "\\*ghostel" (buffer-name))))
    (add-hook 'after-change-functions #'my/git-conflict--on-change nil t)
    (my/git-conflict-highlight-buffer)))

(add-hook 'find-file-hook #'my/git-conflict--setup-buffer)
(add-hook 'prog-mode-hook #'my/git-conflict--setup-buffer)
(add-hook 'text-mode-hook #'my/git-conflict--setup-buffer)
(add-hook 'after-change-major-mode-hook #'my/git-conflict--setup-buffer)
(add-hook 'after-save-hook #'my/git-conflict-highlight-buffer)
(add-hook 'after-revert-hook #'my/git-conflict-highlight-buffer)
(advice-add 'load-theme :after #'my/git-conflict-highlight-buffer)

(require 'git-keys)

(provide 'git-mod)
