(require 'use-package)

(require 'private-mail nil t)

(setq user-mail-address "szymonwilczek@outlook.com"
      user-full-name "Szymon Wilczek")

(use-package notmuch
  :ensure t
  :bind ("<leader>om" . notmuch)
  :config
  (setq notmuch-search-oldest-first nil
        notmuch-show-empty-saved-searches t
        notmuch-always-prompt-for-sender t)

  (setq notmuch-saved-searches
        '((:name "📥 Wszystkie Nowe (Unified [i]nbox)" :query "tag:inbox and tag:unread" :sort-order 'newest-first :key "i")
          (:name "📬 szymonwilczek@[o]utlook.com"      :query "path:outlook-main/** and tag:inbox" :sort-order 'newest-first :key "o")
          (:name "🎓 sw312468@student.[p]olsl.pl"      :query "path:polsl/** and tag:inbox" :sort-order 'newest-first :key "p")
          (:name "✉️ [k]azikwilczek7@gmail.com"        :query "path:gmail-kazik/** and tag:inbox" :sort-order 'newest-first :key "k")
          (:name "✉️ swilczek.[l]x@gmail.com"          :query "path:gmail-swilczek/** and tag:inbox" :sort-order 'newest-first :key "l")
          (:name "📥 Wszystkie Wiadomości ([a]ll)"     :query "tag:inbox" :sort-order 'newest-first :key "a")))

  (setq sendmail-program "msmtp"
        send-mail-function 'smtpmail-send-it
        message-sendmail-f-is-evil t
        message-sendmail-extra-arguments '("--read-envelope-from")
        message-send-mail-function 'message-send-mail-with-sendmail)

  (setq notmuch-identities
        '("Szymon Wilczek <szymonwilczek@outlook.com>"
          "Szymon Wilczek <sw312468@student.polsl.pl>"
          "Szymon Wilczek <kazikwilczek7@gmail.com>"
          "Szymon Wilczek <swilczek.lx@gmail.com>")
        message-alternative-emails
        '("sw312468@student.polsl.pl"
          "kazikwilczek7@gmail.com"
          "swilczek.lx@gmail.com"))

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
      "a" (lambda () (interactive) (notmuch-search "tag:inbox"))
      "c" #'notmuch-mua-new-mail
      "m" #'notmuch-mua-new-mail
      "s" #'notmuch-search
      "g" #'notmuch-refresh-this-buffer
      "r" #'notmuch-refresh-this-buffer
      "q" #'notmuch-bury-or-kill-this-buffer)

    (evil-define-key 'normal notmuch-search-mode-map
      "c" #'notmuch-mua-new-mail
      "m" #'notmuch-mua-new-mail
      "q" #'notmuch-bury-or-kill-this-buffer)

    (evil-define-key '(normal insert) message-mode-map
      (kbd "C-c C-c") #'notmuch-mua-send-and-exit
      (kbd "C-c C-k") #'message-kill-buffer
      (kbd ", s")     #'notmuch-mua-send-and-exit
      (kbd ", k")     #'message-kill-buffer)))

(provide 'setup-mail)
