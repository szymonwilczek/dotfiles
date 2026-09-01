;;; TRAMP Evil keybindings and interactive helpers -*- lexical-binding: t; -*-

(defun my/tramp-get-ssh-hosts ()
  "Parse SSH config file to extract list of configured hostnames."
  (let ((config-file (expand-file-name "~/.ssh/config"))
        hosts)
    (when (file-readable-p config-file)
      (with-temp-buffer
        (insert-file-contents config-file)
        (goto-char (point-min))
        (while (re-search-forward "^[ \t]*Host[ \t]+\\(.+\\)$" nil t)
          (let ((host-line (match-string 1)))
            (dolist (h (split-string host-line "[ \t]+" t))
              (unless (string-match-p "[*?]" h)
                (push h hosts)))))))
    (nreverse (delete-dups hosts))))

(defun my/tramp-open-ssh ()
  "Interactively pick an SSH host from ~/.ssh/config and open its remote directory."
  (interactive)
  (let* ((hosts (my/tramp-get-ssh-hosts))
         (host (if hosts
                   (completing-read "Connect to SSH Host: " hosts nil nil)
                 (read-string "Connect to SSH Host (user@host): ")))
         (remote-path (format "/ssh:%s:~/" host)))
    (find-file remote-path)))

(defun my/tramp-sudo-this-file ()
  "Reopen the current buffer or Dired directory with root/sudo privileges."
  (interactive)
  (let ((path (or (buffer-file-name) default-directory)))
    (if (not path)
        (user-error "Current buffer is not visiting a file or directory")
      (let ((sudo-path (if (file-remote-p path)
                           (let ((vec (tramp-dissect-file-name path)))
                             (tramp-make-tramp-file-name
                              "sudo"
                              "root"
                              nil
                              (tramp-file-name-host vec)
                              nil
                              (tramp-file-name-localname vec)))
                         (concat "/sudo:root@localhost:" path))))
        (find-file sudo-path)))))

(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "r"  '(:ignore t :which-key "Remote/TRAMP")
      "rs" '(my/tramp-open-ssh :which-key "SSH Host (Dired)")
      "ru" '(my/tramp-sudo-this-file :which-key "Sudo Edit File"))))

(provide 'tramp-keys)
