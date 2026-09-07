;;; -*- lexical-binding: t; -*-

(add-to-list 'load-path (expand-file-name "modules/calendar" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "~/Dokumenty/GitHub/icloud-calendar.el"))

(use-package icloud-calendar
  :commands (icloud-calendar icloud-sidebar-toggle)
  :custom
  (icloud-calendar-default-view 'week)
  (icloud-calendar-day-start-hour 7)
  (icloud-calendar-day-end-hour 22)
  (icloud-calendar-sync-interval 300))

(provide 'calendar-mod)
