(let ((modules-dir (expand-file-name "modules" user-emacs-directory)))
  (add-to-list 'load-path modules-dir)
  (let ((default-directory modules-dir))
    (when (file-directory-p default-directory)
      (normal-top-level-add-subdirs-to-load-path))))

(require 'core)

(provide 'init)
