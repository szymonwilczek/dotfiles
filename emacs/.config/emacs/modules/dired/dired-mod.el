;;; Dired file management -*- lexical-binding: t; -*-

(use-package dired
  :ensure nil
  :custom
  (dired-listing-switches "-al --group-directories-first -h -v")
  (dired-dwim-target t)
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'top)
  (dired-auto-revert-buffer t)
  (delete-by-moving-to-trash t)
  (dired-kill-when-opening-new-dired-buffer t)
  :hook
  ((dired-mode . dired-hide-details-mode)
   (dired-mode . hl-line-mode))
  :config
  (require 'dired-x)
  ;; omit mode only hides dotfiles, shown or hidden in every dired at once
  (setq dired-omit-files "\\`[.][^.]"
        dired-omit-extensions nil
        dired-omit-verbose nil))

(define-advice find-alternate-file (:around (fn &rest args) my/dired-replace-last-buffer)
  "Let dired replace its buffer even when it is a perspective's only one."
  (let ((kill-buffer-query-functions
         (if (derived-mode-p 'dired-mode)
             (remq 'persp-maybe-kill-buffer kill-buffer-query-functions)
           kill-buffer-query-functions)))
    (apply fn args)))

(defvar my/dired-show-hidden t
  "Non-nil when dired lists dotfiles.")

(defun my/dired-apply-hidden ()
  "Show or hide dotfiles in the current dired buffer per `my/dired-show-hidden'."
  (when (derived-mode-p 'dired-mode)
    (dired-omit-mode (if my/dired-show-hidden -1 1))))

(add-hook 'dired-mode-hook #'my/dired-apply-hidden)

(defun my/dired-toggle-hidden ()
  "Toggle dotfiles in all dired buffers."
  (interactive)
  (setq my/dired-show-hidden (not my/dired-show-hidden))
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (my/dired-apply-hidden)))
  (message "Hidden files %s" (if my/dired-show-hidden "shown" "hidden")))

;; Per-window history of visited directories
(defvar my/dired-history-max 50
  "Number of directories each window remembers to go back or forward to.")

(defun my/dired-history--record (frame)
  "Remember the directory each dired window of FRAME showed before."
  (dolist (window (window-list frame 'no-minibuf))
    (with-current-buffer (window-buffer window)
      (when (derived-mode-p 'dired-mode)
        (let ((dir (dired-current-directory))
              (prev (window-parameter window 'my/dired-dir)))
          (unless (equal prev dir)
            (let ((moving (window-parameter window 'my/dired-moving)))
              (when (and prev (not (eq moving 'back)))
                (my/dired-history--push window 'my/dired-history prev))
              ;; fresh visit drops the directories to go forward to
              (unless moving
                (set-window-parameter window 'my/dired-future nil))
              (set-window-parameter window 'my/dired-moving nil))
            (set-window-parameter window 'my/dired-dir dir)))))))

(defun my/dired-history--push (window param dir)
  "Put DIR in front of WINDOW's PARAM list of directories."
  (set-window-parameter
   window param
   (seq-take (cons dir (delete dir (window-parameter window param)))
             my/dired-history-max)))

(add-hook 'window-buffer-change-functions #'my/dired-history--record)

(defun my/dired-back ()
  "Go back to the directory this window showed before.
Point lands on the directory just left when it is listed there."
  (interactive)
  (let* ((window (selected-window))
         (from (dired-current-directory))
         (history (seq-filter #'file-directory-p (window-parameter window 'my/dired-history)))
         (dir (or (car history) (user-error "No previous directory"))))
    (set-window-parameter window 'my/dired-history (cdr history))
    (my/dired-history--push window 'my/dired-future from)
    (set-window-parameter window 'my/dired-moving 'back)
    (dired--find-possibly-alternative-file dir)
    (dired-goto-file (directory-file-name from))))

(defun my/dired-forward ()
  "Go forward again to the directory left by `my/dired-back'."
  (interactive)
  (let* ((window (selected-window))
         (future (seq-filter #'file-directory-p (window-parameter window 'my/dired-future)))
         (dir (or (car future) (user-error "No next directory"))))
    (set-window-parameter window 'my/dired-future (cdr future))
    (set-window-parameter window 'my/dired-moving 'forward)
    (dired--find-possibly-alternative-file dir)))

;; File clipboard shared with the desktop
(defvar my/dired-clipboard nil
  "Files copied or cut in dired as (OPERATION . FILES).
Holds the clipboard on frames without a window system.")

(defun my/dired-clipboard--files (value)
  "Return the (OPERATION . FILES) that VALUE was put on the clipboard with."
  (and (stringp value) (get-text-property 0 'my/dired-clipboard value)))

(defun my/dired-clipboard--uri (file)
  "Return FILE as a file:// URI."
  (concat "file://" (url-hexify-string file url-path-allowed-chars)))

(defun my/dired-clipboard--convert-uri-list (selection type value)
  "Serve dired's files as text/uri-list, or fall back to the stock converter."
  (if-let* ((clip (my/dired-clipboard--files value)))
      (cons type (encode-coding-string
                  (mapconcat (lambda (f) (concat (my/dired-clipboard--uri f) "\r\n"))
                             (cdr clip) "")
                  'utf-8))
    (xselect-convert-to-text-uri-list selection type value)))

(defun my/dired-clipboard--convert-gnome (_selection type value)
  "Serve dired's files as x-special/gnome-copied-files."
  (when-let* ((clip (my/dired-clipboard--files value)))
    (cons type (encode-coding-string
                (mapconcat #'identity
                           (cons (symbol-name (car clip))
                                 (mapcar #'my/dired-clipboard--uri (cdr clip)))
                           "\n")
                'utf-8))))

(defun my/dired-clipboard--convert-kde-cut (_selection type value)
  "Tell KDE that dired's files were cut."
  (when (eq (car (my/dired-clipboard--files value)) 'cut)
    (cons type "1")))

(with-eval-after-load 'select
  (require 'url-util)
  (dolist (conv `((text/uri-list
                   ,(lambda (selection type value)
                      (or (my/dired-clipboard--files value)
                          (xselect-uri-list-available-p selection type value)))
                   . my/dired-clipboard--convert-uri-list)
                  (x-special/gnome-copied-files
                   ,(lambda (_selection _type value) (my/dired-clipboard--files value))
                   . my/dired-clipboard--convert-gnome)
                  (application/x-kde-cutselection
                   ,(lambda (_selection _type value)
                      (eq (car (my/dired-clipboard--files value)) 'cut))
                   . my/dired-clipboard--convert-kde-cut)))
    (setf (alist-get (car conv) selection-converter-alist) (cdr conv))))

(defun my/dired-clipboard--set (operation files)
  "Put FILES on the clipboard for OPERATION, `copy' or `cut'."
  (setq my/dired-clipboard (cons operation files))
  (when (display-graphic-p)
    (gui-set-selection 'CLIPBOARD
                       (propertize (string-join files "\n")
                                   'my/dired-clipboard my/dired-clipboard))))

(defun my/dired-clipboard--parse-uris (text)
  "Return the local file names of the file:// URIs in TEXT."
  (delq nil
        (mapcar (lambda (line)
                  (when (string-prefix-p "file://" line)
                    (decode-coding-string
                     (url-unhex-string (url-filename (url-generic-parse-url line)))
                     'utf-8)))
                (split-string text "[\r\n]+" t))))

(defun my/dired-clipboard--reader ()
  "Return a function reading the clipboard as a given type, or nil.
Wayland only hands the clipboard to the focused window, so wl-paste
reads it there."
  (if (and (getenv "WAYLAND_DISPLAY") (executable-find "wl-paste"))
      (let ((types (ignore-errors (process-lines "wl-paste" "--list-types"))))
        (lambda (type)
          (when (member (symbol-name type) types)
            (ignore-errors
              (decode-coding-string
               (with-output-to-string
                 (call-process "wl-paste" nil standard-output nil
                               "--no-newline" "--type" (symbol-name type)))
               'utf-8)))))
    (let ((targets (ignore-errors (gui-get-selection 'CLIPBOARD 'TARGETS))))
      (lambda (type)
        (when (and (vectorp targets) (seq-contains-p targets type))
          (when-let* ((text (ignore-errors (gui-get-selection 'CLIPBOARD type))))
            (if (multibyte-string-p text) text (decode-coding-string text 'utf-8))))))))

(defun my/dired-clipboard--get ()
  "Return the files on the clipboard as (OPERATION . FILES), or nil."
  (if (or (not (display-graphic-p))
          ;; asking wl-paste for it would wait on Emacs
          (gui-backend-selection-owner-p 'CLIPBOARD))
      (if (display-graphic-p)
          (my/dired-clipboard--files (gui-get-selection 'CLIPBOARD))
        my/dired-clipboard)
    (let ((get (my/dired-clipboard--reader)))
      (if-let* ((gnome (funcall get 'x-special/gnome-copied-files))
                (lines (split-string gnome "[\r\n]+" t)))
          (cons (if (string= (car lines) "cut") 'cut 'copy)
                (my/dired-clipboard--parse-uris (string-join (cdr lines) "\n")))
        (when-let* ((uris (funcall get 'text/uri-list))
                    (files (my/dired-clipboard--parse-uris uris)))
          (cons (if (equal (funcall get 'application/x-kde-cutselection) "1") 'cut 'copy)
                files))))))

(defun my/dired-clipboard--free-name (file)
  "Return FILE, or FILE with \" (N)\" before its extension when taken."
  (let ((dir (file-name-directory file))
        (base (file-name-sans-extension (file-name-nondirectory file)))
        (ext (or (file-name-extension file t) ""))
        (n 1))
    (while (file-exists-p file)
      (setq file (expand-file-name (format "%s (%d)%s" base n ext) dir)
            n (1+ n)))
    file))

(defun my/dired-copy ()
  "Copy the selected lines, the marked files or the file at point to the clipboard."
  (interactive)
  (let ((files (mapcar #'car (my/dired--targets))))
    (my/dired-clipboard--set 'copy files)
    (message "Copied %d file%s" (length files) (if (= (length files) 1) "" "s"))))

(defun my/dired-cut ()
  "Cut the selected lines, the marked files or the file at point to the clipboard."
  (interactive)
  (let ((files (mapcar #'car (my/dired--targets))))
    (my/dired-clipboard--set 'cut files)
    (message "Cut %d file%s" (length files) (if (= (length files) 1) "" "s"))))

(defun my/dired-paste ()
  "Paste the files on the clipboard into the current dired directory.
Copied files that would land on themselves get a \" (N)\" suffix; cut
files are moved and the clipboard is emptied."
  (interactive)
  (let* ((clip (or (my/dired-clipboard--get) (user-error "No files on the clipboard")))
         (cut (eq (car clip) 'cut))
         (dir (dired-current-directory))
         pasted)
    (dolist (from (mapcar #'directory-file-name (cdr clip)))
      (let ((to (expand-file-name (file-name-nondirectory from) dir)))
        (cond
         ((not (file-exists-p from))
          (message "Gone, skipped: %s" from))
         ((and (file-directory-p from) (file-in-directory-p dir from)
               (not (file-equal-p from to)))
          (message "Cannot paste a directory into itself: %s" from))
         ((file-equal-p from to)
          (unless cut
            (setq to (my/dired-clipboard--free-name to))
            (dired-copy-file from to nil)
            (push to pasted)))
         ((and (file-exists-p to)
               (not (y-or-n-p (format "Overwrite %s? " (abbreviate-file-name to))))))
         (t
          (if cut
              (dired-rename-file from to t)
            (dired-copy-file from to t))
          (push to pasted)))))
    (when cut
      (setq my/dired-clipboard nil)
      (when (gui-backend-selection-owner-p 'CLIPBOARD)
        (gui-set-selection 'CLIPBOARD nil)))
    (dolist (d (delete-dups (cons dir (mapcar #'file-name-directory
                                              (mapcar #'directory-file-name (cdr clip))))))
      (dolist (buf (dired-buffers-for-dir d))
        (with-current-buffer buf
          (revert-buffer))))
    (when pasted
      (dired-goto-file (car (last pasted))))
    (message "%s %d file%s" (if cut "Moved" "Pasted")
             (length pasted) (if (= (length pasted) 1) "" "s"))))

(use-package wdired
  :ensure nil
  :after dired
  :custom
  (wdired-allow-to-change-permissions t)
  (wdired-create-parent-directories t))

(use-package nerd-icons-dired
  :ensure t
  :after (dired nerd-icons)
  :hook (dired-mode . nerd-icons-dired-mode))

(require 'dired-keys)

(provide 'dired-mod)
