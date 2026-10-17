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

  ;; Every perspective keeps at least one tab: closing the last one is
  ;; refused, and the perspective's scratch goes once a real tab exists
  (defvar my/tab-close-commands
    '(kill-current-buffer kill-buffer kill-this-buffer evil-delete-buffer
      bufferline-close-tab bufferline-pick-close)
    "Commands that close a tab and must leave the perspective one.")

  (defun my/last-tab-p (buffer)
    "Non-nil when BUFFER is the only tab of the selected window."
    (let ((tabs (bufferline-buffers-all)))
      (and (memq buffer tabs) (null (cdr tabs)))))

  (defun my/refuse-closing-last-tab (&optional buffer)
    "Signal a user error when BUFFER is the last tab and a close command runs."
    (let ((buffer (or buffer (current-buffer))))
      (when (and (memq this-command my/tab-close-commands)
                 (my/last-tab-p buffer))
        (user-error "Cannot close the last tab%s"
                    (if (bound-and-true-p persp-mode)
                        (format " of perspective %s" (persp-current-name))
                      ""))))
    t)

  (add-hook 'kill-buffer-query-functions #'my/refuse-closing-last-tab)
  ;; bufferline-close-tab switches away before killing, so stop it first
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
