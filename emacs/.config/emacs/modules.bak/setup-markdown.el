(use-package markdown-mode
  :ensure t
  :mode ("\\.md\\'" . markdown-mode)
  :config
  (with-eval-after-load 'evil
    (evil-define-key 'normal markdown-mode-map (kbd "TAB") nil)
    (evil-define-key 'normal markdown-mode-map (kbd "<tab>") nil)
    (evil-define-key 'normal markdown-mode-map (kbd "<backtab>") nil)
    (evil-define-key 'normal markdown-mode-map (kbd "S-TAB") nil)

    (evil-define-key 'insert markdown-mode-map (kbd "TAB") #'markdown-cycle)
    (evil-define-key 'insert markdown-mode-map (kbd "<tab>") #'markdown-cycle)
    (evil-define-key 'insert markdown-mode-map (kbd "<backtab>") #'markdown-shifttab)
    (evil-define-key 'insert markdown-mode-map (kbd "S-TAB") #'markdown-shifttab)))

(use-package org
  :ensure nil
  :defer t
  :config
  (with-eval-after-load 'evil
    (evil-define-key 'normal org-mode-map (kbd "TAB") nil)
    (evil-define-key 'normal org-mode-map (kbd "<tab>") nil)
    (evil-define-key 'normal org-mode-map (kbd "<backtab>") nil)
    (evil-define-key 'normal org-mode-map (kbd "S-TAB") nil)

    (evil-define-key 'insert org-mode-map (kbd "TAB") #'org-cycle)
    (evil-define-key 'insert org-mode-map (kbd "<tab>") #'org-cycle)
    (evil-define-key 'insert org-mode-map (kbd "<backtab>") #'org-shifttab)
    (evil-define-key 'insert org-mode-map (kbd "S-TAB") #'org-shifttab)))

(provide 'setup-markdown)
