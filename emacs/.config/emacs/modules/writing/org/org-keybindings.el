;;; Custom keybindings for Org-mode under SPC o -*- lexical-binding: t; -*-

(defun my/setup-org-keys ()
  "Define Org mode keybindings under SPC o."
  (when (fboundp 'general-define-key)
    (general-define-key
     :states '(normal visual motion)
     :keymaps 'org-mode-map
     :prefix "SPC"
     "o"   '(:ignore t :which-key "Org Mode")
     "oa"  '(my/org-export-and-view-pdf :which-key "Export Article PDF in Split")
     "ob"  '(:ignore t :which-key "Beamer Slides...")
     "obb" '(my/org-beamer-export-and-view-pdf :which-key "Export Slides in Split")
     "obf" '(my/presentation-toggle-fullscreen :which-key "Toggle Fullscreen Presentation")
     "op"  '(my/org-toggle-latex-preview :which-key "Toggle Math Preview")
     "oe"  '(org-export-dispatch :which-key "Export Dispatcher")
     "ot"  '(org-todo :which-key "Toggle TODO State")
     "od"  '(org-deadline :which-key "Set Deadline")
     "os"  '(org-schedule :which-key "Set Schedule")
     "ol"  '(org-open-at-point :which-key "Open Link at Point")
     "oi"  '(:ignore t :which-key "Insert...")
     "oit" '(org-table-create-or-convert-from-region :which-key "Table")
     "ois" '(org-insert-structure-template :which-key "Source / Block (#+begin_src)")
     "oil" '(org-insert-link :which-key "Link"))))

(with-eval-after-load 'org (my/setup-org-keys))
(add-hook 'org-mode-hook #'my/setup-org-keys)

(provide 'org-keybindings)
