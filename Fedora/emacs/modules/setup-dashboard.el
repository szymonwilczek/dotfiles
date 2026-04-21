(setq inhibit-startup-message t
  inhibit-startup-screen t
  initial-scratch-message nil)

(use-package dashboard
  :ensure t
  :config

  (defun my/get-greeting ()
    (let ((hour (string-to-number (format-time-string "%H"))))
      (cond ((and (>= hour 5) (< hour 14)) "☀️ Good Morning!")
        ((and (>= hour 14) (< hour 18)) "☕ Good Afternoon.")
        ((and (>= hour 18) (< hour 23)) "🌙 Good Evening, time for coding?")
        (t "🦉 Night Owl..."))))

  (setq dashboard-startup-banner (expand-file-name "banners/cat-2.txt" user-emacs-directory))
  (setq dashboard-banner-logo-title (my/get-greeting))

  (setq dashboard-center-content t
    dashboard-vertically-center-content t
    dashboard-display-icons-p t
    dashboard-icon-type 'nerd-icons
    dashboard-set-heading-icons t
    dashboard-set-file-icons t)

  (setq dashboard-items '((recents . 10)))
  (setq dashboard-show-shortcuts nil)
  (setq dashboard-item-names '(("Recent Files:" . "Recent Files:")))
  (setq dashboard-set-footer nil)

  (defun my/dashboard-formatted-footer ()
    (format "%s %s | %s %s" 
      (nerd-icons-faicon "nf-fa-calendar")
      (format-time-string "%d.%m.%Y")
      (nerd-icons-faicon "nf-fa-clock")
      (format-time-string "%H:%M")))

  (setq dashboard-footer-messages (list (my/dashboard-formatted-footer)))
  (setq dashboard-footer-icon nil)

  ;; *scratch* kill
  (setq initial-buffer-choice (lambda () (get-buffer-create dashboard-buffer-name)))
  (add-hook 'emacs-startup-hook
    (lambda ()
      (when (get-buffer "*scratch*")
        (kill-buffer "*scratch*"))))

  (dashboard-setup-startup-hook))

(provide 'setup-dashboard)
