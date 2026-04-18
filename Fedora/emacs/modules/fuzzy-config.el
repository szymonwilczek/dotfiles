(use-package fzf
  :ensure t
  :config

  ;;   Start  -> INSERT (j/k/q/i as normal letters)
  ;;   ESC    -> NORMAL (j/k for navigate, q closes, i goes back to INSERT)

  (defvar my/fzf-vim-binds
    (concat
     "--bind 'j:down,k:up,q:abort' "
     "--bind 'i:unbind(j,k,q,i)+enable-search+change-prompt(SEARCH> )' "
     "--bind 'start:unbind(j,k,q,i)' "
     "--bind 'esc:rebind(j,k,q,i)+disable-search+change-prompt(NORMAL> )' "
     "--bind 'ctrl-j:down,ctrl-k:up' "))

  ;; FIND FILE --- SPC f f
  (setq fzf/args
        (concat
         "-x --print-query --no-hscroll "
         "--color=light "
         "--preview-window=right:60% "
         "--preview 'bat --theme=GitHub --color=always --style=numbers "
         "--line-range=:300 {} 2>/dev/null' "
         my/fzf-vim-binds))

  (setq fzf/position-bottom t
        fzf/window-height 25)

  ;; LIVE GREP --- SPC f w
  (defun my/fzf-live-grep ()
    "live_grep"
    (interactive)
    (let* ((dir (or (locate-dominating-file default-directory ".git")
                    default-directory))
           (grep-args
            (concat
             "-x --print-query --no-hscroll "
             "--color=light "
             "--delimiter : "
             "--disabled "
             "--preview-window=right:60% "
             "--preview 'test -f {1} && bat --theme=GitHub --color=always --style=numbers "
             "--highlight-line {2} --line-range {2}: {1} 2>/dev/null "
             "|| echo \"Search...\"' "
             "--bind 'change:reload:rg --no-heading --color=never --line-number "
             "{q} || true' "
             "--prompt 'Live Grep> ' "
             my/fzf-vim-binds))
           (fzf--target-validator #'fzf--pass-through)
           (fzf--extractor-list (list fzf--file-lnum-regexp 1 2))
           (process-environment (cons "FZF_DEFAULT_COMMAND=true" process-environment)))
      (fzf--start dir
                  #'fzf--action-find-file-with-line
                  grep-args))))

(provide 'fuzzy-config)
