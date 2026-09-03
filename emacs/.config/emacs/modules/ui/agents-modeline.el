;;; agents-modeline.el --- AI agent buffer statusline -*- lexical-binding: t; -*-

(require 'cl-lib)

(defvar my/agent-claude-quota-data nil)
(defvar my/agent-antigravity-quota-data nil)
(defvar-local my/agent-buffer-p nil)
(defvar-local my/agent-type nil)

(declare-function my/modeline-evil-mode-info "modeline")
(declare-function my/modeline-filename "modeline")

(defun my/agents-modeline-buffer-type (&optional buffer)
  "Return agent type symbol for BUFFER ('claude, 'antigravity, etc.)."
  (let* ((buf (or buffer (current-buffer)))
         (name (downcase (buffer-name buf))))
    (with-current-buffer buf
      (or (and (bound-and-true-p my/agent-type)
               (intern (downcase (format "%s" my/agent-type))))
          (cond
           ((string-match-p "agent-claude" name) 'claude)
           ((string-match-p "agent-antigravity" name) 'antigravity)
           ((string-match-p "claude" name) 'claude)
           ((string-match-p "antigravity\\|agy" name) 'antigravity)
           ((or (bound-and-true-p my/agent-buffer-p)
                (string-match-p "\\*agent-" name))
            'generic)
           (t nil))))))

;; alias for agent-mod compatibility
(defalias 'my/agent-buffer-type 'my/agents-modeline-buffer-type)

(defun my/agents-modeline-buffer-p (&optional buffer)
  "Return non-nil if BUFFER is an AI agent buffer."
  (let ((type (my/agents-modeline-buffer-type buffer)))
    (not (null type))))

(defun my/agents-modeline--format-reset-time (reset-str)
  "Format time remaining until RESET-STR as compact human-readable string."
  (if (or (null reset-str) (string-empty-p reset-str))
      ""
    (condition-case nil
        (let* ((target-time (parse-iso8601-time-string reset-str))
               (diff (ceiling (float-time (time-subtract target-time (current-time)))))
               (diff (max 0 diff)))
          (cond
           ((<= diff 0) "0m")
           ((< diff 3600) (format "%dm" (ceiling (/ diff 60.0))))
           ((< diff 86400)
            (let ((hours (/ diff 3600))
                  (mins (/ (% diff 3600) 60)))
              (if (> mins 0)
                  (format "%dh%dm" hours mins)
                (format "%dh" hours))))
           (t
            (let ((days (/ diff 86400))
                  (hours (/ (% diff 86400) 3600)))
              (if (> hours 0)
                  (format "%dd%dh" days hours)
                (format "%dd" days))))))
      (error ""))))

(defun my/agents-modeline--usage-face (pct)
  "Return face for usage PCT from active theme: <75 default, 75-89 warning, >=90 error."
  (cond
   ((>= pct 90) '(:inherit error :weight bold))
   ((>= pct 75) '(:inherit warning :weight bold))
   (t '(:inherit default :weight bold))))

(defun my/agents-modeline--format-quota-item (label pct reset-str)
  "Format LABEL (theme text), PCT (warning/error/default) and RESET-STR (comment face)."
  (let* ((lbl-face '(:inherit default :weight bold))
         (val-face (my/agents-modeline--usage-face (or pct 0)))
         (rst-str (my/agents-modeline--format-reset-time reset-str))
         (rst-part (if (string-empty-p rst-str)
                       ""
                     (concat " " (propertize (format "(%s)" rst-str)
                                             'face 'font-lock-comment-face)))))
    (concat (propertize label 'face lbl-face)
            " "
            (propertize (format "%d%%%%" (or pct 0)) 'face val-face)
            rst-part)))

(defun my/agents-modeline-render-usage (active &optional buffer)
  "Render formatted usage string for BUFFER depending on ACTIVE state."
  (let ((type (my/agents-modeline-buffer-type buffer))
        (sep (propertize " | " 'face 'shadow)))
    (pcase type
      ('claude
       (when (bound-and-true-p my/agent-claude-quota-data)
         (let* ((c-logo (propertize "󰘑" 'face (if active
                                                  '(:foreground "#da7756" :weight bold)
                                                'shadow)))
                (u5 (alist-get '5h-util my/agent-claude-quota-data))
                (r5 (alist-get '5h-reset my/agent-claude-quota-data))
                (u7 (alist-get '7d-util my/agent-claude-quota-data))
                (r7 (alist-get '7d-reset my/agent-claude-quota-data)))
           (concat " " c-logo sep
                   (my/agents-modeline--format-quota-item "5h:" u5 r5)
                   sep
                   (my/agents-modeline--format-quota-item "7d:" u7 r7)
                   " "))))
      ('antigravity
       (when (bound-and-true-p my/agent-antigravity-quota-data)
         (let* ((g-logo (propertize "󰊭" 'face (if active
                                                  '(:foreground "#4285f4" :weight bold)
                                                'shadow)))
                (g-5h (alist-get 'gemini-5h-util my/agent-antigravity-quota-data))
                (g-5r (alist-get 'gemini-5h-reset my/agent-antigravity-quota-data))
                (g-7d (alist-get 'gemini-7d-util my/agent-antigravity-quota-data))
                (g-7r (alist-get 'gemini-7d-reset my/agent-antigravity-quota-data)))
           (concat " " g-logo sep
                   (my/agents-modeline--format-quota-item "5h:" g-5h g-5r)
                   sep
                   (my/agents-modeline--format-quota-item "7d:" g-7d g-7r)
                   " "))))
      (_ ""))))

(defun my/agents-modeline-render ()
  "Render statusline for AI agent buffers."
  (let* ((selected (mode-line-window-selected-p))
         (usage (or (my/agents-modeline-render-usage selected) ""))
         (usage-w (string-width (format-mode-line usage))))
    (if (not selected)
        ;; inactive window
        (let ((lhs-w (string-width (format-mode-line (concat " " (my/modeline-filename))))))
          (if (and (> usage-w 0) (< (+ lhs-w usage-w 2) (window-width)))
              (concat " " (my/modeline-filename)
                      (propertize " " 'display `(space :align-to (- right ,usage-w)))
                      usage)
            (concat " " (my/modeline-filename) " " usage)))
      ;; active window
      (let* ((lhs (concat (my/modeline-evil-mode-info)
                          (my/modeline-filename)))
             (lhs-w (string-width (format-mode-line lhs))))
        (if (and (> usage-w 0) (< (+ lhs-w usage-w 2) (window-width)))
            (concat lhs
                    (propertize " " 'display `(space :align-to (- right ,usage-w)))
                    usage)
          (concat lhs " " usage))))))

(provide 'agents-modeline)
