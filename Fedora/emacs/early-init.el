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
