;;; -*- lexical-binding: t; -*-

;; Force pure Wayland backend for PGTK
(when (featurep 'pgtk)
  (setenv "GDK_BACKEND" "wayland"))

(add-to-list 'default-frame-alist '(fullscreen . maximized))

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)


;; Temporarily disable file-name-handler-alist during startup for faster boot
(defvar my/initial-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

(setq gc-cons-threshold most-positive-fixnum)
(setq gc-cons-percentage 0.6)

;; Restore file-name-handler-alist and reset GC to 128MB after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist my/initial-file-name-handler-alist)
            (setq gc-cons-threshold (* 128 1024 1024)
                  gc-cons-percentage 0.1)
            (makunbound 'my/initial-file-name-handler-alist)))

(setq package-enable-at-startup nil)

;; Cache directory lookups in load-path to accelerate repeated 'require' and 'load'
(when (and (boundp 'load-path-filter-function)
           (fboundp 'load-path-filter-cache-directory-files))
  (setq load-path-filter-function #'load-path-filter-cache-directory-files))

;; .#filename), ~filename, #filename#
(setq create-lockfiles nil
      make-backup-files nil
      auto-save-default nil
      auto-save-list-file-prefix nil)

;; Startup speed, annoyance suppression
(setq inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name
      native-comp-async-report-warnings-errors nil
      native-comp-async-on-battery-power nil
      warning-minimum-level :emergency
      warning-suppress-types '((native-compiler) (with-editor) (files) (comp)))

(setq frame-inhibit-implied-resize t)

;; ----------------------------------------------------------------------------
;; Emacs is a text editor, not an operating system (for me).
;; Disable built-in subsystems I don't use to reduce cognitive overhead.
;; This keeps M-x clean and prevents accidental activation of irrelevant modes.
;; ----------------------------------------------------------------------------

;; I use standalone email
(setq disabled-features/mail t)
(put 'gnus 'disabled t)
(put 'rmail 'disabled t)
(put 'mh-e 'disabled t)

;; Prevent mail/news autoloads from polluting M-x
(with-eval-after-load 'startup
  (dolist (sym '(compose-mail mail browse-url-mail
                              gnus gnus-other-frame
                              rmail rmail-input
                              mh-rmail mh-smail))
    (when (fboundp sym)
      (put sym 'disabled t))))

;; not exactly why I open Emacs
(setq command-line-default-directory (expand-file-name "~/"))
(dolist (game '(tetris snake dunnet hanoi hanoi-unix
                       life pong solitaire zone doctor
                       butterfly animate-birthday-present
                       mpuz 5x5 blackbox bubbles gomoku landmark))
  (put game 'disabled "TURNED OFF."))

;; I use Firefox
(put 'eww 'disabled "TURNED OFF.")
(put 'eww-browse-url 'disabled "TURNED OFF.")

;; using Treemacs instead
(put 'speedbar 'disabled "TURNED OFF.")

;; I dont print from Emacs
(setq lpr-command "")
(setq printer-name "")
(put 'lpr-buffer 'disabled "TURNED OFF.")
(put 'print-buffer 'disabled "TURNED OFF.")
(put 'ps-print-buffer 'disabled "TURNED OFF.")

(put 'help-with-tutorial 'disabled "TURNED OFF.")

;; I use Ghostty and eat
(dolist (term-cmd '(eshell eshell-command term ansi-term shell))
  (put term-cmd 'disabled "TURNED OFF."))

;; Emacs is an editor, not exactly a media center for me
(dolist (net-cmd '(erc erc-tls rcirc newsticker-show-news mpc dictionary-search))
  (put net-cmd 'disabled "TURNED OFF."))

;; superseded by jot, and Org
(dolist (pim-cmd '(diary appt-activate remember remember-notes))
  (put pim-cmd 'disabled "TURNED OFF."))

;; ancient network protocols
(dolist (net-proto '(telnet rlogin ftp ange-ftp finger))
  (put net-proto 'disabled "TURNED OFF."))

;; doc viewers
(dolist (doc-cmd '(woman man info))
  (put doc-cmd 'disabled "TURNED OFF."))

;; archive and image viewers
(dolist (arc-cmd '(tar-mode archive-mode image-dired))
  (put arc-cmd 'disabled "TURNED OFF."))

;; legacy managers
(dolist (mgr-cmd '(vc-dir ibuffer list-buffers bookmark-bmenu-list bookmark-jump))
  (put mgr-cmd 'disabled "TURNED OFF."))

;; drawing, gestures and ascii tables
(dolist (draw-cmd '(strokes-mode artist-mode picture-mode table-insert table-mode))
  (put draw-cmd 'disabled "TURNED OFF."))

;; text toys
(dolist (toy-cmd '(morse-region unmorse-region rot13-region rot13-other-window dissociated-press))
  (put toy-cmd 'disabled "TURNED OFF."))

;; background daemons and nags
(dolist (daemon-cmd '(type-break-mode midnight-mode timeclock-in timeclock-out todo-show))
  (put daemon-cmd 'disabled "TURNED OFF."))

;; obsolete IDE, databases, and sound
(dolist (obs-cmd '(semantic-mode desktop-save-mode forms-mode eudc-query-form play-sound play-sound-file))
  (put obs-cmd 'disabled "TURNED OFF."))

(setq disabled-command-function nil)
