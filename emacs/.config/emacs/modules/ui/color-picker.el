;;; color-picker.el --- Native interactive HSL/RGB color picker for Emacs -*- lexical-binding: t; -*-

(require 'color)
(require 'cl-lib)

(defvar my/color-picker-target-buffer nil)
(defvar my/color-picker-marker-start nil)
(defvar my/color-picker-marker-end nil)
(defvar my/color-picker-orig-hex nil)

(defvar my/color-picker-cur-h 0.0)
(defvar my/color-picker-cur-s 0.0)
(defvar my/color-picker-cur-l 0.0)
(defvar my/color-picker-cur-r 0.0)
(defvar my/color-picker-cur-g 0.0)
(defvar my/color-picker-cur-b 0.0)

(defun my/color-picker-cur-hex ()
  "Return current color as a lowercase #RRGGBB hex string."
  (color-rgb-to-hex my/color-picker-cur-r
                    my/color-picker-cur-g
                    my/color-picker-cur-b 2))

(defun my/color-picker-sync-from-hsl ()
  "Update RGB values from current HSL."
  (let ((rgb (color-hsl-to-rgb my/color-picker-cur-h
                               my/color-picker-cur-s
                               my/color-picker-cur-l)))
    (setq my/color-picker-cur-r (nth 0 rgb)
          my/color-picker-cur-g (nth 1 rgb)
          my/color-picker-cur-b (nth 2 rgb))))

(defun my/color-picker-sync-from-rgb ()
  "Update HSL values from current RGB."
  (let ((hsl (color-rgb-to-hsl my/color-picker-cur-r
                               my/color-picker-cur-g
                               my/color-picker-cur-b)))
    (setq my/color-picker-cur-h (nth 0 hsl)
          my/color-picker-cur-s (nth 1 hsl)
          my/color-picker-cur-l (nth 2 hsl))))

(defun my/color-picker-update-target-buffer ()
  "Update the hex string in the target buffer in real-time."
  (when (and (buffer-live-p my/color-picker-target-buffer)
             (marker-position my/color-picker-marker-start)
             (marker-position my/color-picker-marker-end))
    (with-current-buffer my/color-picker-target-buffer
      (save-excursion
        (let ((start (marker-position my/color-picker-marker-start))
              (end (marker-position my/color-picker-marker-end))
              (new-hex (my/color-picker-cur-hex)))
          (goto-char start)
          (delete-region start end)
          (insert new-hex)
          (set-marker my/color-picker-marker-end (point))
          (font-lock-flush start (point)))))))

(defun my/color-picker-step (type delta)
  "Step parameter TYPE by DELTA units."
  (interactive)
  (cl-case type
    (h
     (let ((deg (+ (round (* my/color-picker-cur-h 360)) delta)))
       (setq my/color-picker-cur-h (/ (mod (float deg) 360.0) 360.0))
       (my/color-picker-sync-from-hsl)))
    (s
     (let ((pct (+ (round (* my/color-picker-cur-s 100)) delta)))
       (setq my/color-picker-cur-s (/ (max 0.0 (min 100.0 (float pct))) 100.0))
       (my/color-picker-sync-from-hsl)))
    (l
     (let ((pct (+ (round (* my/color-picker-cur-l 100)) delta)))
       (setq my/color-picker-cur-l (/ (max 0.0 (min 100.0 (float pct))) 100.0))
       (my/color-picker-sync-from-hsl)))
    (r
     (let ((val (+ (round (* my/color-picker-cur-r 255)) delta)))
       (setq my/color-picker-cur-r (/ (max 0.0 (min 255.0 (float val))) 255.0))
       (my/color-picker-sync-from-rgb)))
    (g
     (let ((val (+ (round (* my/color-picker-cur-g 255)) delta)))
       (setq my/color-picker-cur-g (/ (max 0.0 (min 255.0 (float val))) 255.0))
       (my/color-picker-sync-from-rgb)))
    (b
     (let ((val (+ (round (* my/color-picker-cur-b 255)) delta)))
       (setq my/color-picker-cur-b (/ (max 0.0 (min 255.0 (float val))) 255.0))
       (my/color-picker-sync-from-rgb))))
  (my/color-picker-update-target-buffer)
  (my/color-picker-render))

(defun my/color-picker-set-ratio (type ratio)
  "Set parameter TYPE according to RATIO in [0.0, 1.0]."
  (cl-case type
    (h (setq my/color-picker-cur-h (max 0.0 (min 1.0 ratio)))
       (my/color-picker-sync-from-hsl))
    (s (setq my/color-picker-cur-s (max 0.0 (min 1.0 ratio)))
       (my/color-picker-sync-from-hsl))
    (l (setq my/color-picker-cur-l (max 0.0 (min 1.0 ratio)))
       (my/color-picker-sync-from-hsl))
    (r (setq my/color-picker-cur-r (max 0.0 (min 1.0 ratio)))
       (my/color-picker-sync-from-rgb))
    (g (setq my/color-picker-cur-g (max 0.0 (min 1.0 ratio)))
       (my/color-picker-sync-from-rgb))
    (b (setq my/color-picker-cur-b (max 0.0 (min 1.0 ratio)))
       (my/color-picker-sync-from-rgb)))
  (my/color-picker-update-target-buffer)
  (my/color-picker-render))

(defun my/color-picker-make-slider (type fraction width)
  "Render a clickable slider bar for TYPE with FRACTION value."
  (let* ((w (max 10 width))
         (pos (min (1- w) (max 0 (round (* fraction (1- w))))))
         (res ""))
    (dotimes (i w)
      (let* ((char (if (= i pos) ?| ?-))
             (ratio (/ (float i) (float (1- w))))
             (map (make-sparse-keymap)))
        (define-key map [mouse-1] (lambda () (interactive) (my/color-picker-set-ratio type ratio)))
        (define-key map [down-mouse-1] #'ignore)
        (define-key map [wheel-up] (lambda () (interactive) (my/color-picker-step type 1)))
        (define-key map [wheel-down] (lambda () (interactive) (my/color-picker-step type -1)))
        (setq res (concat res (propertize (string char)
                                          'keymap map
                                          'mouse-face 'highlight
                                          'face (if (= i pos) 'bold 'default)
                                          'help-echo (format "Ustaw wartość na %.0f%%" (* ratio 100)))))))
    (concat "[" res "]")))

(defun my/color-picker-make-btn (label type delta)
  "Create a clickable adjustment button."
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] (lambda () (interactive) (my/color-picker-step type delta)))
    (define-key map [down-mouse-1] #'ignore)
    (propertize (format " [%s] " label)
                'keymap map
                'mouse-face 'highlight
                'face 'custom-button
                'help-echo (format "Zmień o %s" label))))

(defun my/color-picker-prompt-hex ()
  "Prompt user to manually type or paste a hex color code."
  (interactive)
  (let ((input (read-string (format "Wprowadź HEX (obecny %s): " (my/color-picker-cur-hex)))))
    (when (and input (not (string-empty-p (string-trim input))))
      (setq input (string-trim input))
      (unless (string-prefix-p "#" input)
        (setq input (concat "#" input)))
      (if (string-match "^#[0-9a-fA-F]\\{6\\}$" input)
          (let ((rgb (color-name-to-rgb input)))
            (setq my/color-picker-cur-r (nth 0 rgb)
                  my/color-picker-cur-g (nth 1 rgb)
                  my/color-picker-cur-b (nth 2 rgb))
            (my/color-picker-sync-from-rgb)
            (my/color-picker-update-target-buffer)
            (my/color-picker-render))
        (message "Nieprawidłowy format HEX (#RRGGBB): %s" input)))))

(defun my/color-picker-restore-original ()
  "Restore the original hex color in target buffer."
  (interactive)
  (when my/color-picker-orig-hex
    (let ((rgb (color-name-to-rgb my/color-picker-orig-hex)))
      (setq my/color-picker-cur-r (nth 0 rgb)
            my/color-picker-cur-g (nth 1 rgb)
            my/color-picker-cur-b (nth 2 rgb))
      (my/color-picker-sync-from-rgb)
      (my/color-picker-update-target-buffer)
      (my/color-picker-render)
      (message "Przywrócono oryginalny kolor: %s" my/color-picker-orig-hex))))

(defun my/color-picker-confirm ()
  "Confirm color choice and close picker."
  (interactive)
  (let ((final-hex (my/color-picker-cur-hex)))
    (quit-window t)
    (message "Zatwierdzono kolor: %s" final-hex)))

(defun my/color-picker-cancel ()
  "Cancel adjustments, restore original hex, and close picker."
  (interactive)
  (my/color-picker-restore-original)
  (quit-window t)
  (message "Anulowano zmianę koloru"))

(defvar my-color-picker-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Hue
    (define-key map (kbd "h") (lambda () (interactive) (my/color-picker-step 'h -1)))
    (define-key map (kbd "H") (lambda () (interactive) (my/color-picker-step 'h 1)))
    (define-key map (kbd "C-h") (lambda () (interactive) (my/color-picker-step 'h -10)))
    (define-key map (kbd "M-h") (lambda () (interactive) (my/color-picker-step 'h 10)))
    ;; Saturation
    (define-key map (kbd "s") (lambda () (interactive) (my/color-picker-step 's -1)))
    (define-key map (kbd "S") (lambda () (interactive) (my/color-picker-step 's 1)))
    ;; Lightness
    (define-key map (kbd "l") (lambda () (interactive) (my/color-picker-step 'l -1)))
    (define-key map (kbd "L") (lambda () (interactive) (my/color-picker-step 'l 1)))
    ;; Red
    (define-key map (kbd "r") (lambda () (interactive) (my/color-picker-step 'r -1)))
    (define-key map (kbd "R") (lambda () (interactive) (my/color-picker-step 'r 1)))
    ;; Green
    (define-key map (kbd "g") (lambda () (interactive) (my/color-picker-step 'g -1)))
    (define-key map (kbd "G") (lambda () (interactive) (my/color-picker-step 'g 1)))
    ;; Blue
    (define-key map (kbd "b") (lambda () (interactive) (my/color-picker-step 'b -1)))
    (define-key map (kbd "B") (lambda () (interactive) (my/color-picker-step 'b 1)))
    ;; Direct input & reset
    (define-key map (kbd "c") #'my/color-picker-prompt-hex)
    (define-key map (kbd "e") #'my/color-picker-prompt-hex)
    (define-key map (kbd "o") #'my/color-picker-restore-original)
    (define-key map (kbd "u") #'my/color-picker-restore-original)
    ;; Confirm / Cancel
    (define-key map (kbd "RET") #'my/color-picker-confirm)
    (define-key map (kbd "q") #'my/color-picker-confirm)
    (define-key map (kbd "C-g") #'my/color-picker-cancel)
    (define-key map [escape] #'my/color-picker-cancel)
    map)
  "Keymap for `my-color-picker-mode'.")

(define-derived-mode my-color-picker-mode special-mode "ColorPicker"
  "Major mode for the native Emacs color picker buffer."
  (setq buffer-read-only t
        truncate-lines t)
  (buffer-disable-undo))

(with-eval-after-load 'evil
  (evil-set-initial-state 'my-color-picker-mode 'emacs))

(defun my/color-picker-render ()
  "Render the visual color picker buffer with HSL and RGB sliders."
  (let* ((buf (get-buffer "*Color Picker*"))
         (hex (my/color-picker-cur-hex))
         (h-deg (round (* my/color-picker-cur-h 360)))
         (s-pct (round (* my/color-picker-cur-s 100)))
         (l-pct (round (* my/color-picker-cur-l 100)))
         (r-val (round (* my/color-picker-cur-r 255)))
         (g-val (round (* my/color-picker-cur-g 255)))
         (b-val (round (* my/color-picker-cur-b 255)))
         (text-color (if (> (color-distance hex "#ffffff")
                            (color-distance hex "#000000"))
                         "#ffffff" "#000000")))
    (when (buffer-live-p buf)
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert " ")
          (insert (propertize (format "      KOLOR:  %s      " hex)
                              'face (list :foreground text-color
                                          :background hex
                                          :weight 'bold
                                          :height 1.2)))
          (insert (format "   (Oryginał: %s)\n\n" my/color-picker-orig-hex))

          ;; HSL Section
          (insert "   [HSL]\n")
          (insert (format "   Hue (h/H):         %s  %3d°  "
                          (my/color-picker-make-slider 'h my/color-picker-cur-h 28)
                          h-deg))
          (insert (my/color-picker-make-btn "-10" 'h -10))
          (insert (my/color-picker-make-btn "-1" 'h -1))
          (insert (my/color-picker-make-btn "+1" 'h 1))
          (insert (my/color-picker-make-btn "+10" 'h 10))
          (insert "\n")

          (insert (format "   Saturation (s/S):  %s  %3d%%  "
                          (my/color-picker-make-slider 's my/color-picker-cur-s 28)
                          s-pct))
          (insert (my/color-picker-make-btn "-10" 's -10))
          (insert (my/color-picker-make-btn "-1" 's -1))
          (insert (my/color-picker-make-btn "+1" 's 1))
          (insert (my/color-picker-make-btn "+10" 's 10))
          (insert "\n")

          (insert (format "   Lightness (l/L):   %s  %3d%%  "
                          (my/color-picker-make-slider 'l my/color-picker-cur-l 28)
                          l-pct))
          (insert (my/color-picker-make-btn "-10" 'l -10))
          (insert (my/color-picker-make-btn "-1" 'l -1))
          (insert (my/color-picker-make-btn "+1" 'l 1))
          (insert (my/color-picker-make-btn "+10" 'l 10))
          (insert "\n\n")

          ;; RGB Section
          (insert "   [RGB]\n")
          (insert (format "   Red (r/R):         %s  %3d   "
                          (my/color-picker-make-slider 'r my/color-picker-cur-r 28)
                          r-val))
          (insert (my/color-picker-make-btn "-10" 'r -10))
          (insert (my/color-picker-make-btn "-1" 'r -1))
          (insert (my/color-picker-make-btn "+1" 'r 1))
          (insert (my/color-picker-make-btn "+10" 'r 10))
          (insert "\n")

          (insert (format "   Green (g/G):       %s  %3d   "
                          (my/color-picker-make-slider 'g my/color-picker-cur-g 28)
                          g-val))
          (insert (my/color-picker-make-btn "-10" 'g -10))
          (insert (my/color-picker-make-btn "-1" 'g -1))
          (insert (my/color-picker-make-btn "+1" 'g 1))
          (insert (my/color-picker-make-btn "+10" 'g 10))
          (insert "\n")

          (insert (format "   Blue (b/B):        %s  %3d   "
                          (my/color-picker-make-slider 'b my/color-picker-cur-b 28)
                          b-val))
          (insert (my/color-picker-make-btn "-10" 'b -10))
          (insert (my/color-picker-make-btn "-1" 'b -1))
          (insert (my/color-picker-make-btn "+1" 'b 1))
          (insert (my/color-picker-make-btn "+10" 'b 10))
          (insert "\n\n")

          (insert "   [Skróty: h/s/l/r/g/b (-), H/S/L/R/G/B (+), c (wpisz hex), o (oryginał), RET/q (zatwierdź), C-g (anuluj)]")
          (goto-char (point-min)))))))

;;;###autoload
(defun my/color-picker-at-point (&optional event)
  "Open native interactive Emacs color picker with HSL/RGB sliders for hex at point."
  (interactive (list last-input-event))
  (when (and event (mouse-event-p event))
    (mouse-set-point event))
  (let* ((hex-regexp "#[0-9a-fA-F]\\{6\\}")
         (bounds (save-excursion
                   (skip-chars-backward "#0-9a-fA-F")
                   (when (looking-at hex-regexp)
                     (cons (match-beginning 0) (match-end 0)))))
         (hex (when bounds (buffer-substring-no-properties (car bounds) (cdr bounds)))))
    (if (not (and bounds hex))
        (message "Brak koloru hex (#RRGGBB) pod kursorem!")
      (let* ((rgb (color-name-to-rgb hex))
             (hsl (apply #'color-rgb-to-hsl rgb)))
        (setq my/color-picker-target-buffer (current-buffer)
              my/color-picker-marker-start (copy-marker (car bounds))
              my/color-picker-marker-end (copy-marker (cdr bounds) t)
              my/color-picker-orig-hex (downcase hex)
              my/color-picker-cur-r (nth 0 rgb)
              my/color-picker-cur-g (nth 1 rgb)
              my/color-picker-cur-b (nth 2 rgb)
              my/color-picker-cur-h (nth 0 hsl)
              my/color-picker-cur-s (nth 1 hsl)
              my/color-picker-cur-l (nth 2 hsl))
        (let ((buf (get-buffer-create "*Color Picker*")))
          (with-current-buffer buf
            (my-color-picker-mode)
            (my/color-picker-render))
          (select-window
           (display-buffer-at-bottom buf '((window-height . 17)))))))))

(provide 'color-picker)
;;; color-picker.el ends here
