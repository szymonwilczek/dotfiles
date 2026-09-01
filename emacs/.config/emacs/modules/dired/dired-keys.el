;;; Dired Evil keybindings -*- lexical-binding: t; -*-

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

(with-eval-after-load 'dired
  (with-eval-after-load 'evil
    (evil-define-key* '(normal visual motion) dired-mode-map
      "h"  #'dired-up-directory
      "l"  #'dired-find-file
      "i"  #'wdired-change-to-wdired-mode
      "("  #'dired-hide-details-mode
      "Y"  #'my/dired-copy-path
      "gy" #'my/dired-copy-name)))

(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "d"  '(:ignore t :which-key "Dired")
      "dd" '(dired-jump :which-key "Dired (Current File)")
      "df" '(dired :which-key "Open Directory"))))

(provide 'dired-keys)
