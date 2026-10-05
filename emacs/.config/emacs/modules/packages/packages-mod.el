;;; Package updates and live reloading -*- lexical-binding: t; -*-

;; M-x repack picks an installed package, then updates and reloads it,
;; or only reloads it, without restarting Emacs.
;;
;; Updating a VC package pulls its checkout and rebuilds it,
;; an archive package is upgraded from its archive.
;; Reloading loads again every file of the package loaded so far,
;; in the original order, so redefined functions take effect at once.
;; Variables already set by `defvar' and `defcustom' keep their values.

(require 'package)
(require 'package-vc)

(defconst my/repack-own-url-re "github\\.com[:/]szymonwilczek/"
  "Remote URLs matching this regexp mark packages I maintain.")

(defun my/repack--desc (name)
  "Return the installed package description of NAME."
  (cadr (assq name package-alist)))

(defun my/repack--git (dir &rest args)
  "Run git ARGS in DIR and return its first output line, or nil."
  (let ((default-directory (file-name-as-directory dir)))
    (car (ignore-errors (apply #'process-lines "git" args)))))

(defun my/repack--kind (desc)
  "Return `own', `vc' or `archive' for package DESC."
  (cond ((not (package-vc-p desc)) 'archive)
        ((string-match-p my/repack-own-url-re
                         (or (my/repack--git (package-desc-dir desc)
                                             "remote" "get-url" "origin")
                             ""))
         'own)
        (t 'vc)))

(defun my/repack--annotation (desc)
  "Return the version or revision of DESC for the minibuffer."
  (if (package-vc-p desc)
      (or (my/repack--git (package-desc-dir desc) "rev-parse" "--short" "HEAD")
          "")
    (concat (package-version-join (package-desc-version desc))
            (when-let* ((archive (package-desc-archive desc)))
              (concat "  " archive)))))

(defun my/repack--read ()
  "Read an installed package, my own packages first."
  (let* ((rank '((own . 0) (vc . 1) (archive . 2)))
         (groups '((own . "My packages") (vc . "VC packages")
                   (archive . "Archive packages")))
         (cands
          (sort (mapcar (lambda (entry)
                          (let ((desc (cadr entry)))
                            (list (symbol-name (car entry))
                                  (my/repack--kind desc)
                                  (my/repack--annotation desc))))
                        package-alist)
                (lambda (a b)
                  (let ((ra (alist-get (nth 1 a) rank))
                        (rb (alist-get (nth 1 b) rank)))
                    (if (= ra rb) (string< (car a) (car b)) (< ra rb))))))
         (table
          (lambda (str pred action)
            (if (eq action 'metadata)
                `(metadata
                  (category . repack-package)
                  (display-sort-function . identity)
                  (group-function
                   . ,(lambda (cand transform)
                        (if transform cand
                          (alist-get (nth 1 (assoc cand cands)) groups))))
                  (annotation-function
                   . ,(lambda (cand)
                        (concat (propertize " " 'display '(space :align-to 32))
                                (propertize (nth 2 (assoc cand cands))
                                            'face 'completions-annotations)))))
              (complete-with-action action cands str pred)))))
    (intern (completing-read "Repack: " table nil t))))

(defun my/repack--loaded-files (desc)
  "Return files of DESC in `load-history', relative and oldest first."
  (let ((dir (file-name-as-directory (package-desc-dir desc)))
        files)
    ;; `load-history' lists the most recent load first
    (dolist (entry load-history)
      (let ((file (car entry)))
        (when (and (stringp file)
                   (string-prefix-p dir file)
                   (string-match-p "\\.elc?\\'" file))
          (push (file-name-sans-extension (file-relative-name file dir))
                files))))
    (delete-dups files)))

(defun my/repack--reload (name files)
  "Load FILES of package NAME again from its current directory."
  (let ((dir (package-desc-dir (my/repack--desc name)))
        (load-prefer-newer t)
        (loaded 0)
        failed)
    (dolist (file files)
      (condition-case err
          (when (load (expand-file-name file dir) t t)
            (setq loaded (1+ loaded)))
        (error (push (format "%s: %s" file (error-message-string err))
                     failed))))
    (cond (failed
           (message "repack: %s reloaded with errors: %s"
                    name (string-join (nreverse failed) "; ")))
          ((zerop loaded)
           (message "repack: %s is not loaded yet, next use picks up the new code"
                    name))
          (t (message "repack: %s reloaded (%d files)" name loaded)))))

(defconst my/repack--update-script "
set -e
if [ -n \"$1\" ]; then git checkout --quiet \"$1\"; fi
upstream=$(git rev-parse --symbolic-full-name @{u})
# fresh clone has no reflog for the remote branch yet
before=$(git rev-parse \"$upstream\")
git fetch --quiet
# HEAD is, or is behind, an earlier tip of the remote branch;
# the reflog holds both the old and the new tip of each update
was_upstream() {
    log=$(git rev-parse --git-path \"logs/$upstream\")
    for c in $before $([ -f \"$log\" ] && cut -d' ' -f1,2 \"$log\"); do
        git merge-base --is-ancestor HEAD \"$c\" && return 0
    done
    return 1
}
if git merge-base --is-ancestor HEAD @{u}; then
    git merge --quiet --ff-only @{u}
elif was_upstream; then
    if [ -n \"$(git status --porcelain --untracked-files=no)\" ]; then
        echo 'Uncommitted changes, not resetting:'
        git status --short --untracked-files=no
        exit 1
    fi
    echo \"Remote history was rewritten, moving to $(git rev-parse --short @{u})\"
    git reset --quiet --hard @{u}
else
    echo 'Local commits that were never on the remote:'
    git log --oneline @{u}..HEAD
    exit 1
fi"
  "Shell script bringing a package checkout up to its remote branch.
Its first argument names a branch to check out first, or is empty.")

(defun my/repack--update-vc (desc then)
  "Update the checkout of DESC, rebuild it if it changed, then call THEN.
A checkout on a detached HEAD, as left by installing a release,
first switches to the default branch of its remote.
Remote history rewritten by a force push replaces the checkout's
history, unless the checkout has commits or changes of its own."
  (let* ((name (package-desc-name desc))
         (dir (package-desc-dir desc))
         (before (my/repack--git dir "rev-parse" "HEAD"))
         (branch (unless (my/repack--git dir "symbolic-ref" "-q" "--short" "HEAD")
                   (string-remove-prefix
                    "origin/"
                    (or (my/repack--git dir "symbolic-ref" "-q" "--short"
                                        "refs/remotes/origin/HEAD")
                        "origin/main"))))
         (buffer (get-buffer-create (format " *repack: %s*" name)))
         (default-directory (file-name-as-directory dir)))
    (with-current-buffer buffer (erase-buffer))
    (message "repack: updating %s..." name)
    (make-process
     :name (format "repack-%s" name)
     :buffer buffer
     :command (list "sh" "-c" my/repack--update-script "sh" (or branch ""))
     :sentinel
     (lambda (proc _event)
       (when (memq (process-status proc) '(exit signal))
         (if (/= (process-exit-status proc) 0)
             (progn
               (display-buffer buffer)
               (message "repack: updating %s failed" name))
           (if (equal before (my/repack--git dir "rev-parse" "HEAD"))
               (message "repack: %s is already up to date" name)
             (package-vc-rebuild desc))
           (funcall then)))))))

(defun my/repack--update-archive (desc then)
  "Upgrade DESC from its package archive, then call THEN."
  (let ((name (package-desc-name desc)))
    (package-refresh-contents)
    (let ((available (cadr (assq name package-archive-contents))))
      (if (and available
               (version-list-< (package-desc-version desc)
                               (package-desc-version available)))
          (package-upgrade name)
        (message "repack: %s is already up to date" name)))
    (funcall then)))

;;;###autoload
(defun repack (name action)
  "Update and reload, or only reload, the installed package NAME.
ACTION is `update' or `reload'."
  (interactive
   (let ((name (my/repack--read)))
     (list name
           (pcase (car (read-multiple-choice
                        (format "%s: " name)
                        '((?u "update" "Pull or upgrade, then reload")
                          (?r "reload" "Reload the installed code"))))
             (?u 'update)
             (?r 'reload)))))
  (let* ((desc (or (my/repack--desc name)
                   (user-error "repack: %s is not installed" name)))
         ;; collected before updating, an archive upgrade
         ;; moves the package to a new directory
         (files (my/repack--loaded-files desc))
         (reload (lambda () (my/repack--reload name files))))
    (pcase action
      ('reload (funcall reload))
      ('update (if (package-vc-p desc)
                   (my/repack--update-vc desc reload)
                 (my/repack--update-archive desc reload))))))

(provide 'packages-mod)
