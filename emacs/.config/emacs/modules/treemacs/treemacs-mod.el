;;; Treemacs file explorer configuration -*- lexical-binding: t; -*-

(defun my/file-manager--target ()
  "Return the path `my/show-in-file-manager' should reveal."
  (cond
   ((derived-mode-p 'treemacs-mode)
    (let ((path (treemacs--prop-at-point :path)))
      (unless (stringp path)
        (user-error "No file or directory at point"))
      path))
   ((derived-mode-p 'dired-mode)
    (or (dired-get-filename nil t) default-directory))
   (buffer-file-name)
   (t default-directory)))

(defun my/show-in-file-manager (&optional path)
  "Reveal PATH in the system file manager.
A directory opens as itself; a file opens its parent with the file
selected.  PATH defaults to the treemacs/dired node at point, then the
visited file, then `default-directory'.  Uses the freedesktop
FileManager1 D-Bus interface), falling back to xdg-open, macOS `open'
or Windows Explorer."
  (interactive)
  (let* ((path (directory-file-name
                (expand-file-name (or path (my/file-manager--target)))))
         (dir-p (file-directory-p path)))
    (when (file-remote-p path)
      (user-error "Remote path: %s" path))
    (unless (file-exists-p path)
      (user-error "No such file: %s" path))
    (cond
     ((and (featurep 'dbusbind)
           (require 'dbus nil t)
           (require 'url-util)
           (ignore-errors
             (dbus-call-method
              :session "org.freedesktop.FileManager1"
              "/org/freedesktop/FileManager1" "org.freedesktop.FileManager1"
              (if dir-p "ShowFolders" "ShowItems")
              (list :array (concat "file://"
                                   (url-hexify-string path url-path-allowed-chars)))
              "")
             t)))
     ((eq system-type 'darwin)
      (if dir-p
          (call-process "open" nil 0 nil path)
        (call-process "open" nil 0 nil "-R" path)))
     ((eq system-type 'windows-nt)
      (let ((win (subst-char-in-string ?/ ?\\ path)))
        (if dir-p
            (call-process "explorer" nil 0 nil win)
          (call-process "explorer" nil 0 nil (concat "/select," win)))))
     (t
      (call-process "xdg-open" nil 0 nil
                    (if dir-p path (file-name-directory path)))))
    (message "File manager: %s" (abbreviate-file-name path))))

(use-package treemacs
  :ensure t
  :config
  (setq treemacs-no-png-images t
        treemacs-width 35
        treemacs-indentation 2
        treemacs-show-cursor nil
        treemacs-space-between-root-nodes nil
        treemacs-is-never-other-window nil
        treemacs-persist-file nil)

  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-fringe-indicator-mode nil)

  (add-hook 'treemacs-mode-hook (lambda () (display-line-numbers-mode -1))))

(use-package treemacs-evil
  :ensure t
  :after (treemacs evil))

(use-package treemacs-nerd-icons
  :ensure t
  :after (treemacs nerd-icons)
  :config
  (treemacs-load-theme "nerd-icons"))

(require 'treemacs-keys)

(provide 'treemacs-mod)
