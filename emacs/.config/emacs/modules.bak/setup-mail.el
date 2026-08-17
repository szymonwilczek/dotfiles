(require 'use-package)

(require 'private-mail nil t)

(setq user-mail-address "szymonwilczek@outlook.com"
      user-full-name "Szymon Wilczek")

(defun my/mail-sync-and-refresh ()
  "Natychmiast odśwież widok Notmucha i pobierz nową pocztę w tle."
  (interactive)
  (message "Pobieranie nowej poczty...")
  (ignore-errors
    (if (eq major-mode 'notmuch-hello-mode)
        (notmuch-hello-update)
      (when (eq major-mode 'notmuch-search-mode)
        (notmuch-search-refresh-view))))
  (make-process
   :name "mail-sync-async"
   :buffer nil
   :command '("sh" "-c" "mbsync -a && notmuch new")
   :sentinel
   (lambda (p _event)
     (when (eq (process-status p) 'exit)
       (message "Poczta zsynchronizowana.")
       (ignore-errors
         (when (get-buffer "*notmuch-hello*")
           (with-current-buffer "*notmuch-hello*"
             (notmuch-hello-update))))
       (ignore-errors
         (dolist (buf (buffer-list))
           (with-current-buffer buf
             (when (eq major-mode 'notmuch-search-mode)
               (notmuch-search-refresh-view)))))))))

(defun my/open-mail ()
  "Otwiera pocztę Notmuch i od razu synchronizuje."
  (interactive)
  (notmuch)
  (my/mail-sync-and-refresh))


(use-package notmuch
  :ensure t
  :bind ("<leader>om" . my/open-mail)
  :config
  (setq notmuch-search-oldest-first nil
        notmuch-show-empty-saved-searches t
        notmuch-always-prompt-for-sender t)

  (setq notmuch-hello-sections
        '(notmuch-hello-insert-saved-searches
          notmuch-hello-insert-search
          notmuch-hello-insert-recent-searches
          notmuch-hello-insert-alltags
          notmuch-hello-insert-footer))

  (setq notmuch-saved-searches
        '((:name "📥 Wszystkie Nowe (Unified [i]nbox)" :query "tag:inbox and tag:unread" :sort-order newest-first :key "i")
          (:name "📬 szymonwilczek@[o]utlook.com"      :query "path:outlook-main/** and tag:inbox" :sort-order newest-first :key "o")
          (:name "🎓 sw312468@student.[p]olsl.pl"      :query "path:polsl/** and tag:inbox" :sort-order newest-first :key "p")
          (:name "✉️ [k]azikwilczek7@gmail.com"        :query "path:gmail-kazik/** and tag:inbox" :sort-order newest-first :key "k")
          (:name "✉️ swilczek.[l]x@gmail.com"          :query "path:gmail-swilczek/** and tag:inbox" :sort-order newest-first :key "l")
          (:name "🍎 szymonwilczek@iclo[u]d.com"       :query "path:icloud/** and tag:inbox" :sort-order newest-first :key "u")
          (:name "📥 Wszystkie Wiadomości ([a]ll)"     :query "tag:inbox" :sort-order newest-first :key "a")))

  (setq sendmail-program "msmtp"
        send-mail-function 'smtpmail-send-it
        message-sendmail-f-is-evil t
        message-sendmail-extra-arguments '("--read-envelope-from")
        message-send-mail-function 'message-send-mail-with-sendmail)

  (setq notmuch-identities
        '("Szymon Wilczek <szymonwilczek@outlook.com>"
          "Szymon Wilczek <sw312468@student.polsl.pl>"
          "Szymon Wilczek <kazikwilczek7@gmail.com>"
          "Szymon Wilczek <swilczek.lx@gmail.com>"
          "Szymon Wilczek <szymonwilczek@icloud.com>")
        message-alternative-emails
        '("sw312468@student.polsl.pl"
          "kazikwilczek7@gmail.com"
          "swilczek.lx@gmail.com"
          "szymonwilczek@icloud.com"))

  (with-eval-after-load 'evil
    (evil-set-initial-state 'notmuch-hello-mode 'normal)
    (evil-set-initial-state 'notmuch-search-mode 'normal)
    (evil-set-initial-state 'notmuch-show-mode 'normal)

    (evil-define-key 'normal notmuch-hello-mode-map
      "i" (lambda () (interactive) (notmuch-search "tag:inbox and tag:unread"))
      "o" (lambda () (interactive) (notmuch-search "path:outlook-main/** and tag:inbox"))
      "p" (lambda () (interactive) (notmuch-search "path:polsl/** and tag:inbox"))
      "k" (lambda () (interactive) (notmuch-search "path:gmail-kazik/** and tag:inbox"))
      "l" (lambda () (interactive) (notmuch-search "path:gmail-swilczek/** and tag:inbox"))
      "u" (lambda () (interactive) (notmuch-search "path:icloud/** and tag:inbox"))
      "a" (lambda () (interactive) (notmuch-search "tag:inbox"))
      "O" (lambda () (interactive) (notmuch-search "path:\"outlook-main/Sent/**\""))
      "P" (lambda () (interactive) (notmuch-search "path:\"polsl/Elementy wysłane/**\""))
      "K" (lambda () (interactive) (notmuch-search "path:\"gmail-kazik/[Gmail]/Wysłane/**\""))
      "L" (lambda () (interactive) (notmuch-search "path:\"gmail-swilczek/[Gmail]/Sent Mail/**\""))
      "U" (lambda () (interactive) (notmuch-search "path:\"icloud/Sent Messages/**\""))
      "c" #'notmuch-mua-new-mail
      "m" #'notmuch-mua-new-mail
      "g" #'my/mail-sync-and-refresh
      "r" #'my/mail-sync-and-refresh
      "gr" #'my/mail-sync-and-refresh
      "s" #'notmuch-search
      "q" #'notmuch-bury-or-kill-this-buffer)

    (evil-define-key 'normal notmuch-search-mode-map
      "c" #'notmuch-mua-new-mail
      "m" #'notmuch-mua-new-mail
      "g" #'my/mail-sync-and-refresh
      "r" #'notmuch-search-reply-to-thread-sender
      "R" #'notmuch-search-reply-to-thread
      "RET" #'notmuch-search-show-thread
      "q" #'notmuch-bury-or-kill-this-buffer)

    (evil-define-key 'normal notmuch-show-mode-map
      "c" #'notmuch-mua-new-mail
      "m" #'notmuch-mua-new-mail
      "r" #'notmuch-show-reply-sender
      "R" #'notmuch-show-reply
      "q" #'notmuch-bury-or-kill-this-buffer)

    (evil-define-key '(normal insert) message-mode-map
      (kbd "C-c C-c") #'notmuch-mua-send-and-exit
      (kbd "C-c C-k") #'message-kill-buffer
      (kbd ", s")     #'notmuch-mua-send-and-exit
      (kbd ", k")     #'message-kill-buffer)))

(provide 'setup-mail)
