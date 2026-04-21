(defun my/markdown-mermaid-browser-preview ()
  (interactive)
  (save-excursion
    (if (not (re-search-backward "^```mermaid" nil t))
      (message "Not in the mermaid scope!")
      (forward-line 1)
      (let* ((start (point))
              (_ (re-search-forward "^```" nil t))
              (end (match-beginning 0))
              (code (buffer-substring-no-properties start end))
              (html-file (expand-file-name "mermaid-preview.html" temporary-file-directory))
              (html-content (concat
                              "<!DOCTYPE html>\n<html lang=\"pl\">\n<head>\n"
                              "<meta charset=\"UTF-8\">\n"
                              "<title>Mermaid Full Canvas</title>\n"
                              "<style>\n"
                              "  body, html { margin: 0; padding: 0; width: 100%; height: 100%; background-color: #0d1117; overflow: hidden; }\n"
                              "  #diagram-container { position: absolute; top: 0; left: 0; width: 100vw; height: 100vh; }\n"
                              "  svg text, svg foreignObject, svg tspan { user-select: text !important; cursor: text !important; }\n"
                              "  #reset-btn { position: fixed; bottom: 20px; right: 20px; background: #21262d; color: #c9d1d9; border: 1px solid #30363d; border-radius: 6px; padding: 8px 16px; cursor: pointer; z-index: 1000; font-family: sans-serif; }\n"
                              "  #reset-btn:hover { background: #30363d; }\n"
                              "</style>\n"
                              "<script src=\"https://cdn.jsdelivr.net/npm/svg-pan-zoom@3.6.1/dist/svg-pan-zoom.min.js\"></script>\n"
                              "</head>\n<body>\n"
                              "<pre id=\"source\" style=\"display:none;\">\n"
                              code
                              "\n</pre>\n"
                              "<button id=\"reset-btn\">Reset</button>\n"
                              "<div id=\"diagram-container\"></div>\n"
                              "<script type=\"module\">\n"
                              "  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';\n"
                              "  mermaid.initialize({ startOnLoad: false, theme: 'dark' });\n"
                              "  \n"
                              "  async function draw() {\n"
                              "    const sourceCode = document.getElementById('source').textContent;\n"
                              "    const container = document.getElementById('diagram-container');\n"
                              "    \n"
                              "    const { svg } = await mermaid.render('generated-svg', sourceCode);\n"
                              "    container.innerHTML = svg;\n"
                              "    \n"
                              "    const svgEl = container.querySelector('svg');\n"
                              "    svgEl.setAttribute('width', '100%');\n"
                              "    svgEl.setAttribute('height', '100%');\n"
                              "    svgEl.style.maxWidth = 'none';\n"
                              "    \n"
                              "    const panZoom = svgPanZoom(svgEl, {\n"
                              "      zoomEnabled: true,\n"
                              "      controlIconsEnabled: false,\n"
                              "      fit: true,\n"
                              "      center: true,\n"
                              "      minZoom: 0.05,\n"
                              "      maxZoom: 50\n"
                              "    });\n"
                              "    \n"
                              "    document.getElementById('reset-btn').addEventListener('click', () => {\n"
                              "      panZoom.reset();\n"
                              "      panZoom.fit();\n"
                              "      panZoom.center();\n"
                              "    });\n"
                              "    \n"
                              "    svgEl.querySelectorAll('text, tspan, foreignObject').forEach(el => {\n"
                              "      el.addEventListener('mousedown', e => e.stopPropagation());\n"
                              "    });\n"
                              "  }\n"
                              "  draw();\n"
                              "</script>\n"
                              "</body>\n</html>")))

        (with-temp-file html-file (insert html-content))
        (browse-url (concat "file://" html-file))
        (message "Opened preview.")))))

(with-eval-after-load 'general
  (with-eval-after-load 'markdown-mode
    (my-leader-def
      :keymaps 'markdown-mode-map
      "m" '(:ignore t :which-key "Markdown")
      "mm" '(my/markdown-mermaid-browser-preview :which-key "Mermaid Preview"))))

(provide 'setup-mermaid)
