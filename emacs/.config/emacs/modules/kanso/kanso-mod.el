;;; Kanso - Keyboard-Centric Dojo -*- lexical-binding: t; -*-

(let ((kanso-dir (expand-file-name "~/Dokumenty/GitHub/kanso.el")))
  (when (file-directory-p kanso-dir)
    (add-to-list 'load-path kanso-dir)
    (add-to-list 'load-path (expand-file-name "modules/dojo" kanso-dir))
    (add-to-list 'load-path (expand-file-name "modules/speedtest" kanso-dir))
    (add-to-list 'load-path (expand-file-name "modules/coach" kanso-dir))
    (add-to-list 'load-path (expand-file-name "modules/heatmap" kanso-dir))

    (require 'kanso)

    (setq kanso-enabled-modules '(dojo speedtest coach heatmap)
          kanso-speedtest-language "pl"
          kanso-speedtest-track-history t
          kanso-dojo-layout 'hhkb-ansi
          kanso-dojo-adaptive-drills t)

    (kanso-initialize)))

(provide 'kanso-mod)
