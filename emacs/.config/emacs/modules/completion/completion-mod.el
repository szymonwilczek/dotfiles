;;; Minad stack minibuffer and Company completion -*- lexical-binding: t; -*-

;; Minibuffer Completion
;; (Vertico + Orderless + Marginalia + Consult)
(use-package vertico
  :ensure t
  :init
  (vertico-mode 1)
  :config
  (setq vertico-count 12
        vertico-cycle t))

(use-package savehist
  :ensure nil
  :init
  (savehist-mode 1))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode 1))

(use-package nerd-icons-completion
  :ensure t
  :after (marginalia nerd-icons)
  :config
  (nerd-icons-completion-mode 1))

(require 'cl-lib)

(defun my/project-root (&optional _may-prompt)
  "Return the root directory of the current project or perspective.
The optional argument is what `consult-project-function' passes; it
is ignored because this never prompts."
  (or
   ;; directory of the current perspective, while inside it
   (when-let* (((bound-and-true-p persp-mode))
               (dir (cdr (assoc (persp-current-name)
                                (bound-and-true-p my/persp-directories))))
               ((or (null buffer-file-name)
                    (file-in-directory-p default-directory dir))))
     dir)
   ;; the project around default-directory
   (my/project-root--detect default-directory)
   ;; current Perspective's project root
   (when (and (bound-and-true-p persp-mode)
              (fboundp 'persp-current-name)
              (fboundp 'projectile-relevant-known-projects))
     (let ((name (persp-current-name)))
       (when-let* ((proj (cl-find-if
                          (lambda (p)
                            (string= (funcall (or (bound-and-true-p projectile-project-name-function)
                                                  #'file-name-nondirectory)
                                              p)
                                     name))
                          (projectile-relevant-known-projects))))
         (file-name-as-directory (expand-file-name proj)))))
   default-directory))

(use-package consult
  :ensure t
  :config
  (setq consult-preview-key "M-."
        consult-async-min-input 2
        consult-buffer-filter
        '("\\` "
          "\\`\\*.*"
          "\\`magit-process:"
          "\\`newsrc-dribble"))

  (setq consult-fd-args
        '((if (executable-find "fdfind" 'remote) "fdfind" "fd")
          "--full-path --color=never --hidden --exclude .git"))

  (setq consult-ripgrep-args
        "rg --null --line-buffered --color=never --max-columns=1000 --path-separator / --smart-case --no-heading --with-filename --line-number --search-zip --hidden --glob !.git/")

  (setq consult-project-function #'my/project-root))

(defvar my/find-file-show-ignored nil
  "When non-nil, `my/project-find-file' includes gitignored files.")

(defvar my/find-file--restart nil
  "Non-nil when the prompt is restarting after a toggle.")

(defvar my/find-file--input ""
  "Minibuffer input preserved across a toggle restart.")

(defun my/find-file-toggle-ignored ()
  "Toggle showing ignored files and restart the prompt."
  (interactive)
  (setq my/find-file-show-ignored (not my/find-file-show-ignored)
        my/find-file--restart t
        my/find-file--input (minibuffer-contents))
  (abort-recursive-edit))

(defvar-keymap my/find-file-prompt-mode-map
  "C-h" #'my/find-file-toggle-ignored)

(define-minor-mode my/find-file-prompt-mode
  "Keys for the `my/project-find-file' prompt."
  :keymap my/find-file-prompt-mode-map
  (when (fboundp 'evil-normalize-keymaps)
    (evil-normalize-keymaps)))

(with-eval-after-load 'evil
  (evil-define-key '(normal insert) my/find-file-prompt-mode-map
    (kbd "C-h") #'my/find-file-toggle-ignored))

(defun my/project-find-file ()
  "Find a file in the project with orderless completion.
Pressing \\`C-h' toggles showing gitignored files."
  (interactive)
  (let ((root (my/project-root)))
    (catch 'my/find-file-done
      (while t
        (setq my/find-file--restart nil)
        (condition-case nil
            (let* ((default-directory root)
                   (git-p (= 0 (process-file "git" nil nil nil
                                             "rev-parse" "--is-inside-work-tree")))
                   (tracked
                    (split-string
                     (shell-command-to-string
                      (if git-p "git ls-files -z"
                        (format "fd --type f --color=never %s --exclude .git ."
                                (if my/find-file-show-ignored "--hidden --no-ignore" ""))))
                     (if git-p "\0" "\n") t))
                   (ignored
                    (when (and my/find-file-show-ignored git-p)
                      (split-string
                       (shell-command-to-string
                        "git ls-files -z --others --ignored --exclude-standard")
                       "\0" t)))
                   (ignored-set
                    (let ((ht (make-hash-table :test #'equal
                                               :size (max 1 (length ignored)))))
                      (dolist (f ignored) (puthash f t ht))
                      ht))
                   (candidates (append tracked (or ignored '())))
                   (file
                    (minibuffer-with-setup-hook
                        (lambda ()
                          (my/find-file-prompt-mode 1)
                          (when (and my/find-file--input
                                     (not (string-empty-p my/find-file--input)))
                            (insert my/find-file--input)))
                      (completing-read
                       (format "Find file%s [%s]: "
                               (if my/find-file-show-ignored " +ignored" "")
                               (abbreviate-file-name root))
                       (lambda (str pred action)
                         (if (eq action 'metadata)
                             `(metadata
                               (category . project-file)
                               (annotation-function
                                . ,(lambda (cand)
                                     (when (gethash cand ignored-set)
                                       (propertize " [ignored]" 'face 'shadow)))))
                           (complete-with-action action candidates str pred)))
                       nil t))))
              (setq my/find-file--input nil)
              (find-file (expand-file-name file root))
              (throw 'my/find-file-done nil))
          (quit
           (unless my/find-file--restart
             (setq my/find-file--input nil)
             (throw 'my/find-file-done nil))))))))

(defun my/open-file-anywhere (file)
  "Open FILE from anywhere, starting the prompt in the home directory.
The file opens in the current perspective, whatever project it is in."
  (interactive
   (list (read-file-name "Open file: " (expand-file-name "~/") nil t)))
  (find-file (expand-file-name file)))

(defun my/project-search-word ()
  "Search for text in the project root with `ripgrep', including hidden files."
  (interactive)
  (consult-ripgrep (my/project-root)))

(use-package embark
  :ensure t
  :defer t)

(use-package embark-consult
  :ensure t
  :after (embark consult))

;; Editable grep results
(define-advice grep-edit-save-changes (:after () my/save-files)
  "Save the files that the edits in this grep buffer went to."
  (let (buffers (saved 0))
    (save-excursion
      (goto-char (point-min))
      (let (match)
        (while (setq match (text-property-search-forward 'occur-target))
          (dolist (target (prop-match-value match))
            (when-let* ((buffer (marker-buffer (car target))))
              (cl-pushnew buffer buffers))))))
    (dolist (buffer buffers)
      (when (buffer-modified-p buffer)
        (with-current-buffer buffer (save-buffer))
        (setq saved (1+ saved))))
    (message "Saved %d file(s)" saved)))

;; In-Buffer Completion
;; (Company with overlay frontend)
(use-package company
  :ensure t
  :hook ((prog-mode conf-mode) . company-mode)
  :config
  (setq company-minimum-prefix-length 1
        company-idle-delay nil
        company-selection-wrap-around t
        company-tooltip-limit 10
        company-tooltip-align-annotations t
        company-require-match nil
        company-dabbrev-other-buffers nil
        company-frontends '(company-pseudo-tooltip-frontend)
        company-backends '((company-capf :with company-dabbrev)))

  ;; Clean overlay faces
  (set-face-attribute 'company-tooltip nil :inherit 'tooltip :background 'unspecified :foreground 'unspecified)
  (set-face-attribute 'company-tooltip-selection nil :inherit 'highlight :background 'unspecified :foreground 'unspecified :weight 'bold)
  (set-face-attribute 'company-tooltip-common nil :inherit 'font-lock-keyword-face :background 'unspecified :foreground 'unspecified)
  (set-face-attribute 'company-tooltip-annotation nil :inherit 'font-lock-comment-face :background 'unspecified :foreground 'unspecified))

(require 'completion-keys)

(provide 'completion-mod)
