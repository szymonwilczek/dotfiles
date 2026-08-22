;;; Zen writing -*- lexical-binding: t; -*-

(require 'cl-lib)

;; Storage directory
(defcustom my/writings-directory (expand-file-name "~/Dokumenty/writings")
  "Directory where poetry, meditations, and philosophical reflections are stored."
  :type 'directory
  :group 'writings)

(unless (file-directory-p my/writings-directory)
  (make-directory my/writings-directory t))

(use-package olivetti
  :ensure t
  :custom
  (olivetti-body-width 74)
  (olivetti-minimum-body-width 60)
  (olivetti-recall-visual-line-mode-entry-state t))

;; Zen Writings Mode
(defvar-local my/writings--saved-line-numbers nil
  "Stores state of line numbers before entering zen writings mode.")

(defun my/writings-zen-toggle ()
  "Toggle distraction-free Zen Writings mode with centered text and soft wrap."
  (interactive)
  (if (bound-and-true-p olivetti-mode)
      (progn
        (olivetti-mode -1)
        (when my/writings--saved-line-numbers
          (display-line-numbers-mode 1))
        (message "Writings Zen Mode: OFF"))
    (setq my/writings--saved-line-numbers (bound-and-true-p display-line-numbers-mode))
    (display-line-numbers-mode -1)
    (visual-line-mode 1)
    (olivetti-mode 1)
    (message "🧘 Writings Zen Mode: ON (%d columns)" olivetti-body-width)))

;; Helper to create URL/filename-friendly slug
(defun my/writings--slugify (str)
  "Convert STR into a clean filename-safe slug."
  (let* ((slug (downcase str))
         ;; replace polish diacritics
         (slug (replace-regexp-in-string "[ąćęłńóśźż]"
                                         (lambda (ch)
                                           (pcase ch
                                             ("ą" "a") ("ć" "c") ("ę" "e") ("ł" "l")
                                             ("ń" "n") ("ó" "o") ("ś" "s") ("ź" "z") ("ż" "z")))
                                         slug))
         ;; replace non-alphanumeric with hyphens
         (slug (replace-regexp-in-string "[^a-z0-9]+" "-" slug))
         ;; trim leading/trailing hyphens
         (slug (replace-regexp-in-string "^-\\|-$" "" slug)))
    (if (string-blank-p slug) "wpis" slug)))

(defun my/writings-new ()
  "Create a new timestamped poetry or philosophical meditation note."
  (interactive)
  (let* ((title (read-string "Tytuł: "))
         (type (completing-read "Rodzaj wpisu: " '("Wiersz" "Esej" "Czysty tekst") nil t))
         (timestamp (format-time-string "%Y%m%d-%H%M"))
         (date-header (format-time-string "[%Y-%m-%d %a %H:%M]"))
         (slug (my/writings--slugify (if (string-blank-p title) "rozmyslania" title)))
         (filename (format "%s--%s.org" timestamp slug))
         (filepath (expand-file-name filename my/writings-directory)))
    (find-file filepath)
    (when (= (buffer-size) 0)
      (insert (format "#+title: %s\n" (if (string-blank-p title) "Bez tytułu" title)))
      (insert (format "#+date: %s\n" date-header))
      (pcase type
        ("Wiersz"
         (insert "#+filetags: :poezja:tworczosc:\n\n")
         (insert "#+begin_verse\n")
         (save-excursion
           (insert "\n#+end_verse\n")))
        ("Esej"
         (insert "#+filetags: :rozmyslania:filozofia:\n\n"))
        (_
         (insert "#+filetags: :notatki:\n\n")))
      (save-buffer))
    (unless (bound-and-true-p olivetti-mode)
      (my/writings-zen-toggle))
    (goto-char (point-max))
    (when (string-equal type "Wiersz")
      (forward-line -1))
    (when (fboundp 'evil-insert-state)
      (evil-insert-state))))

(defun my/writings-find ()
  "Interactively browse and open writings."
  (interactive)
  (let ((default-directory my/writings-directory))
    (if (fboundp 'consult-find)
        (consult-find my/writings-directory)
      (call-interactively #'find-file))))

(defun my/writings-insert-verse ()
  "Insert an Org verse block for poetry."
  (interactive)
  (insert "#+begin_verse\n\n#+end_verse")
  (forward-line -1)
  (when (fboundp 'evil-insert-state)
    (evil-insert-state)))

(defun my/writings-insert-quote ()
  "Insert an Org quote block for aphorisms or citations."
  (interactive)
  (insert "#+begin_quote\n\n#+end_quote")
  (forward-line -1)
  (when (fboundp 'evil-insert-state)
    (evil-insert-state)))

(defun my/writings-widen ()
  "Widen writing column by 2 characters."
  (interactive)
  (setq olivetti-body-width (+ olivetti-body-width 2))
  (when (bound-and-true-p olivetti-mode)
    (olivetti-set-environment))
  (message "Writing width: %d columns" olivetti-body-width))

(defun my/writings-narrow ()
  "Narrow writing column by 2 characters."
  (interactive)
  (setq olivetti-body-width (max 50 (- olivetti-body-width 2)))
  (when (bound-and-true-p olivetti-mode)
    (olivetti-set-environment))
  (message "Writing width: %d columns" olivetti-body-width))

(require 'writings-keys)

(provide 'writings-mod)
