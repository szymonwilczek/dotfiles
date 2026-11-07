;;; -*- lexical-binding: t; -*-
(use-package bufferline
  :vc (:url "https://github.com/szymonwilczek/bufferline.el" :branch "main" :rev :newest)
  :demand t
  :custom
  (bufferline-separator-style 'vertical)
  :config
  (setq bufferline-show-special-buffers t)
  (global-bufferline-mode 1)

  (defun my/bufferline-persp-filter (tabs)
    "Keep only TABS belonging to the current perspective."
    (if (bound-and-true-p persp-mode)
        (seq-filter (lambda (buf) (persp-is-current-buffer buf)) tabs)
      tabs))

  (advice-add 'bufferline-buffers-all :filter-return #'my/bufferline-persp-filter)

  (defun my/bufferline-filter (buffer)
    (let ((name (buffer-name buffer)))
      (not (or (buffer-local-value 'my/agent-buffer-p buffer)
               (buffer-local-value 'my/ghostel-bottom-buffer-p buffer)
               (string-prefix-p "*agent-" name)
               (string-prefix-p "*ghostel-bottom" name)))))

  (setq bufferline-custom-filter #'my/bufferline-filter)

  (defvar my/tab-close-commands
    '(kill-current-buffer kill-buffer kill-this-buffer evil-delete-buffer
                          bufferline-close-tab bufferline-pick-close))

  (defun my/last-tab-p (&optional buffer)
    (let* ((buf (or buffer (current-buffer)))
           (tabs (seq-filter (lambda (b)
                               (and (if (bound-and-true-p persp-mode)
                                        (persp-is-current-buffer b)
                                      t)
                                    (bufferline-buffers-candidate-p b)))
                             (buffer-list))))
      (and (memq buf tabs)
           (null (cdr tabs)))))

  (defun my/split-window-p (&optional window)
    (let ((win (or window (selected-window))))
      (unless (window-dedicated-p win)
        (> (length (seq-filter (lambda (w) (not (window-dedicated-p w)))
                               (window-list nil 'no-minibuf)))
           1))))

  (defun my/tab-close ()
    (interactive)
    (let* ((win (selected-window))
           (buf (window-buffer win)))
      (cond
       ((window-dedicated-p win)
        (delete-window win))
       ((my/split-window-p win)
        (delete-window win)
        (unless (or (my/last-tab-p buf)
                    (get-buffer-window buf))
          (kill-buffer buf)))
       ((my/last-tab-p buf)
        (user-error "Cannot close the last tab%s"
                    (if (bound-and-true-p persp-mode)
                        (format " of perspective %s" (persp-current-name))
                      "")))
       (t
        (kill-current-buffer)))))

  (defun my/refuse-closing-last-tab (&optional buffer)
    (let ((buf (or buffer (current-buffer))))
      (when (and (memq this-command my/tab-close-commands)
                 (not (my/split-window-p))
                 (my/last-tab-p buf))
        (user-error "Cannot close the last tab%s"
                    (if (bound-and-true-p persp-mode)
                        (format " of perspective %s" (persp-current-name))
                      ""))))
    t)

  (add-hook 'kill-buffer-query-functions #'my/refuse-closing-last-tab -90)
  (advice-add 'bufferline-close-tab :before #'my/refuse-closing-last-tab)

  (defun my/scratch-buffer-p (buffer)
    "Non-nil when BUFFER is a global or perspective scratch buffer."
    (string-match-p "\\`\\*scratch\\*" (buffer-name buffer)))

  (defun my/drop-perspective-scratch (frame)
    "Kill the perspective's scratch once FRAME's selected window shows a real tab."
    (when (bound-and-true-p persp-mode)
      (with-selected-frame frame
        (let ((buffer (window-buffer (selected-window))))
          (when (and (not (my/scratch-buffer-p buffer))
                     (memq buffer (bufferline-buffers-all)))
            (when-let* ((scratch (get-buffer (persp-scratch-buffer))))
              (when (and (not (buffer-modified-p scratch))
                         (not (get-buffer-window scratch t)))
                (run-at-time 0 nil
                             (lambda ()
                               (when (and (buffer-live-p scratch)
                                          (not (buffer-modified-p scratch))
                                          (not (get-buffer-window scratch t)))
                                 (kill-buffer scratch)))))))))))

  (add-hook 'window-buffer-change-functions #'my/drop-perspective-scratch))

(require 'tabs-keys)

(provide 'tabs-mod)
