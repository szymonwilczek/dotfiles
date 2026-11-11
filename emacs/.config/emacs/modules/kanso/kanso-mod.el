;;; Kanso - Keyboard-Centric Dojo -*- lexical-binding: t; -*-

(let ((kanso-dir (expand-file-name "~/Dokumenty/GitHub/kanso.el")))
  (when (file-directory-p kanso-dir)
    (add-to-list 'load-path kanso-dir)
    (add-to-list 'load-path (expand-file-name "modules/dojo" kanso-dir))
    (add-to-list 'load-path (expand-file-name "modules/speedtest" kanso-dir))
    (add-to-list 'load-path (expand-file-name "modules/coach" kanso-dir))
    (add-to-list 'load-path (expand-file-name "modules/heatmap" kanso-dir))
    (add-to-list 'load-path (expand-file-name "modules/ergonomics" kanso-dir))

    (require 'kanso)

    (setq kanso-enabled-modules '(dojo speedtest coach heatmap ergonomics)
          kanso-speedtest-language "pl"
          kanso-speedtest-track-history t
          kanso-dojo-layout 'hhkb-ansi
          kanso-dojo-adaptive-drills t)

    (kanso-initialize)

    (global-set-key (kbd "C-c k") #'kanso)

    (with-eval-after-load 'general
      (when (fboundp 'my-leader-def)
        (my-leader-def
          "k"   '(:ignore t :which-key "Kanso Dojo")
          "kk"  '(kanso :which-key "Kanso Menu")
          "ks"  '(kanso-speedtest :which-key "Speedtest (10FF)")
          "kd"  '(kanso-dojo :which-key "Dojo Kata")
          "kh"  '(kanso-heatmap :which-key "Heatmap")
          "kc"  '(kanso-coach-report :which-key "Coach Report")
          "ke"  '(kanso-ergonomics-status :which-key "Ergonomics"))))))

(provide 'kanso-mod)
