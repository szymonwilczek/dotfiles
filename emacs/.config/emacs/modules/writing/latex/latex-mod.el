;;; LaTeX compilation and in-Emacs PDF viewer -*- lexical-binding: t; -*-

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

(defvar my/latex-error-last-pos nil
  "Last searched position in *latexmk-output* buffer.")

(defun my/latex-compile (&optional callback)
  "Compile current LaTeX file asynchronously via latexmk in background."
  (interactive)
  (let ((tex-file (buffer-file-name)))
    (unless tex-file
      (user-error "Current buffer is not visiting a file"))
    (save-buffer)
    (setq my/latex-error-last-pos nil)
    (message "⏳ Compiling %s in background..." (file-name-nondirectory tex-file))
    (let* ((default-directory (file-name-directory tex-file))
           (out-buf (get-buffer-create "*latexmk-output*"))
           (cb callback)
           (proc (progn
                   (with-current-buffer out-buf
                     (let ((inhibit-read-only t))
                       (erase-buffer)
                       (compilation-mode)))
                   (start-process "latexmk-async" out-buf
                                  "latexmk" "-pdf" "-interaction=nonstopmode" "-file-line-error" "-synctex=1"
                                  tex-file))))
      (set-process-sentinel
       proc
       (lambda (_p event)
         (cond
          ((string-prefix-p "finished" event)
           (message "✅ LaTeX compilation successful: %s" (file-name-nondirectory (my/latex-get-pdf-file)))
           (when (and cb (functionp cb))
             (funcall cb)))
          ((string-prefix-p "exited abnormally" event)
           (message "❌ LaTeX compilation failed. Press SPC m e to jump to error or SPC m l to view log."))))))))

(defun my/latex-show-log ()
  "Toggle display of the compilation output log buffer."
  (interactive)
  (let ((buf (get-buffer "*latexmk-output*")))
    (if (not buf)
        (message "No compilation log found.")
      (let ((win (get-buffer-window buf)))
        (if win
            (delete-window win)
          (pop-to-buffer buf))))))

(defvar-local my/latex-error-index 0
  "Index of currently viewed error in buffer.")

(defun my/latex-get-log-file ()
  "Return path to the compilation .log file for current buffer."
  (let ((tex-file (or (buffer-file-name)
                      (and (fboundp 'TeX-master-file) (TeX-master-file t)))))
    (when tex-file
      (concat (file-name-sans-extension (expand-file-name tex-file)) ".log"))))

(defun my/latex-parse-errors ()
  "Parse all compilation errors from the .log file."
  (let ((errors nil)
        (log-file (my/latex-get-log-file)))
    (when (and log-file (file-exists-p log-file))
      (with-temp-buffer
        (insert-file-contents log-file)
        ;; file-line-error:
        ;; /path/to/file.tex:<line>: <msg>
        ;; or file.tex:<line>: <msg>
        (goto-char (point-min))
        (while (re-search-forward "^\\([^:\n\r\t ]+\\.tex\\):\\([0-9]+\\): *\\([^\n\r]+\\)" nil t)
          (let ((line (string-to-number (match-string 2)))
                (msg (string-trim (match-string 3))))
            (push (cons line msg) errors)))
        ;; standard TeX: ! <msg> \n l.<line>
        (goto-char (point-min))
        (while (re-search-forward "^! *\\([^\n\r]+\\)\n+l\\.\\([0-9]+\\)" nil t)
          (let ((msg (string-trim (match-string 1)))
                (line (string-to-number (match-string 2))))
            (push (cons line msg) errors)))))
    (seq-uniq (nreverse errors) (lambda (a b) (= (car a) (car b))))))

(defun my/latex-next-error ()
  "Jump to the next compilation error in the current LaTeX buffer."
  (interactive)
  (let ((errors (my/latex-parse-errors)))
    (if (null errors)
        (message "✅ No LaTeX errors found in log.")
      (let* ((count (length errors))
             (idx (if (or (null my/latex-error-index) (>= my/latex-error-index count))
                      0
                    my/latex-error-index))
             (item (nth idx errors))
             (line (car item))
             (msg (cdr item)))
        (setq my/latex-error-index (1+ idx))
        (goto-char (point-min))
        (forward-line (1- line))
        (ignore-errors (recenter))
        (message "❌ [%d/%d] Line %d: %s" (1+ idx) count line msg)))))

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
