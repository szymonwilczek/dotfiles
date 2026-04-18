;; garbage collection off for the start
(setq gc-cons-threshold most-positive-fixnum)

;; kills the ui before it shows
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; silence warnings 
(setq native-comp-async-report-warnings-errors 'silent)
