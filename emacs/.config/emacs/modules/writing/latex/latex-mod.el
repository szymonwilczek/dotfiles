;;; LaTeX compilation and in-Emacs PDF viewer

(use-package doc-view
  :ensure nil
  :defer t
  :config
  (setq doc-view-pdfengine 'mupdf)
  (setq doc-view-resolution 180)
  (setq doc-view-continuous t))


(defun my/latex-get-pdf-file ()
  "Return path to the corresponding PDF file for current buffer."
  (let ((tex-file (or (buffer-file-name)
                      (and (fboundp 'TeX-master-file) (TeX-master-file t)))))
    (when tex-file
      (concat (file-name-sans-extension tex-file) ".pdf"))))

(defun my/latex-compile (&optional callback)
  "Compile current LaTeX file asynchronously via latexmk in background."
  (interactive)
  (let ((tex-file (buffer-file-name)))
    (unless tex-file
      (user-error "Current buffer is not visiting a file"))
    (save-buffer)
    (message "⏳ Compiling %s in background..." (file-name-nondirectory tex-file))
    (let* ((default-directory (file-name-directory tex-file))
           (proc (start-process "latexmk-async" "*latexmk-output*"
                                "latexmk" "-pdf" "-interaction=nonstopmode" "-synctex=1"
                                tex-file)))
      (set-process-sentinel
       proc
       (lambda (_p event)
         (cond
          ((string-prefix-p "finished" event)
           (message "✅ LaTeX compilation successful: %s" (file-name-nondirectory (my/latex-get-pdf-file)))
           (when callback (funcall callback)))
          ((string-prefix-p "exited abnormally" event)
           (message "❌ LaTeX compilation failed. See buffer *latexmk-output*"))))))))

(defun my/latex-view-pdf ()
  "Open or focus the compiled PDF in a right split window inside Emacs."
  (interactive)
  (let ((pdf-file (my/latex-get-pdf-file)))
    (if (not (and pdf-file (file-exists-p pdf-file)))
        (message "⚠️ No PDF found. Compile first with SPC m c")
      (let* ((pdf-buffer (or (find-buffer-visiting pdf-file)
                             (find-file-noselect pdf-file)))
             (win (get-buffer-window pdf-buffer)))
        (with-current-buffer pdf-buffer
          (unless (derived-mode-p 'doc-view-mode)
            (doc-view-mode))
          (auto-revert-mode 1))
        (if win
            (select-window win)
          (let ((new-win (split-window-right)))
            (set-window-buffer new-win pdf-buffer)
            (select-window new-win)))))))

(defun my/latex-compile-and-view ()
  "Compile document and open PDF in right split once compilation finishes."
  (interactive)
  (my/latex-compile #'my/latex-view-pdf))

(defun my/latex-quit-pdf ()
  "Close PDF viewer and delete the split window if multiple windows exist."
  (interactive)
  (if (> (count-windows) 1)
      (delete-window)
    (kill-current-buffer)))


(require 'latex-keys)

(provide 'latex-mod)
