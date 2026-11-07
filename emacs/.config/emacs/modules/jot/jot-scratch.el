;;; -*- lexical-binding: t; -*-

;; The SCRATCH note behind $mod+grave in my sway config.
;; It lives in jot-dir and is linked to a SCRATCH session, so a tmux
;; session or a perspective named SCRATCH opens the same file in
;; tmux-jot and jot.el.

(require 'jot)

(defconst my/jot-scratch-note "SCRATCH")

(defun my/jot-scratch-frame-p (&optional frame)
  "Return non-nil if FRAME is the sway scratchpad frame of the SCRATCH note."
  (frame-parameter frame 'my/jot-scratch))

(defun my/jot-scratch-open ()
  "Show the SCRATCH note in the selected frame and mark it as its frame.
Called by sway/.config/sway/scripts/jot-scratch.sh in a new client frame."
  (let ((file (jot--note-path my/jot-scratch-note)))
    (unless (file-exists-p file)
      (write-region "" nil file nil 'silent))
    (unless (equal (jot-session-linked-file my/jot-scratch-note)
                   (file-truename file))
      (jot-link-note-to-session file my/jot-scratch-note))
    (set-frame-parameter nil 'my/jot-scratch t)
    (switch-to-buffer
     (jot--get-or-create-buffer file my/jot-scratch-note my/jot-scratch-note))
    (delete-other-windows)))

(defun my/jot-scratch-save ()
  "Save the SCRATCH note if it has unsaved changes."
  (when-let* ((buf (get-file-buffer (jot--note-path my/jot-scratch-note))))
    (with-current-buffer buf
      (when (buffer-modified-p)
        (save-buffer)))))

(defun my/jot-scratch-hide (orig-fn &rest args)
  "Send the scratchpad frame back to the sway scratchpad, else call ORIG-FN.
This makes q and C-c C-c of `jot-buffer-mode' work in that frame."
  (if (my/jot-scratch-frame-p)
      (progn
        (my/jot-scratch-save)
        (call-process "swaymsg" nil 0 nil
                      "[con_mark=\"jot_scratch\"] move scratchpad"))
    (apply orig-fn args)))

(advice-add 'jot-hide :around #'my/jot-scratch-hide)

;; $mod+grave hides the frame without Emacs knowing,
;; so save when it loses focus, for tmux-jot to read it current
(defun my/jot-scratch-save-on-blur ()
  "Save the SCRATCH note when its scratchpad frame loses focus."
  (dolist (frame (frame-list))
    (when (and (my/jot-scratch-frame-p frame)
               (not (frame-focus-state frame)))
      (my/jot-scratch-save))))

(add-function :after after-focus-change-function #'my/jot-scratch-save-on-blur)

(provide 'jot-scratch)
