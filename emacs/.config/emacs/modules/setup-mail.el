(require 'use-package)
(require 'cl-lib)

(add-to-list 'load-path "/usr/share/emacs/site-lisp/mu4e")

(require 'private-mail nil t)

(use-package mu4e
  :ensure nil
  :config
  (setq mu4e-maildir (expand-file-name "~/Mail"))
  
  (setq sendmail-program "msmtp"
        send-mail-function 'smtpmail-send-it
        message-sendmail-f-is-evil t
        message-sendmail-extra-arguments '("--read-envelope-from")
        message-send-mail-function 'message-send-mail-with-sendmail)

  (setq mu4e-get-mail-command "mbsync -a"
        mu4e-update-interval 300)

  (setq mu4e-attachment-dir  "~/Pobrane"
        mu4e-change-filenames-when-moving t
        mu4e-context-policy 'pick-first
        mu4e-compose-context-policy 'ask)

  (when (boundp 'my/mail-accounts)
    (setq mu4e-contexts
          (cl-loop for account in my/mail-accounts
                   for ctx-name = (car account)
                   for props    = (cdr account)
                   for dir      = (plist-get props :dir)
                   collect
                   (make-mu4e-context
                    :name ctx-name
                    :match-func
                    `(lambda (msg)
                       (when msg (string-prefix-p ,dir (mu4e-message-field msg :maildir))))
                    :vars `((user-mail-address  . ,(plist-get props :address))
                            (user-full-name     . ,(plist-get props :name))
                            (mu4e-drafts-folder . ,(plist-get props :drafts))
                            (mu4e-sent-folder   . ,(plist-get props :sent))
                            (mu4e-trash-folder  . ,(plist-get props :trash))
                            (mu4e-refile-folder . ,(plist-get props :archive)))))))

  )

(provide 'setup-mail)
