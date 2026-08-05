(add-to-list 'default-frame-alist '(fullscreen . maximized))

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)

(defvar my-bg-cache-file (expand-file-name ".bg-cache" user-emacs-directory))

(let ((bg-color (if (file-exists-p my-bg-cache-file)
                  (with-temp-buffer
                    (insert-file-contents my-bg-cache-file)
                    (string-trim (buffer-string)))
                  "#1e1e2e")))
  (when (and bg-color (string-prefix-p "#" bg-color))
    (push `(background-color . ,bg-color) default-frame-alist)))

(setq gc-cons-threshold most-positive-fixnum)
(setq package-enable-at-startup nil)


;; Disable lockfiles (.#filename) and redirect auto-saves (#filename#) away from Git repos
(setq create-lockfiles nil)
(setq make-backup-files nil)
(setq auto-save-default nil)
(setq auto-save-list-file-prefix nil)

(let ((auto-save-dir (expand-file-name "auto-save/" user-emacs-directory)))
  (make-directory auto-save-dir t)
  (setq auto-save-file-name-transforms `((".*" ,auto-save-dir t))))

;; Startup speed, annoyance suppression
(setq inhibit-startup-screen t
  inhibit-startup-message t
  inhibit-startup-echo-area-message user-login-name)

(setq frame-inhibit-implied-resize t)
