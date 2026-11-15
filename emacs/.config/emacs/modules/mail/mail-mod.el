;;; mu4e mail client and message sending -*- lexical-binding: t; -*-

;; Account definitions live outside my dotfiles repo.
;; ~/.config/mail/accounts.el sets `my/mail-accounts', a list of plists
;; with :name, :address and :fullname for each configured mailbox.

(defvar my/mail-accounts nil
  "Mail accounts loaded from ~/.config/mail/accounts.el.
Each entry is a plist (:name NAME :address EMAIL :fullname DISPLAY).")

(let ((accts (expand-file-name "~/.config/mail/accounts.el")))
  (when (file-readable-p accts)
    (load accts nil 'nomessage)))

(use-package message
  :ensure nil
  :custom
  (mail-user-agent 'mu4e-user-agent)
  (message-send-mail-function #'message-send-mail-with-sendmail)
  (sendmail-program (executable-find "msmtp"))
  (message-sendmail-envelope-from 'header)
  (message-sendmail-f-is-evil t)
  (message-kill-buffer-on-exit t)
  (message-sendmail-extra-arguments '("--read-envelope-from")))

(defun my/mail--build-contexts ()
  "Build `mu4e-context' list from `my/mail-accounts'."
  (mapcar
   (lambda (acct)
     (let ((name    (plist-get acct :name))
           (address (plist-get acct :address))
           (full    (plist-get acct :fullname)))
       (make-mu4e-context
        :name name
        :match-func
        (lambda (msg)
          (when msg
            (string-prefix-p (concat "/" name)
                             (mu4e-message-field msg :maildir))))
        :vars `((user-mail-address  . ,address)
                (user-full-name     . ,full)
                (mu4e-sent-folder   . ,(concat "/" name "/Sent"))
                (mu4e-drafts-folder . ,(concat "/" name "/Drafts"))
                (mu4e-trash-folder  . ,(concat "/" name "/Trash"))
                (mu4e-refile-folder . ,(concat "/" name "/INBOX"))))))
   my/mail-accounts))

(defun my/mail--sync-command ()
  "Build mbsync command string from configured accounts."
  (concat "mbsync "
          (mapconcat (lambda (a) (plist-get a :name))
                     my/mail-accounts " ")))

(use-package mu4e
  :ensure nil
  :load-path "/usr/share/emacs/site-lisp/mu4e"
  :commands (mu4e mu4e-compose-new mu4e-update-mail-and-index)
  :custom

  ;; Paths
  (mu4e-maildir (expand-file-name "~/.local/share/mail"))
  (mu4e-attachment-dir (expand-file-name "~/Pobrane"))

  ;; Display
  (mu4e-headers-date-format "%d/%m/%y")
  (mu4e-headers-time-format "%H:%M")
  (mu4e-headers-fields '((:human-date . 12)
                         (:flags      .  6)
                         (:from-or-to . 25)
                         (:subject    . nil)))
  (mu4e-use-fancy-chars t)
  (mu4e-modeline-show-global nil)

  ;; Compose
  (mu4e-compose-dont-reply-to-self t)
  (mu4e-compose-format-flowed t)

  ;; Behaviour
  (mu4e-confirm-quit nil)
  (mu4e-change-filenames-when-moving t)

  ;; Sync
  (mu4e-update-interval 300)
  (mu4e-index-update-in-background t)
  (mu4e-hide-index-messages t)

  ;; Bookmarks
  (mu4e-bookmarks
   '((:name "All Inboxes"  :query "maildir:/.*INBOX/ AND NOT flag:trashed"
            :key ?i)
     (:name "Unread"       :query "flag:unread AND NOT flag:trashed"
            :key ?u :favorite t)
     (:name "Today"        :query "date:today..now AND NOT flag:trashed"
            :key ?t)
     (:name "Last 7 days"  :query "date:7d..now AND NOT flag:trashed"
            :key ?w)
     (:name "Flagged"      :query "flag:flagged"
            :key ?f)))

  :config
  (setq mu4e-get-mail-command (my/mail--sync-command))
  (setq mu4e-contexts (my/mail--build-contexts))
  (setq mu4e-context-policy 'pick-first
        mu4e-compose-context-policy 'ask-if-none))

(defun my/mail-open-inbox ()
  "Open unified INBOX for all configured mailboxes in mu4e."
  (interactive)
  (require 'mu4e)
  (let ((query "maildir:/.*INBOX/ AND NOT flag:trashed"))
    (if (and (fboundp 'mu4e-running-p) (mu4e-running-p))
        (mu4e-search query)
      (mu4e--start (lambda () (mu4e-search query))))))

(provide 'mail-mod)
