;;; Sending mail through msmtp -*- lexical-binding: t; -*-

(defun my/mail-msmtp-from ()
  "Return the from address of the msmtp config, or nil."
  (let ((file (expand-file-name "~/.config/msmtp/config")))
    (when (file-readable-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (when (re-search-forward "^from[ \t]+\\(\\S-+\\)" nil t)
          (match-string 1))))))

(use-package message
  :ensure nil
  :custom
  (mail-user-agent 'message-user-agent)
  (message-send-mail-function #'message-send-mail-with-sendmail)
  (sendmail-program (executable-find "msmtp"))
  (message-sendmail-envelope-from 'header)
  (message-sendmail-f-is-evil nil)
  (message-kill-buffer-on-exit t)
  :config
  (when-let* ((from (my/mail-msmtp-from)))
    (setq user-mail-address from)))

(provide 'mail-mod)
