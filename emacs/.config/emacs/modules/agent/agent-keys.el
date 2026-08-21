;;; Keybindings for AI Agents -*- lexical-binding: t; -*-

(with-eval-after-load 'evil-keys
  (when (fboundp 'my-leader-def)
    (my-leader-def
      "a"  '(:ignore t :which-key "AI Agents")
      "ag" '(my/agent-shell-gemini :which-key "Antigravity")
      "ac" '(my/agent-shell-claude :which-key "Claude Code")
      "ao" '(my/agent-shell-codex :which-key "OpenAI Codex")
      "at" '(my/agent-shell-toggle :which-key "Toggle Agent Split")
      "aa" '(my/agent-shell-select :which-key "Select Agent"))))

(provide 'agent-keys)
