;;; Tea house pottery inbox (szymon-wilczek.me/roji) -*- lexical-binding: t; -*-

(let ((moderate (expand-file-name
                 "~/Dokumenty/GitHub/sw.szymon-wilczek.me/emacs/chashitsu-moderate.el")))
  (when (file-exists-p moderate)
    (load moderate)
    (setq chashitsu-inbox-url "https://roji.szymon-wilczek.me"
          chashitsu-repo "~/Dokumenty/GitHub/sw.szymon-wilczek.me/")
    (chashitsu-mode-line-mode 1)))

(provide 'chashitsu-mod)
