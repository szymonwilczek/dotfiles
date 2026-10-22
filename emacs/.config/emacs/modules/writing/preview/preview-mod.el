;;; Rendered preview of Org and Markdown buffers -*- lexical-binding: t; -*-

(require 'shr)

(add-to-list 'display-buffer-alist
             '("\\`\\*Preview: "
               (display-buffer-in-side-window)
               (side . right)
               (slot . 0)
               (window-width . 0.5)
               (preserve-size . (t . nil))
               (window-parameters . ((no-delete-other-windows . t)))))

(defvar-local my/preview-buffer nil
  "The buffer showing the preview of this one.")

(defun my/preview--html ()
  "Return the current buffer as HTML."
  (cond ((derived-mode-p 'org-mode)
         (require 'ox-html)
         (let ((org-export-show-temporary-export-buffer nil))
           (org-export-as 'html nil nil t '(:with-toc nil))))
        ((derived-mode-p 'markdown-mode)
         (let ((source (buffer-string)))
           (with-temp-buffer
             (insert source)
             (unless (zerop (call-process-region (point-min) (point-max) "pandoc"
                                                 t t nil "--from=gfm" "--to=html"))
               (error "pandoc failed: %s" (buffer-string)))
             (buffer-string))))
        (t (user-error "No preview for %s" major-mode))))

(defun my/preview-render ()
  "Render the current buffer into its preview window."
  (interactive)
  (let* ((html (my/preview--html))
         (base (file-name-as-directory (expand-file-name default-directory)))
         (buffer (or (and (buffer-live-p my/preview-buffer) my/preview-buffer)
                     (setq my/preview-buffer
                           (get-buffer-create (format "*Preview: %s*" (buffer-name))))))
         (window (get-buffer-window buffer))
         (line (when window
                 (with-current-buffer buffer
                   (line-number-at-pos (window-start window))))))
    ;; shr fills the text to the selected window,
    ;; so the preview window has to exist and be selected before rendering
    (with-selected-window (or window (display-buffer buffer))
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert html)
        (let ((dom (libxml-parse-html-region (point-min) (point-max)))
              (shr-base (shr-parse-base (concat "file://" base))))
          (erase-buffer)
          (shr-insert-document dom))
        (goto-char (point-min)))
      (unless (derived-mode-p 'special-mode)
        (special-mode))
      (setq-local default-directory base)
      (when line
        (forward-line (1- line))
        (set-window-start nil (point))))))

(define-minor-mode my/preview-mode
  "Show this Org or Markdown buffer rendered in a window on the right.
The preview is rendered again every time the buffer is saved."
  :lighter " Preview"
  (if my/preview-mode
      (progn
        (add-hook 'after-save-hook #'my/preview-render nil t)
        (my/preview-render))
    (remove-hook 'after-save-hook #'my/preview-render t)
    (when (buffer-live-p my/preview-buffer)
      (kill-buffer my/preview-buffer))
    (setq my/preview-buffer nil)))

(provide 'preview-mod)
