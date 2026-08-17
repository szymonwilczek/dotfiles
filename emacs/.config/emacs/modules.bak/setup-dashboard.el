(setq inhibit-startup-message t
      inhibit-startup-screen t
      initial-scratch-message nil)

(use-package dashboard
  :ensure t
  :config

  ;; General
  (setq dashboard-startup-banner nil)       
  (setq dashboard-banner-logo-title nil)    
  (setq dashboard-set-init-info nil)        
  (setq dashboard-set-footer nil)           
  (setq dashboard-center-content t)         
  (setq dashboard-vertically-center-content t) 

  ;; Widgets
  (setq dashboard-items '((recents . 4)))   
  (setq dashboard-item-names '(("Recent Files:" . "Recent Files")))
  (setq dashboard-item-shortcuts nil)
  (setq dashboard-display-icons-p t)        
  (setq dashboard-icon-type 'nerd-icons)    
  (setq dashboard-set-heading-icons t)      
  (setq dashboard-set-file-icons t)         

  ;; Greeting
  (defun my/get-greeting ()
    (let ((hour (string-to-number (format-time-string "%H"))))
      (cond ((and (>= hour 5) (< hour 14)) "☀️ Good Morning")
            ((and (>= hour 14) (< hour 18)) "☕ Good Afternoon")
            ((and (>= hour 18) (< hour 23)) "🌙 Good Evening")
            (t "🦉 Night Mode..."))))

  ;; Banners
  (defun my/get-random-banner ()
    (let* ((banner-dir (expand-file-name "banners/" user-emacs-directory))
           (banners (when (file-directory-p banner-dir)
                      (directory-files banner-dir t "^[^.]"))))
      (if banners (nth (random (length banners)) banners) nil)))

  (defun my/parse-dashboard-banner (file)
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (let ((tag-alist '(("[R]" . error)
                         ("[G]" . success)
                         ("[L]" . font-lock-builtin-face)
                         ("[Y]" . warning)
                         ("[O]" . font-lock-constant-face)
                         ("[P]" . font-lock-keyword-face)
                         ("[C]" . font-lock-function-name-face)
                         ("[A]" . shadow)
                         ("[B]" . font-lock-type-face)
                         ("[W]" . default))))
        (while (not (eobp))
          (let ((current-face 'default)
                (start-pos (point)))
            (while (re-search-forward "\\[[RGLYOPCABW]\\]" (line-end-position) t)
              (let* ((tag (match-string 0))
                     (face (cdr (assoc tag tag-alist)))
                     (tag-start (match-beginning 0)))
                (when (> tag-start start-pos)
                  (put-text-property start-pos tag-start 'face current-face))
                (delete-region tag-start (point))
                (when face (setq current-face face))
                (setq start-pos (point))))
            (when (> (line-end-position) start-pos)
              (put-text-property start-pos (line-end-position) 'face current-face)))
          (forward-line 1)))
      (buffer-string)))

  ;; Header 
  (defun my/dashboard-insert-custom-header (&rest _)
    (let ((banner-file (my/get-random-banner)))
      (when banner-file
        (let* ((parsed-string (my/parse-dashboard-banner banner-file))
               (lines (split-string parsed-string "\n"))
               (max-width (apply #'max 0 (mapcar #'string-width lines)))
               (pad (max 0 (/ (- (window-width) max-width) 2))))
          (mapc (lambda (line)
                  (insert (make-string pad ?\s) line "\n"))
                lines))))
    
    (insert "\n")
    
    ;; Greeting
    (let* ((greeting (propertize (my/get-greeting) 'face 'warning))
           (g-pad (max 0 (/ (- (window-width) (string-width (my/get-greeting))) 2))))
      (insert (make-string g-pad ?\s) greeting "\n\n"))

;; Statistics
    (let* ((pkg-count (length (bound-and-true-p package-activated-list)))
           (time-str (emacs-init-time "%.2f s"))
           (stats-raw (format "󰏖 Loaded %d packages in 󱐋 %s" pkg-count time-str))
           (s-pad (max 0 (/ (- (window-width) (string-width stats-raw)) 2))))
      (insert (make-string s-pad ?\s) 
              (propertize (format "󰏖 Loaded %d packages in " pkg-count) 'face 'font-lock-comment-face)
              (propertize (format "󱐋 %s" time-str) 'face 'font-lock-keyword-face))))

  (advice-add 'dashboard-insert-banner :override #'my/dashboard-insert-custom-header)
  
  (advice-add 'dashboard-insert-init-info :override #'ignore)

  ;; Footer
  (defun my/dashboard-insert-dynamic-footer (&rest _)
    (let* ((date (format-time-string "󰸗 %d.%m.%Y"))
           (sep " | ")
           (time (format-time-string "󱑒 %H:%M"))
           (footer (concat (propertize date 'face 'success)
                           (propertize sep 'face 'shadow)
                           (propertize time 'face 'font-lock-builtin-face)))
           (width (+ (string-width date) (string-width sep) (string-width time)))
           (pad (max 0 (/ (- (window-width) width) 2))))
      (insert "\n\n")
      (insert (make-string pad ?\s))
      (insert footer "\n")))

  (advice-add 'dashboard-insert-footer :override #'my/dashboard-insert-dynamic-footer)

  ;; Start
  (setq initial-buffer-choice (lambda () (get-buffer-create dashboard-buffer-name)))
  (add-hook 'emacs-startup-hook
            (lambda ()
              (when (get-buffer "*scratch*")
                (kill-buffer "*scratch*"))))

  (dashboard-setup-startup-hook))

;; Themes
(defun my/refresh-dashboard-on-theme-change (&rest _)
  (when (get-buffer dashboard-buffer-name)
    (with-current-buffer dashboard-buffer-name
      (dashboard-refresh-buffer))))
(advice-add 'load-theme :after #'my/refresh-dashboard-on-theme-change)

(provide 'setup-dashboard)
