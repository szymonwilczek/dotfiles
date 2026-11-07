;;; -*- lexical-binding: t; -*-
(use-package bufferline
  :vc (:url "https://github.com/szymonwilczek/bufferline.el" :branch "main" :rev :newest)
  :demand t
  :custom
  (bufferline-separator-style 'vertical)
  :config
  (setq bufferline-show-special-buffers t)
  (global-bufferline-mode 1)

  (setq bufferline-exclude-modes
        (append '(jsonrpc-events-mode special-mode) bufferline-exclude-modes))

  (defun my/scratch-buffer-p (buffer)
    "Non-nil when BUFFER is a global or perspective scratch buffer."
    (string-match-p "\\`\\*scratch\\*" (buffer-name buffer)))

  (defun my/bufferline-persp-filter (buffer)
    "Give BUFFER a tab only when it belongs to the current perspective.
Scratch buffers and eglot's server buffers never get one."
    (and (not (my/scratch-buffer-p buffer))
         (not (string-prefix-p "*EGLOT " (buffer-name buffer)))
         (or (not (bound-and-true-p persp-mode))
             (persp-is-current-buffer buffer))))

  (setq bufferline-custom-filter #'my/bufferline-persp-filter)

  (defvar my/tab-close-commands
    '(kill-current-buffer kill-buffer kill-this-buffer evil-delete-buffer
                          bufferline-close-tab bufferline-close-tab-at-click bufferline-pick-close)
    "Commands that close a tab and must leave the perspective one.")

  (defun my/last-tab-p (buffer window)
    "Non-nil when BUFFER is the only tab of WINDOW."
    (let ((tabs (with-selected-window window (bufferline-buffers-all))))
      (and (memq buffer tabs) (null (cdr tabs)))))

  (defun my/refuse-closing-last-tab ()
    "Refuse to kill the last tab of a window while a close command runs.
Killing it is fine when it closes the window, which `kill-buffer' does
for a window dedicated to the buffer."
    (let* ((buffer (current-buffer))
           (window (if (eq (window-buffer) buffer)
                       (selected-window)
                     (get-buffer-window buffer))))
      (when (and window
                 (memq this-command my/tab-close-commands)
                 (my/last-tab-p buffer window)
                 (not (and (window-dedicated-p window)
                           (eq (window-deletable-p window) t))))
        (user-error "Cannot close the last tab%s"
                    (if (bound-and-true-p persp-mode)
                        (format " of perspective %s" (persp-current-name))
                      ""))))
    t)

  (add-hook 'kill-buffer-query-functions #'my/refuse-closing-last-tab -90)

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
