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
  "Return the root directory of the current project or perspective."
  (or
   ;; Projectile if active and recognized
   (when (and (bound-and-true-p projectile-mode)
              (fboundp 'projectile-project-root))
     (projectile-project-root))
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
   ;; project.el
   (when-let* ((project (and (fboundp 'project-current)
                             (project-current nil))))
     (if (fboundp 'project-root)
         (project-root project)
       (car (project-roots project))))
   ;; dominating .git folder
   (when-let* ((git-dir (locate-dominating-file default-directory ".git")))
     (file-name-as-directory (expand-file-name git-dir)))
   ;; fallback to default-directory
   default-directory))

(use-package consult
  :ensure t
  :config
  (setq consult-preview-key '(:debounce 0.2 any)
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

(defun my/project-find-file ()
  "Search for files in the project root with `fd', including hidden files."
  (interactive)
  (consult-fd (my/project-root)))

(defun my/project-search-word ()
  "Search for text in the project root with `ripgrep', including hidden files."
  (interactive)
  (consult-ripgrep (my/project-root)))

;; In-Buffer Completion
;; (Company with overlay frontend)
(defcustom my-disabled-completion-modes
  '(text-mode
    markdown-mode
    gfm-mode
    rst-mode
    git-commit-mode
    fundamental-mode)
  "List of major modes where auto-completion popup is disabled."
  :type '(repeat symbol))

(use-package company
  :ensure t
  :hook ((prog-mode . (lambda ()
                        (unless (or (memq major-mode my-disabled-completion-modes)
                                    (derived-mode-p 'text-mode 'markdown-mode 'rst-mode))
                          (company-mode 1))))
         (conf-mode . company-mode))
  :config
  (setq company-minimum-prefix-length 2
        company-idle-delay 0.2
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
