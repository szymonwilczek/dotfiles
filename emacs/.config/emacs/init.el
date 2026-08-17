(let ((modules-dir (expand-file-name "modules" user-emacs-directory)))
  (add-to-list 'load-path modules-dir)
  (dolist (dir (directory-files modules-dir t "^[^.]"))
    (when (file-directory-p dir)
      (add-to-list 'load-path dir))))

(require 'core)
(require 'evil-mod)
(require 'ui-mod)
(require 'completion-mod)

(provide 'init)
(custom-set-variables
 '(package-selected-packages nil))
(custom-set-faces
 )
