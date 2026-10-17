;;; Dashboard of installed packages for repack -*- lexical-binding: t; -*-

;; M-x repack-status lists the installed packages and checks them for
;; updates at once: VC checkouts are fetched, archives are refreshed.
;; Updating a package there rebuilds and reloads it like M-x repack.
;; Packages installed from a local checkout are left out.

(require 'cl-lib)
(require 'package)
(require 'transient)

(defvar my/repack-status--state (make-hash-table)
  "Check results of each package name, as plists.")

(defvar my/repack-status--open nil
  "Names of packages whose details are shown.")

(defvar my/repack-status--only-updates nil
  "Non-nil lists only packages with an update available.")

(defconst my/repack-status--glyphs
  '((checking "⟳" shadow) (busy "⟳" warning) (ok "✓" success)
    (update "↑" font-lock-keyword-face) (local "⚠" warning) (error "✗" error))
  "Glyph and face of each package status.")

(defconst my/repack-status--check-script "
git fetch --quiet || exit 1
ref=$(git rev-parse -q --verify '@{u}' || git rev-parse -q --verify origin/HEAD) || exit 1
echo $ref $(git rev-list --count HEAD..$ref) $(git rev-list --count $ref..HEAD) \\
     $(git status --porcelain --untracked-files=no | wc -l)"
  "Shell script fetching a checkout and comparing it with its remote.
It prints the remote commit, then the commits behind and ahead of it
and the number of changed files.")

(defun my/repack-status--packages ()
  "Return `package-alist' without packages installed from a checkout."
  (cl-remove-if (lambda (entry)
                  (file-symlink-p
                   (directory-file-name (package-desc-dir (cadr entry)))))
                package-alist))

(defun my/repack-status--version (desc)
  "Return the installed version or revision of DESC."
  (if (package-vc-p desc)
      (or (my/repack--git (package-desc-dir desc) "rev-parse" "--short" "HEAD")
          "")
    (package-version-join (package-desc-version desc))))

(defun my/repack-status--refresh ()
  "Redraw the dashboard, keeping point on the same package."
  (when-let* ((buffer (get-buffer "*repack*")))
    (with-selected-window (or (get-buffer-window buffer t) (selected-window))
      (with-current-buffer buffer
        (when (derived-mode-p 'my/repack-status-mode)
          (tabulated-list-print t))))))

(defun my/repack-status--update (name &rest props)
  "Merge PROPS into the state of NAME and redraw."
  (let ((state (gethash name my/repack-status--state)))
    (while props
      (setq state (plist-put state (pop props) (pop props))))
    (puthash name state my/repack-status--state))
  (my/repack-status--refresh))

(defun my/repack-status--check-vc (name desc)
  "Fetch the checkout of DESC and record whether NAME can be updated."
  (let ((default-directory (file-name-as-directory (package-desc-dir desc)))
        (buffer (generate-new-buffer " *repack-check*")))
    (make-process
     :name (format "repack-check-%s" name)
     :buffer buffer
     :noquery t
     :command (list "sh" "-c" my/repack-status--check-script)
     :sentinel
     (lambda (proc _event)
       (when (memq (process-status proc) '(exit signal))
         (let ((out (with-current-buffer buffer (string-trim (buffer-string)))))
           (kill-buffer buffer)
           (if (/= (process-exit-status proc) 0)
               (my/repack-status--update name :status 'error
                                         :info "check failed" :log out)
             (pcase-let ((`(,ref . ,counts) (split-string out)))
               (pcase-let ((`(,behind ,ahead ,dirty)
                            (mapcar #'string-to-number counts)))
                 (apply #'my/repack-status--update name :ref ref
                        (cond ((or (> ahead 0) (> dirty 0))
                               (list :status 'local
                                     :info (format "%d local commits, %d changed files, %d behind"
                                                   ahead dirty behind)))
                              ((> behind 0)
                               (list :status 'update
                                     :info (format "+%d commits" behind)))
                              (t (list :status 'ok :info "")))))))))))))

(defun my/repack-status--compare-archive (name desc)
  "Record whether the archive offers a newer version of NAME than DESC."
  (let ((available (cadr (assq name package-archive-contents))))
    (if (and available
             (version-list-< (package-desc-version desc)
                             (package-desc-version available)))
        (let ((version (package-version-join (package-desc-version available))))
          (my/repack-status--update name :status 'update :available version
                                    :info (concat "→ " version)))
      (my/repack-status--update name :status 'ok :info ""))))

(defun my/repack-status--check-one (name &optional fresh)
  "Check NAME for an update, forgetting earlier results if FRESH."
  (let ((desc (my/repack--desc name)))
    (when fresh (remhash name my/repack-status--state))
    (my/repack-status--update name :status 'checking :info "" :log nil
                              :kind (my/repack--kind desc)
                              :installed (my/repack-status--version desc))
    (if (package-vc-p desc)
        (my/repack-status--check-vc name desc)
      ;; archive contents stay fresh from the last check
      (unless fresh (my/repack-status--compare-archive name desc)))))

(defun my/repack-status-check ()
  "Check every listed package for an update."
  (interactive)
  (let ((names (mapcar #'car (my/repack-status--packages))))
    (dolist (name names) (my/repack-status--check-one name t))
    (letrec ((done (lambda ()
                     (remove-hook 'package--post-download-archives-hook done)
                     (dolist (name names)
                       (let ((desc (my/repack--desc name)))
                         (unless (package-vc-p desc)
                           (my/repack-status--compare-archive name desc)))))))
      (add-hook 'package--post-download-archives-hook done)
      (package-refresh-contents t))))

(defun my/repack-status--update-package (name)
  "Update NAME, reload it and check it again."
  (let* ((desc (my/repack--desc name))
         ;; collected before updating, an archive upgrade
         ;; moves the package to a new directory
         (files (my/repack--loaded-files desc))
         (done (lambda ()
                 (my/repack--reload name files)
                 (my/repack-status--update name :reloaded t)
                 (my/repack-status--check-one name)))
         (fail (lambda (log)
                 (my/repack-status--update name :status 'error
                                           :info "update failed" :log log))))
    (unless (eq (plist-get (gethash name my/repack-status--state) :status) 'busy)
      (my/repack-status--update name :status 'busy :info "updating…")
      (if (package-vc-p desc)
          (my/repack--update-vc
           desc done
           (lambda ()
             (funcall fail (with-current-buffer (format " *repack: %s*" name)
                             (buffer-string)))))
        (condition-case err
            (progn (package-upgrade name) (funcall done))
          (error (funcall fail (error-message-string err))))))))

(defun my/repack-status--entries ()
  "Return the dashboard rows, updates first in each kind."
  (let ((rank '((own . 0) (vc . 1) (archive . 2)))
        (urgency '((update . 0) (local . 1) (error . 2)))
        rows)
    (pcase-dolist (`(,name . ,_) (my/repack-status--packages))
      (let* ((state (gethash name my/repack-status--state))
             (status (or (plist-get state :status) 'checking))
             (glyph (alist-get status my/repack-status--glyphs))
             (info (plist-get state :info)))
        (unless (or (null state)
                    (and my/repack-status--only-updates (not (eq status 'update))))
          (push (list name
                      (vector (propertize (car glyph) 'face (cadr glyph))
                              (symbol-name name)
                              (symbol-name (plist-get state :kind))
                              (or (plist-get state :installed) "")
                              (if (and (eq status 'ok) (plist-get state :reloaded))
                                  "reloaded"
                                (or info "")))
                      (list (alist-get (plist-get state :kind) rank)
                            (alist-get status urgency 3)
                            (symbol-name name)))
                rows))))
    (mapcar #'butlast
            (sort rows (lambda (a b)
                         (let ((ka (nth 2 a)) (kb (nth 2 b)))
                           (cond ((/= (nth 0 ka) (nth 0 kb)) (< (nth 0 ka) (nth 0 kb)))
                                 ((/= (nth 1 ka) (nth 1 kb)) (< (nth 1 ka) (nth 1 kb)))
                                 (t (string< (nth 2 ka) (nth 2 kb))))))))))

(defun my/repack-status--details (name)
  "Return the detail lines of NAME: new commits, a log or its summary."
  (let* ((state (gethash name my/repack-status--state))
         (desc (my/repack--desc name))
         (dir (package-desc-dir desc))
         (ref (plist-get state :ref))
         (log (lambda (range)
                (let ((default-directory (file-name-as-directory dir)))
                  (ignore-errors
                    (process-lines "git" "log" "--format=%h %s" range))))))
    (or (when-let* ((text (plist-get state :log)))
          (split-string text "\n" t))
        (when (and ref (package-vc-p desc))
          (append (funcall log (concat "HEAD.." ref))
                  (mapcar (lambda (line) (concat "local: " line))
                          (funcall log (concat ref "..HEAD")))))
        (when-let* ((available (plist-get state :available)))
          (list (format "%s → %s" (plist-get state :installed) available)))
        (list (package-desc-summary desc)))))

(defun my/repack-status--print-entry (id cols)
  "Print the row ID with COLS, and its details when they are open."
  (tabulated-list-print-entry id cols)
  (when (memq id my/repack-status--open)
    (let ((start (point)))
      (dolist (line (my/repack-status--details id))
        (insert "      " line "\n"))
      ;; lets the commands act on the package from its details too
      (put-text-property start (point) 'tabulated-list-id id))))

(defun my/repack-status--targets ()
  "Return the packages of the visual selection, or the one at point."
  (if (and (fboundp 'evil-visual-state-p) (evil-visual-state-p))
      (let ((beg (region-beginning)) (end (region-end)) names)
        (evil-exit-visual-state)
        (save-excursion
          (goto-char beg)
          (while (< (point) end)
            (when-let* ((id (tabulated-list-get-id)))
              (cl-pushnew id names))
            (forward-line 1)))
        (nreverse names))
    (list (or (tabulated-list-get-id) (user-error "No package here")))))

(defun my/repack-status-update ()
  "Update and reload the package at point or the selected ones."
  (interactive)
  (mapc #'my/repack-status--update-package (my/repack-status--targets)))

(defun my/repack-status-update-all ()
  "Update and reload every package with an update available."
  (interactive)
  (let (names)
    (maphash (lambda (name state)
               (when (eq (plist-get state :status) 'update) (push name names)))
             my/repack-status--state)
    (unless names (user-error "Nothing to update"))
    (when (y-or-n-p (format "Update %d packages? " (length names)))
      (mapc #'my/repack-status--update-package names))))

(defun my/repack-status-reload ()
  "Reload the package at point or the selected ones."
  (interactive)
  (dolist (name (my/repack-status--targets))
    (my/repack--reload name (my/repack--loaded-files (my/repack--desc name)))))

(defun my/repack-status-toggle-details ()
  "Show or hide the details of the package at point."
  (interactive)
  (let ((name (or (tabulated-list-get-id) (user-error "No package here"))))
    (setq my/repack-status--open
          (if (memq name my/repack-status--open)
              (delq name my/repack-status--open)
            (cons name my/repack-status--open)))
    (my/repack-status--refresh)))

(defun my/repack-status-toggle-filter ()
  "List only packages with an update available, or all of them."
  (interactive)
  (setq my/repack-status--only-updates (not my/repack-status--only-updates))
  (my/repack-status--refresh))

(defun my/repack-status-open-dir ()
  "Open the directory of the package at point in Dired."
  (interactive)
  (dired (package-desc-dir (my/repack--desc (car (my/repack-status--targets))))))

(defun my/repack-status-open-homepage ()
  "Open the homepage of the package at point in a browser."
  (interactive)
  (let ((desc (my/repack--desc (car (my/repack-status--targets)))))
    (browse-url (or (alist-get :url (package-desc-extras desc))
                    (user-error "%s has no homepage" (package-desc-name desc))))))

(transient-define-prefix my/repack-status-menu ()
  "Commands of the repack dashboard."
  [["Update"
    ("u" "Update" my/repack-status-update)
    ("U" "Update all" my/repack-status-update-all)
    ("r" "Reload" my/repack-status-reload)
    ("C" "Check again" my/repack-status-check)]
   ["View"
    ("RET" "Details" my/repack-status-toggle-details)
    ("f" "Only updates" my/repack-status-toggle-filter)]
   ["Open"
    ("od" "Directory" my/repack-status-open-dir)
    ("oh" "Homepage" my/repack-status-open-homepage)]])

(define-derived-mode my/repack-status-mode tabulated-list-mode "Repack"
  "Major mode of the repack dashboard."
  (setq tabulated-list-format [("" 1 nil) ("Package" 22 t) ("Kind" 8 t)
                               ("Installed" 14 nil) ("Status" 0 nil)]
        tabulated-list-padding 1
        tabulated-list-printer #'my/repack-status--print-entry
        tabulated-list-entries #'my/repack-status--entries)
  (tabulated-list-init-header))

(with-eval-after-load 'evil
  (evil-set-initial-state 'my/repack-status-mode 'normal)
  (evil-define-key* 'normal my/repack-status-mode-map
    "u"             #'my/repack-status-update
    "U"             #'my/repack-status-update-all
    "r"             #'my/repack-status-reload
    "C"             #'my/repack-status-check
    (kbd "RET")     #'my/repack-status-toggle-details
    (kbd "TAB")     #'my/repack-status-toggle-details
    (kbd "<tab>")   #'my/repack-status-toggle-details
    "f"             #'my/repack-status-toggle-filter
    "od"            #'my/repack-status-open-dir
    "oh"            #'my/repack-status-open-homepage
    "?"             #'my/repack-status-menu
    "q"             #'quit-window)
  (evil-define-key* 'visual my/repack-status-mode-map
    "u" #'my/repack-status-update
    "r" #'my/repack-status-reload))

;;;###autoload
(defun repack-status ()
  "Show installed packages, check them for updates and update them."
  (interactive)
  (switch-to-buffer (get-buffer-create "*repack*"))
  (my/repack-status-mode)
  (my/repack-status-check))

(provide 'repack-status)
