(require 'cl-lib)
(require 'subr-x)

;;; ======
;;; CONFIG
;;; ======

(defvar my/pv-latex-delay    0.1   "Opóźnienie texfrag-document po syncu (s).")
(defvar my/pv-texfrag-dir
  (expand-file-name "texfrag-preview" temporary-file-directory)
  "Katalog na pliki tymczasowe texfrag (~=/tmp/texfrag-preview).")
(defvar my/pv-left-margin    4    "Lewy margines prawego bufora.")
(defvar my/pv-right-margin   4    "Prawy margines prawego bufora.")
(defvar my/pv-line-spacing   0.2  "Odstęp między liniami w preview.")


(autoload 'texfrag-document "texfrag" nil t)
(autoload 'texfrag-mode "texfrag" nil t)

;;; =====
;;; STATE
;;; =====

(defvar my/pv-source-buffer nil "Bufor źródłowy aktywnego preview.")
(defvar-local my/pv-active       nil)
(defvar-local my/pv-latex-timer  nil)

(defun my/pv-name ()
  (format "*Preview %s*" (buffer-name)))

;;; ==========
;;; FORMATTING
;;; ==========

(defun my/pv-apply-formatting ()
  "Formatuj cały bieżący bufor ręcznie, bez użycia zbugowanego font-locka."
  (let ((inhibit-read-only t)
        (inhibit-modification-hooks t))

    ;; Czyścimy stary stan, uwzględniając również nasz nowy tag my-code-tag
    (with-silent-modifications
      (remove-list-of-text-properties
       (point-min) (point-max) '(invisible display my/pv face font-lock-face my-code-tag)))

    ;; ===============================
    ;; Horizontal rule: ---, ***, ___
    ;; ===============================
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^[ \t]*\\(---+\\|\\*\\*\\*+\\|___+\\)[ \t]*$" nil t)
        (let* ((win   (get-buffer-window (current-buffer)))
               (width (if win (window-body-width win) 72))
               (rule  (make-string width ?─)))
          (put-text-property (match-beginning 0) (match-end 0)
                             'display (propertize rule 'face 'shadow)))))

    ;; ==================
    ;; Hard line break: \
    ;; ==================
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "\\\\[ \t]*\n" nil t)
        (put-text-property (match-beginning 0) (1- (match-end 0)) 'invisible t)))

    ;; =======
    ;; Headers
    ;; =======
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^\\(#\\{1,6\\}\\)\\([ \t]+\\)\\(.*?\\)[ \t]*$" nil t)
        (let* ((level    (length (match-string 1)))
               (hdr-beg  (match-beginning 1))
               (txt-beg  (match-beginning 3))
               (txt-end  (match-end 3))
               (face (pcase level
                       (1 '(:height 1.7 :weight bold :inherit markdown-header-face-1))
                       (2 '(:height 1.5 :weight bold :inherit markdown-header-face-2))
                       (3 '(:height 1.3 :weight bold :inherit markdown-header-face-3))
                       (4 '(:height 1.2 :weight bold :inherit markdown-header-face-4))
                       (5 '(:height 1.1 :weight bold :inherit markdown-header-face-5))
                       (_ '(:height 1.05 :weight bold :inherit markdown-header-face-6)))))
          (put-text-property hdr-beg txt-beg 'invisible t)
          (add-face-text-property txt-beg txt-end face t))))

    ;; ====
    ;; Bold
    ;; ====
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "\\*\\*\\([^*\n]+?\\)\\*\\*" nil t)
        (put-text-property (match-beginning 0) (+ (match-beginning 0) 2) 'invisible t)
        (put-text-property (- (match-end 0) 2) (match-end 0)            'invisible t)
        (add-face-text-property (match-beginning 1) (match-end 1) 'bold t)))

    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "__\\([^_\n]+?\\)__" nil t)
        (put-text-property (match-beginning 0) (+ (match-beginning 0) 2) 'invisible t)
        (put-text-property (- (match-end 0) 2) (match-end 0)            'invisible t)
        (add-face-text-property (match-beginning 1) (match-end 1) 'bold t)))

    ;; ======
    ;; Italic
    ;; ======
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "\\(?:^\\|[^*]\\)\\(\\*\\)\\([^*\n]+?\\)\\(\\*\\)\\(?:[^*]\\|$\\)" nil t)
        (put-text-property (match-beginning 1) (match-end 1) 'invisible t)
        (put-text-property (match-beginning 3) (match-end 3) 'invisible t)
        (add-face-text-property (match-beginning 2) (match-end 2) 'italic t)))

    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "\\(?:^\\|[^_]\\)\\(_\\)\\([^_\n]+?\\)\\(_\\)\\(?:[^_]\\|$\\)" nil t)
        (put-text-property (match-beginning 1) (match-end 1) 'invisible t)
        (put-text-property (match-beginning 3) (match-end 3) 'invisible t)
        (add-face-text-property (match-beginning 2) (match-end 2) 'italic t)))

    ;; =============
    ;; Strikethrough
    ;; =============
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "~~\\([^~\n]+?\\)~~" nil t)
        (put-text-property (match-beginning 0) (+ (match-beginning 0) 2) 'invisible t)
        (put-text-property (- (match-end 0) 2) (match-end 0)            'invisible t)
        (add-face-text-property (match-beginning 1) (match-end 1) '(:strike-through t) t)))

    ;; ===========
    ;; Inline code
    ;; ===========
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "`\\([^`\n]+?\\)`" nil t)
        (put-text-property (match-beginning 0) (1+ (match-beginning 0)) 'invisible t)
        (put-text-property (1- (match-end 0))  (match-end 0)            'invisible t)
        ;; OZNACZAMY jako kod, żeby nie ukrywać divów wewnątrz! Zaciągamy też motyw.
        (put-text-property (match-beginning 1) (match-end 1) 'my-code-tag t)
        (add-face-text-property (match-beginning 1) (match-end 1) 'markdown-inline-code-face t)))

    ;; =====
    ;; Links
    ;; =====
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "\\[\\([^]\n]+\\)\\](\\([^)\n]+\\))" nil t)
        (let ((url (match-string-no-properties 2))
              (map (make-sparse-keymap)))
          ;; Ukrywanie znaczników i zaciągnięcie motywu
          (put-text-property (match-beginning 0) (1+ (match-beginning 0)) 'invisible t)
          (put-text-property (match-end 1)       (match-end 0)            'invisible t)
          (add-face-text-property (match-beginning 1) (match-end 1) 'markdown-link-face t)
          
          ;; Mapowanie klawiszy: Enter i kliknięcie otwiera przeglądarkę
          (define-key map (kbd "RET") (lambda () (interactive) (browse-url url)))
          (define-key map [mouse-1]   (lambda () (interactive) (browse-url url)))
          (define-key map [mouse-2]   (lambda () (interactive) (browse-url url)))
          (put-text-property (match-beginning 1) (match-end 1) 'keymap map)
          
          ;; Bajery wizualne: efekt hover i dymek z pełnym adresem (tooltip)
          (put-text-property (match-beginning 1) (match-end 1) 'mouse-face 'highlight)
          (put-text-property (match-beginning 1) (match-end 1) 'help-echo url))))

    ;; ==========
    ;; Blockquote
    ;; ==========
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^\\(> ?\\)" nil t)
        (put-text-property (match-beginning 1) (match-end 1) 'invisible t)
        (add-face-text-property (match-end 1) (line-end-position) '(:inherit font-lock-string-face :slant italic) t)))

    ;; =====
    ;; Lists
    ;; =====
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^\\([ \t]*\\)\\([-*]\\)\\( \\)" nil t)
        (unless (looking-at "[-*]")
          (put-text-property (match-beginning 2) (match-end 2) 'display "•"))))

    ;; ==================
    ;; Fenced code blocks
    ;; ==================
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^\\(```\\).*\n" nil t)
        (let ((open-beg (match-beginning 0))
              (open-end (match-end 0)))
          (when (re-search-forward "^\\(```\\)[ \t]*$" nil t)
            (let* ((close-beg (match-beginning 0))
                   (close-end (match-end 0)))
              (put-text-property open-beg open-end 'invisible t)
              (put-text-property close-beg close-end 'invisible t)
              
              ;; OZNACZAMY wnętrze bloku jako kod
              (put-text-property open-end close-beg 'my-code-tag t)
              
              ;; DODANO: Motyw zamiast HEX-a i perfekcyjne rozciągnięcie tła (:extend t)
              ;; Obejmując obszar do close-beg, łapiemy znak \n z ostatniej linijki!
              (add-face-text-property open-end close-beg '(:inherit markdown-code-face :extend t) t))))))

    ;; ============================================
    ;; Tabele: Czyste malowanie krawędzi (motyw)
    ;; ============================================
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^[ \t]*|.*|$" nil t)
        (let ((row-beg (match-beginning 0))
              (row-end (match-end 0)))
          (save-excursion
            (goto-char row-beg)
            (while (re-search-forward "[|-]" row-end t)
              (add-face-text-property (match-beginning 0) (match-end 0) 'shadow t))))))

    ;; =======================================================
    ;; MAGICZNE UKRYWANIE <div> (Omija bloki kodu automatycznie)
    ;; =======================================================
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "</?div\\b[^>]*>" nil t)
        ;; Sprawdzamy czy nałożyliśmy tu nasz znacznik z pętli Inline/Fenced Code. 
        ;; Jeśli go nie ma — chowamy tag. Jeśli jest — zostawiamy go widocznym!
        (unless (get-text-property (match-beginning 0) 'my-code-tag)
          (put-text-property (match-beginning 0) (match-end 0) 'invisible t))))))

;;; ==================
;;; SYNC TEXT & TABLES
;;; ==================

(defun my/pv-sync ()
  "Zsynchronizuj lewy bufor z prawym, odśwież formatowanie i odpal LaTeXa."
  (let* ((sbuf  (current-buffer))
         (pbuf  (get-buffer (my/pv-name))))
    (when (and pbuf (buffer-live-p pbuf))
      (with-current-buffer pbuf
        (let ((inhibit-read-only        t)
              (inhibit-modification-hooks t))
              
          (replace-region-contents
           (point-min) (point-max)
           (lambda ()
             (with-current-buffer sbuf
               (buffer-substring-no-properties (point-min) (point-max)))))
               
          ;; Wbudowany mechanizm Emacsa do zrównywania tabel tekstowych
          (save-excursion
            (goto-char (point-min))
            (while (re-search-forward "^[ \t]*|.*|$" nil t)
              (beginning-of-line)
              (ignore-errors (markdown-table-align))
              (while (and (not (eobp)) (looking-at-p "^[ \t]*|.*|$"))
                (forward-line 1))))
        
          (my/pv-apply-formatting)
          (my/pv-schedule-texfrag (current-buffer)))))))

;;; =======
;;; TEXFRAG
;;; =======

(defun my/pv-schedule-texfrag (pbuf)
  "Zaplanuj texfrag-document w PBUF po opóźnieniu my/pv-latex-delay."
  (when (buffer-live-p pbuf)
    (with-current-buffer pbuf
      (when my/pv-latex-timer
        (cancel-timer my/pv-latex-timer)
        (setq my/pv-latex-timer nil))
      (when (bound-and-true-p texfrag-mode)
        (setq my/pv-latex-timer
              (run-with-timer
               my/pv-latex-delay nil
               (lambda ()
                 (when (and (buffer-live-p pbuf)
                            (buffer-local-value 'texfrag-mode pbuf))
                   (with-current-buffer pbuf
                     (let ((inhibit-read-only t)
                           (preview-auto-cache-preamble nil)
                           (TeX-PDF-mode nil)
                           (preview-image-type 'dvipng))
                       (ignore-errors (texfrag-document))))))))))))

;;; ===========
;;; SCROLL SYNC
;;; ===========

(defun my/pv-sync-scroll ()
  "Synchronizuj scroll i pozycję kursora do bufora preview."
  (when my/pv-active
    (let* ((pbuf (get-buffer (my/pv-name)))
           (pwin (and pbuf (get-buffer-window pbuf))))
      (when pwin
        (let ((sl (line-number-at-pos (window-start)))
              (cl (line-number-at-pos (point))))
          (with-selected-window pwin
            (goto-char (point-min))
            (forward-line (1- sl))
            (set-window-start pwin (point))
            (goto-char (point-min))
            (forward-line (1- cl))))))))

;;; ==============
;;; PREVIEW BUFFER
;;; ==============

(defun my/pv-init (sbuf pbuf)
  "Inicjalizuj PBUF jako preview dla SBUF."
  (let ((smode (buffer-local-value 'major-mode sbuf)))
    (with-current-buffer pbuf
      (let ((inhibit-read-only        t)
            (inhibit-modification-hooks t))

        (erase-buffer)
        (insert (with-current-buffer sbuf
                  (buffer-substring-no-properties (point-min) (point-max))))

        (cond
         ((memq smode '(markdown-mode gfm-mode))
          (funcall smode)
          (font-lock-mode -1)
          (jit-lock-mode -1))
         ((eq smode 'org-mode)
          (setq-local org-hide-emphasis-markers t)
          (setq-local org-hide-leading-stars    t)
          (setq-local org-pretty-entities       t)
          (org-mode)
          (font-lock-mode -1)
          (jit-lock-mode -1)))

        (add-to-invisibility-spec t)

        (when (featurep 'texfrag)
          (make-directory my/pv-texfrag-dir t)
          (setq-local texfrag-subdir my/pv-texfrag-dir)
          (texfrag-mode 1))

        (when (fboundp 'display-line-numbers-mode)
          (display-line-numbers-mode -1))
        (when (boundp 'linum-mode)
          (linum-mode -1))

        (setq-local line-spacing my/pv-line-spacing)
        (setq-local cursor-type  nil)
        (setq-local truncate-lines nil)
        (setq buffer-read-only t)))))

;;; ======
;;; TOGGLE
;;; ======

(defun my/pv-supported-mode-p ()
  "Zwraca non-nil jeśli bieżący tryb obsługuje preview."
  (memq major-mode '(markdown-mode gfm-mode org-mode latex-mode LaTeX-mode)))

(defun my/pv-is-preview-buffer-p ()
  "Zwraca non-nil jeśli bieżący bufor to bufor preview."
  (string-prefix-p "*Preview " (buffer-name)))

(defun my/pv-close ()
  "Zamknij preview dla bieżącego bufora źródłowego."
  (let ((pname (my/pv-name)))
    (when my/pv-latex-timer
      (cancel-timer my/pv-latex-timer)
      (setq my/pv-latex-timer nil))
    (when-let* ((pbuf (get-buffer pname)))
      (when (buffer-live-p pbuf)
        (with-current-buffer pbuf
          (when (bound-and-true-p texfrag-mode)
            (ignore-errors (texfrag-mode -1)))))
      (when-let* ((w (get-buffer-window pname)))
        (delete-window w))
      (when (buffer-live-p (get-buffer pname))
        (kill-buffer pname)))
        
    (remove-hook 'post-command-hook #'my/pv-sync-scroll   t)
    (remove-hook 'after-save-hook   #'my/pv-sync t)
    
    (setq my/pv-active nil)
    (setq my/pv-source-buffer nil)
    (message "Preview OFF")))

(defun my/toggle-live-preview ()
  "Włącz/wyłącz podgląd na żywo."
  (interactive)
  (when (my/pv-is-preview-buffer-p)
    (user-error "Jesteś w buforze preview — wróć do lewego bufora i użyj SPC m"))
  (unless (my/pv-supported-mode-p)
    (user-error "Preview działa tylko w markdown, org i LaTeX (current: %s)" major-mode))

  (let ((sbuf (current-buffer)))
    (cond
     ((and my/pv-source-buffer (eq my/pv-source-buffer sbuf))
      (with-current-buffer sbuf (my/pv-close)))

     (my/pv-source-buffer
      (with-current-buffer my/pv-source-buffer (my/pv-close))
      (my/pv-open sbuf))

     (t
      (my/pv-open sbuf)))))

(defun my/pv-open (sbuf)
  "Otwórz preview dla bufora SBUF."
  (let ((pname (with-current-buffer sbuf (my/pv-name))))
    (with-current-buffer sbuf
      (when (memq major-mode '(markdown-mode gfm-mode))
        (setq-local markdown-hide-markup nil)
        (setq face-remapping-alist
              (cl-remove-if (lambda (x)
                              (memq (car x)
                                    '(markdown-header-face-1
                                      markdown-header-face-2
                                      markdown-header-face-3
                                      markdown-header-face-4
                                      markdown-header-face-5
                                      markdown-header-face-6)))
                            face-remapping-alist))
        (font-lock-flush)
        (font-lock-ensure))
      (when (eq major-mode 'org-mode)
        (setq-local org-hide-emphasis-markers nil)
        (font-lock-flush)
        (font-lock-ensure)))

    (let ((pbuf (get-buffer-create pname)))
      (let ((pwin (split-window-right)))
        (set-window-buffer pwin pbuf)
        (run-with-timer 0.1 nil
                        (lambda (s p w lm rm)
                          (when (buffer-live-p s)
                            (with-current-buffer s
                              (my/pv-init s p)
                              (my/pv-sync))
                            (set-window-margins w lm rm)))
                        sbuf pbuf pwin my/pv-left-margin my/pv-right-margin))))

    (with-current-buffer sbuf
      (setq my/pv-active t)
      (setq my/pv-source-buffer sbuf)
      (add-hook 'post-command-hook #'my/pv-sync-scroll nil t)
      (add-hook 'after-save-hook   #'my/pv-sync nil t))
    (message "Live Preview ON! 🚀"))

;;; ==========
;;; KEYBINDING
;;; ==========

(with-eval-after-load 'evil
  (evil-define-key 'normal 'global (kbd "SPC m") #'my/toggle-live-preview))

(provide 'setup-preview)
