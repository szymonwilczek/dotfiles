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

  (defun my/window-tabs (&optional window)
    "Return the tabs on the tab line of WINDOW."
    (with-selected-window (or window (selected-window))
      (bufferline-buffers-all)))

  (defun my/primary-window-p (&optional window)
    "Return non-nil if WINDOW is a regular one, kept apart from the agent,
the prompt draft, the bottom terminal and side windows."
    (let ((win (or window (selected-window))))
      (and (not (window-dedicated-p win))
           (not (window-parameter win 'window-side))
           (my/bufferline-filter (window-buffer win)))))

  (defun my/split-window-p (&optional window)
    "Return non-nil if WINDOW can go because another primary window stays."
    (let ((win (or window (selected-window))))
      (and (not (window-dedicated-p win))
           (seq-some (lambda (w)
                       (and (not (eq w win)) (my/primary-window-p w)))
                     (window-list (window-frame win) 'no-minibuf)))))

  (defun my/last-tab-p (&optional buffer)
    "Return non-nil if BUFFER is the only tab of the window showing it.
An unmodified scratch buffer does not count as another tab."
    (let* ((buf (or buffer (current-buffer)))
           (win (get-buffer-window buf)))
      (when win
        (let ((tabs (seq-remove (lambda (b)
                                  (and (not (eq b buf))
                                       (my/scratch-buffer-p b)
                                       (not (buffer-modified-p b))))
                                (my/window-tabs win))))
          (and (memq buf tabs)
               (null (cdr tabs)))))))

  (defun my/perspective-scratch ()
    "Return the scratch buffer of the current perspective, creating it."
    (if (bound-and-true-p persp-mode)
        (persp-get-scratch-buffer)
      (get-scratch-buffer-create)))

  (defun my/window-show-scratch (window)
    "Show the scratch buffer of the perspective of WINDOW in WINDOW."
    (with-selected-frame (window-frame window)
      (set-window-buffer window (my/perspective-scratch))))

  (defun my/window-tab-p (window buffer)
    "Return non-nil if BUFFER is a tab of WINDOW, even one hidden elsewhere."
    (and (bufferline-buffers-candidate-p buffer)
         (or (assq buffer (window-prev-buffers window))
             (memq buffer (window-next-buffers window)))
         (or (not (bound-and-true-p persp-mode))
             (with-selected-frame (window-frame window)
               (persp-is-current-buffer buffer)))))

  (defun my/switch-to-prev-buffer-skip (window buffer _bury-or-kill)
    "Skip BUFFER unless it is a tab of the ordinary WINDOW."
    (and (not (window-dedicated-p window))
         (not (my/window-tab-p window buffer))))

  (setq switch-to-prev-buffer-skip #'my/switch-to-prev-buffer-skip)

  (defun my/switch-to-prev-buffer-or-scratch (orig-fn &optional window bury-or-kill)
    "Call ORIG-FN with WINDOW and BURY-OR-KILL, else fall back to the scratch."
    (or (funcall orig-fn window bury-or-kill)
        (let ((win (window-normalize-window window t)))
          (when (and bury-or-kill
                     (not (window-parameter win 'window-side))
                     (not (my/scratch-buffer-p (window-buffer win))))
            (my/window-show-scratch win)
            (window-buffer win)))))

  (advice-add 'switch-to-prev-buffer :around #'my/switch-to-prev-buffer-or-scratch)

  (defun my/tab-close ()
    "Close the selected tab, the window it empties, but never the last tab."
    (interactive)
    (let* ((win (selected-window))
           (buf (window-buffer win)))
      (cond
       ((window-dedicated-p win)
        (cond
         ((not (frame-root-window-p win))
          (delete-window win))
         ((my/agent-window-p win)
          (my/agent-restore-ordinary-window win))
         (t
          (user-error "Cannot close the only window of this frame"))))
       ((not (my/primary-window-p win))
        (if (frame-root-window-p win)
            (kill-buffer buf)
          (delete-window win)
          (unless (get-buffer-window buf t)
            (kill-buffer buf))))
       ((and (remq buf (my/window-tabs win))
             (not (my/last-tab-p buf)))
        (switch-to-buffer (car (remq buf (my/window-tabs win))))
        (unless (get-buffer-window buf t)
          (kill-buffer buf)))
       ((my/split-window-p win)
        (delete-window win)
        (unless (get-buffer-window buf t)
          (kill-buffer buf)))
       ((my/last-tab-p buf)
        (user-error "Cannot close the last tab%s"
                    (if (bound-and-true-p persp-mode)
                        (format " of perspective %s" (persp-current-name))
                      "")))
       (t
        (kill-buffer buf)))))

  (defun my/refuse-closing-last-tab (&optional buffer)
    (let* ((buf (or buffer (current-buffer)))
           (win (get-buffer-window buf)))
      (when (and win
                 (memq this-command my/tab-close-commands)
                 (not (my/split-window-p win))
                 (my/last-tab-p buf))
        (user-error "Cannot close the last tab%s"
                    (if (bound-and-true-p persp-mode)
                        (format " of perspective %s" (persp-current-name))
                      ""))))
    t)

  (add-hook 'kill-buffer-query-functions #'my/refuse-closing-last-tab -90)
  (advice-add 'bufferline-close-tab :before #'my/refuse-closing-last-tab)

  (defun my/scratch-buffer-p (buffer)
    (string-match-p "\\`\\*scratch\\*" (buffer-name buffer)))

  (defun my/keep-visible-scratch ()
    "Refuse to kill a scratch buffer that is all a window has left to show."
    (let ((buf (current-buffer)))
      (not (and (my/scratch-buffer-p buf)
                (seq-some (lambda (win)
                            (null (remq buf (my/window-tabs win))))
                          (get-buffer-window-list buf nil t))))))

  (add-hook 'kill-buffer-query-functions #'my/keep-visible-scratch -90)

  (defvar my/drop-scratch-timer nil
    "Pending run of `my/drop-perspective-scratch-now'.")

  (defun my/drop-perspective-scratch-now ()
    "Kill the hidden, unmodified scratch once the perspective has a real tab."
    (setq my/drop-scratch-timer nil)
    (when (bound-and-true-p persp-mode)
      (when-let* ((scratch (get-buffer (persp-scratch-buffer))))
        (when (and (not (buffer-modified-p scratch))
                   (not (get-buffer-window scratch t))
                   (seq-some (lambda (b)
                               (and (bufferline-buffers-candidate-p b)
                                    (not (my/scratch-buffer-p b))))
                             (persp-buffers (persp-curr))))
          (kill-buffer scratch)))))

  (defun my/drop-perspective-scratch (&rest _)
    "Schedule one `my/drop-perspective-scratch-now', however often it is called."
    (when (and (bound-and-true-p persp-mode)
               (not (timerp my/drop-scratch-timer)))
      (setq my/drop-scratch-timer
            (run-at-time 0 nil #'my/drop-perspective-scratch-now))))

  (advice-add 'persp-add-buffer :after #'my/drop-perspective-scratch)
  (add-hook 'persp-switch-hook #'my/drop-perspective-scratch)
  (add-hook 'find-file-hook #'my/drop-perspective-scratch))

(require 'tabs-keys)

(provide 'tabs-mod)
