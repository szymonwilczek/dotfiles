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
  (define-key magit-status-mode-map (kbd "I") #'my/magit-stage-intent)
  (define-key magit-log-mode-map (kbd "W") #'my/magit-add-co-author)
  (define-key magit-log-mode-map (kbd "I") #'my/magit-stage-intent))

(with-eval-after-load 'evil-collection-magit
  (with-eval-after-load 'magit
    (dolist (map (list magit-mode-map magit-status-mode-map magit-log-mode-map magit-revision-mode-map))
      (evil-define-key* '(normal visual motion emacs) map "o" #'my/magit-browse-at-point))))

;; Git gutter indicators
(use-package git-gutter
  :ensure t
  :hook (prog-mode . git-gutter-mode)
  :config
  (setq git-gutter:update-interval 1)
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
                        (get-fg 'diff-changed)))
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

;;;; Merge conflict markers
;; Color only the marker lines, with faces inherited from the theme,
;; via font-lock so they follow edits and theme switches on their own.

(defface my/git-conflict-ours
  '((t :inherit (font-lock-function-name-face pulse-highlight-start-face) :weight bold :extend t))
  "Face for the <<<<<<< (ours, HEAD) conflict marker."
  :group 'vc)

(defface my/git-conflict-base
  '((t :inherit (font-lock-constant-face show-paren-match) :weight bold :extend t))
  "Face for the ||||||| (base, diff3 style) conflict marker."
  :group 'vc)

(defface my/git-conflict-separator
  '((t :inherit diff-refine-changed :weight bold :extend t))
  "Face for the ======= conflict marker."
  :group 'vc)

(defface my/git-conflict-theirs
  '((t :inherit (font-lock-type-face diff-added) :weight bold :extend t))
  "Face for the >>>>>>> (theirs) conflict marker."
  :group 'vc)

(defconst my/git-conflict--begin-re "^<<<<<<< .+$")
(defconst my/git-conflict--base-re "^||||||| .+$")
(defconst my/git-conflict--sep-re "^=======$")
(defconst my/git-conflict--end-re "^>>>>>>> .+$")
(defconst my/git-conflict--marker-re
  (mapconcat (lambda (re) (concat "\\(?:" re "\\)"))
             (list my/git-conflict--begin-re my/git-conflict--base-re
                   my/git-conflict--sep-re my/git-conflict--end-re)
             "\\|"))

(defun my/git-conflict--block ()
  "Return (BEG END SEP-OK) for the conflict block around the marker at point.
The block runs from <<<<<<< to the next >>>>>>> with nothing nested and
at most one ||||||| in between; otherwise, as for a lone RST or Markdown
\"=======\", the result is nil.  SEP-OK is non-nil when the block holds
exactly one \"=======\" after any |||||||; with more, one of them is
content and there is no telling which is Git's separator."
  (save-excursion
    (save-match-data
      (let* ((here (line-beginning-position))
             (beg (if (looking-at my/git-conflict--begin-re)
                      here
                    (re-search-backward my/git-conflict--begin-re nil t))))
        (when beg
          (goto-char beg)
          (forward-line 1)
          (when (re-search-forward my/git-conflict--end-re nil t)
            (let ((end (line-end-position))
                  (inner (my/git-conflict--inner-markers beg)))
              (when (and (>= end here)
                         (not (memq ?< inner))
                         (<= (seq-count (lambda (c) (eq c ?|)) inner) 1))
                (list beg end
                      (and (= (seq-count (lambda (c) (eq c ?=)) inner) 1)
                           (not (memq ?| (memq ?= inner)))))))))))))

(defun my/git-conflict--inner-markers (beg)
  "Marker chars of the lines after BEG up to the end marker at point."
  (let ((bound (line-beginning-position))
        (markers nil))
    (goto-char beg)
    (forward-line 1)
    (while (re-search-forward my/git-conflict--marker-re bound t)
      (push (char-after (line-beginning-position)) markers))
    (nreverse markers)))

(defun my/git-conflict--match (limit)
  "Font-lock matcher for conflict marker lines up to LIMIT."
  (let (found)
    (while (and (not found)
                (re-search-forward my/git-conflict--marker-re limit t))
      (let* ((mbeg (match-beginning 0))
             (mend (match-end 0))
             (block (save-excursion
                      (goto-char mbeg)
                      (my/git-conflict--block))))
        (when block
          ;; refontify the whole block when any part of it changes,
          ;; so deleting one marker updates the others
          (put-text-property (nth 0 block) (nth 1 block) 'font-lock-multiline t)
          (when (or (/= (char-after mbeg) ?=) (nth 2 block))
            ;; include the newline so :extend paints the whole line
            (set-match-data (list mbeg (min (1+ mend) (point-max))))
            (goto-char (min (1+ mend) (point-max)))
            (setq found t)))))
    found))

(defun my/git-conflict--face ()
  "Face for the conflict marker matched last."
  ;; the marker faces inherit their backgrounds from these
  (require 'diff-mode)
  (require 'pulse)
  (pcase (char-after (match-beginning 0))
    (?< 'my/git-conflict-ours)
    (?| 'my/git-conflict-base)
    (?= 'my/git-conflict-separator)
    (?> 'my/git-conflict-theirs)))

(defvar font-lock-beg)
(defvar font-lock-end)

(defun my/git-conflict--extend-region ()
  "Extend the font-lock region over the conflict around a marker in it.
A typed or restored marker completes a block that starts or ends
outside the changed text."
  (save-excursion
    (goto-char font-lock-beg)
    (when (re-search-forward my/git-conflict--marker-re font-lock-end t)
      (let ((beg (progn (goto-char font-lock-beg)
                        (re-search-backward my/git-conflict--begin-re nil t)))
            (end (progn (goto-char font-lock-end)
                        (and (re-search-forward my/git-conflict--end-re nil t)
                             (min (1+ (point)) (point-max))))))
        (when (or (and beg (< beg font-lock-beg))
                  (and end (> end font-lock-end)))
          (setq font-lock-beg (min font-lock-beg (or beg font-lock-beg))
                font-lock-end (max font-lock-end (or end font-lock-end)))
          t)))))

(defun my/git-conflict-markers-setup ()
  "Highlight Git conflict markers in the current buffer."
  (font-lock-add-keywords
   nil '((my/git-conflict--match (0 (my/git-conflict--face) t)))
   'append)
  (add-hook 'font-lock-extend-region-functions
            #'my/git-conflict--extend-region 'append t))

(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'my/git-conflict-markers-setup))

(with-eval-after-load 'smerge-mode
  (setq smerge-font-lock-keywords nil))

(defvar smerge-mode)
(defvar treesit-font-lock-feature-list)
(defvar treesit-font-lock-level)

(defvar-local my/git-conflict--hid-treesit-errors nil
  "Non-nil while the tree-sitter `error' font-lock feature is off here.")

(defun my/git-conflict--smerge-setup ()
  "Keep conflict contents in their normal colors while `smerge-mode' is on.
The markers are syntax errors to tree-sitter, which paints everything
after \"=======\" with its `error' feature; turn that off until the last
conflict is resolved and smerge-mode leaves."
  (setq-local diff-refine nil)
  (when (and (fboundp 'treesit-parser-list) (treesit-parser-list))
    (cond
     ((and smerge-mode (not my/git-conflict--hid-treesit-errors)
           (seq-some (lambda (features) (memq 'error features))
                     (seq-take treesit-font-lock-feature-list
                               treesit-font-lock-level)))
      (treesit-font-lock-recompute-features nil '(error))
      (setq my/git-conflict--hid-treesit-errors t)
      (font-lock-flush))
     ((and (not smerge-mode) my/git-conflict--hid-treesit-errors)
      (treesit-font-lock-recompute-features '(error))
      (setq my/git-conflict--hid-treesit-errors nil)
      (font-lock-flush)))))

(add-hook 'smerge-mode-hook #'my/git-conflict--smerge-setup)

(use-package octo
  :load-path "~/Dokumenty/GitHub/octo.el"
  :demand t
  :config
  (octo-sync-mode 1))

(use-package gh-radar
  :load-path "~/Dokumenty/GitHub/gh-radar.el"
  :demand t
  :custom
  (gh-radar-interval 600)
  (gh-radar-show-prefix nil)
  (gh-radar-notify-on-new t)
  (gh-radar-hide-zero-counts '(inbox))
  :config
  (gh-radar-mode 1))

(use-package rere
  :load-path "~/Dokumenty/GitHub/rere.el"
  :commands (rere))

(require 'git-keys)

(provide 'git-mod)
