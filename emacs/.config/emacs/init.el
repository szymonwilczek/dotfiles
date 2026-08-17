(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))

(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))
(package-initialize)

(setq inhibit-startup-screen t)

(provide 'init)
