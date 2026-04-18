(require 'cl-lib)
(global-tab-line-mode t)

(setq tab-line-close-button-show nil
      tab-line-new-button-show nil)

(setq tab-line-separator "")

(defun my/tab-line-render-with-icons (buffer &optional _buffers)
  "Renderuje zakładkę z równym paddingiem i chroni kolor ikony."
  (let* ((name (buffer-name buffer))
         (icon (nerd-icons-icon-for-buffer buffer)))
    (if icon
        (concat " " icon " " name " ")
      (concat " " name " "))))

(setq tab-line-tab-name-function #'my/tab-line-render-with-icons)

(setq tab-line-exclude-modes '(treemacs-mode lisp-interaction-mode messages-buffer-mode help-mode fundamental-mode))

(setq tab-line-tabs-function
      (lambda ()
        (let ((bufs (cl-remove-if (lambda (b) (string-match-p "^\\*" (buffer-name b)))
                                  (buffer-list))))
          (cl-sort bufs #'string< :key #'buffer-name))))

(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "TAB") 'tab-line-switch-to-next-tab)
  (define-key evil-normal-state-map (kbd "<backtab>") 'tab-line-switch-to-prev-tab))

(defun my/fix-tab-line-faces (&rest args)
  "removes 3d frames"
  (set-face-attribute 'tab-line nil :box nil)
  (set-face-attribute 'tab-line-tab nil :box nil)
  (set-face-attribute 'tab-line-tab-inactive nil :box nil)
  (set-face-attribute 'tab-line-tab-current nil :box nil :weight 'bold))

;; run this every time scripts loads a module
(advice-add 'load-theme :after #'my/fix-tab-line-faces)

;; one for the start as well
(my/fix-tab-line-faces)

(define-key evil-normal-state-map (kbd "SPC x") 'kill-current-buffer)
(define-key evil-window-map (kbd "x") 'kill-current-buffer)

(with-eval-after-load 'tab-line
  (set-face-attribute 'tab-line nil :box nil)
  (set-face-attribute 'tab-line-tab nil :box nil)
  (set-face-attribute 'tab-line-tab-inactive nil :box nil)
  (set-face-attribute 'tab-line-tab-current nil :box nil :weight 'bold))


;; hides * buffers 
(add-to-list 'tab-line-exclude-modes 'lisp-interaction-mode) ; *scratch*
(add-to-list 'tab-line-exclude-modes 'messages-buffer-mode)  ; *Messages*
(add-to-list 'tab-line-exclude-modes 'help-mode)             ; Help Mode 
(add-to-list 'tab-line-exclude-modes 'fundamental-mode)      ; Default Empty

(setq tab-line-tabs-function
      (lambda ()
        (cl-remove-if (lambda (b) (string-match-p "^\\*" (buffer-name b)))
                      (tab-line-tabs-window-buffers))))

(provide 'tabs-config)
