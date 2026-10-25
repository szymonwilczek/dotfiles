;;; Dired Evil keybindings -*- lexical-binding: t; -*-

(require 'dired)

(defun my/dired-copy-path ()
  "Copy the absolute path of the file at point to the kill ring."
  (interactive)
  (let ((filename (dired-get-filename nil t)))
    (if filename
        (progn
          (kill-new filename)
          (message "Copied path: %s" filename))
      (user-error "No file at point"))))

(defun my/dired-copy-name ()
  "Copy the filename of the file at point to the kill ring."
  (interactive)
  (let ((filename (dired-get-filename 'no-dir t)))
    (if filename
        (progn
          (kill-new filename)
          (message "Copied filename: %s" filename))
      (user-error "No file at point"))))

(defun my/dired--targets ()
  "Return the files to act on as (FILE . MARKER) pairs.
In Evil visual state these are the selected lines, which leaves visual
state; otherwise the marked files, or the file at point."
  (if (and (fboundp 'evil-visual-state-p) (evil-visual-state-p))
      (let* ((beg (min (point) (mark)))
             (end (max (point) (mark)))
             (last (save-excursion
                     (goto-char end)
                     (when (and (> end beg) (bolp))
                       (backward-char))
                     (pos-bol)))
             targets)
        (evil-exit-visual-state)
        (save-excursion
          (goto-char beg)
          (forward-line 0)
          (while (<= (point) last)
            (when-let* ((file (dired-get-filename nil t)))
              (push (cons file (point-marker)) targets))
            (if (eobp) (setq last -1) (forward-line 1))))
        (or (nreverse targets) (user-error "No files selected")))
    (nreverse (dired-map-over-marks (cons (dired-get-filename) (point-marker)) nil))))

(defun my/dired-delete ()
  "Move the selected lines, the marked files or the file at point to trash."
  (interactive)
  (dired-internal-do-deletions (my/dired--targets) nil delete-by-moving-to-trash))

(defun my/dired-delete-permanently ()
  "Delete the selected lines, the marked files or the file at point for good."
  (interactive)
  (let ((delete-by-moving-to-trash nil))
    (dired-internal-do-deletions (my/dired--targets) nil nil)))

(defun my/dired-rename ()
  "Rename the file at point within its directory."
  (interactive)
  (let* ((file (dired-get-filename nil t))
         (name (and file (file-name-nondirectory file))))
    (unless file
      (user-error "No file at point"))
    (let ((new (read-string "Rename to: " name)))
      (unless (string= new name)
        (dired-rename-file file (expand-file-name new (file-name-directory file)) nil)
        (revert-buffer)
        (dired-goto-file (expand-file-name new (file-name-directory file)))))))

(defun my/dired--on-selection (fn)
  "Call FN with the visual selection standing in for the marked files.
The selection is marked with a private character, so the files the user
marked with * elsewhere are left out and keep their marks."
  (let* ((targets (my/dired--targets))
         (dired-marker-char ?\a))
    (unwind-protect
        (progn
          (dolist (target targets)
            (save-excursion
              (goto-char (cdr target))
              (dired-mark 1)))
          (funcall fn))
      (dired-unmark-all-files dired-marker-char))))

(defun my/dired-move ()
  "Move the selected lines, the marked files or the file at point.
Offers the other pane as the target.  Like `dired-do-rename', but the
prompt says Move for a single file too."
  (interactive)
  (if (and (fboundp 'evil-visual-state-p) (evil-visual-state-p))
      (my/dired--on-selection
       (lambda ()
         (dired-do-create-files 'move #'dired-rename-file
                                "Move" nil nil "Move")))
    (dired-do-create-files 'move #'dired-rename-file
                           "Move" nil dired-keep-marker-rename "Move"))
  (dired-post-do-command))

(defun my/dired-copy-to-pane ()
  "Copy the selected lines, the marked files or the file at point.
Offers the other pane as the target, like `dired-do-copy'."
  (interactive)
  (if (and (fboundp 'evil-visual-state-p) (evil-visual-state-p))
      (my/dired--on-selection #'dired-do-copy)
    (dired-do-copy)))

(defun my/dired-home ()
  "Go to the home directory in this window."
  (interactive)
  (dired--find-possibly-alternative-file (expand-file-name "~/")))

(defun my/dired-terminal ()
  "Open a terminal in the current dired directory."
  (interactive)
  (let ((default-directory (dired-current-directory)))
    (my/ghostel-open-full-buffer)))

(defun my/dired-split (dir)
  "Show the current directory and DIR side by side in dired.
With two dired windows, C and R offer the other one as the target."
  (interactive
   (list (read-directory-name "Second pane: " (expand-file-name "~/") nil t)))
  (let ((here (if (derived-mode-p 'dired-mode) (dired-current-directory) default-directory)))
    (dired here)
    (with-selected-window (split-window-right)
      (dired dir))))

(require 'transient)

(transient-define-prefix my/dired-menu ()
  "Dired actions under the keys they are bound to in dired."
  [["Files"
    ("yy" "Copy" my/dired-copy)
    ("x"  "Cut" my/dired-cut)
    ("p"  "Paste" my/dired-paste)
    ("dd" "Trash" my/dired-delete)
    ("D"  "Delete for good" my/dired-delete-permanently)
    ("C"  "Copy to other pane" dired-do-copy)
    ("R"  "Move to other pane" my/dired-move)]
   ["Select"
    ("m" "Mark" dired-mark :transient t)
    ("u" "Unmark" dired-unmark :transient t)
    ("U" "Unmark all" dired-unmark-all-marks :transient t)
    ("t" "Invert" dired-toggle-marks :transient t)]
   ["Open"
    ("of" "File manager" my/show-in-file-manager)
    ("oa" "Default application" dired-do-open)
    ("ow" "Other window" dired-find-file-other-window)
    ("ot" "Terminal here" my/dired-terminal)]]
  [["Create & rename"
    ("+"  "Directory" dired-create-directory)
    ("%"  "File" dired-create-empty-file)
    ("cw" "Rename" my/dired-rename)
    ("i"  "Rename many (wdired)" wdired-change-to-wdired-mode)]
   ["Yank path"
    ("ya" "Absolute path" my/dired-copy-path)
    ("yn" "File name" my/dired-copy-name)]
   ["View"
    ("." "Hidden files" my/dired-toggle-hidden :transient t)
    ("(" "Details" dired-hide-details-mode :transient t)
    ("s" "Sort" dired-sort-toggle-or-edit :transient t)
    ("gr" "Refresh" revert-buffer)]
   ["Go"
    ("h" "Up" dired-up-directory)
    ("~" "Home" my/dired-home)
    ("DEL" "Back" my/dired-back)
    ("S-<backspace>" "Forward" my/dired-forward)]])

(defun my/dired-skip-matchit ()
  "Return non-nil in dired, where `%' creates a file instead of matching."
  (derived-mode-p 'dired-mode))

(advice-add 'turn-on-evil-matchit-mode :before-until #'my/dired-skip-matchit)

(with-eval-after-load 'dired
  (with-eval-after-load 'evil
    (evil-define-key* '(normal motion) dired-mode-map
      "c" nil
      "d" nil
      "o" nil
      "y" nil)
    (evil-define-key* '(normal motion) dired-mode-map
      "h"  #'dired-up-directory
      "l"  #'dired-find-file
      "~"  #'my/dired-home
      (kbd "DEL") #'my/dired-back
      (kbd "S-<backspace>") #'my/dired-forward
      "i"  #'wdired-change-to-wdired-mode
      "+"  #'dired-create-directory
      "%"  #'dired-create-empty-file
      "cw" #'my/dired-rename
      "dd" #'my/dired-delete
      "D"  #'my/dired-delete-permanently
      "R"  #'my/dired-move
      "yy" #'my/dired-copy
      "x"  #'my/dired-cut
      "p"  #'my/dired-paste
      "ya" #'my/dired-copy-path
      "yn" #'my/dired-copy-name
      "of" #'my/show-in-file-manager
      "oa" #'dired-do-open
      "ow" #'dired-find-file-other-window
      "ot" #'my/dired-terminal
      "s"  #'dired-sort-toggle-or-edit
      "."  #'my/dired-toggle-hidden
      "("  #'dired-hide-details-mode
      "?"  #'my/dired-menu)
    (evil-define-key* 'visual dired-mode-map
      "y" #'my/dired-copy
      "x" #'my/dired-cut
      "d" #'my/dired-delete
      "D" #'my/dired-delete-permanently
      "C" #'my/dired-copy-to-pane
      "R" #'my/dired-move))

  (with-eval-after-load 'which-key
    (which-key-add-major-mode-key-based-replacements 'dired-mode
      "c" "change"
      "d" "delete"
      "o" "open"
      "y" "yank")))

(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "d"  '(:ignore t :which-key "Dired")
      "dd" '(dired-jump :which-key "Dired (Current File)")
      "df" '(dired :which-key "Open Directory")
      "ds" '(my/dired-split :which-key "Split Panes"))))

(provide 'dired-keys)
