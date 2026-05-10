return {
  {
    'oonamo/ef-themes.nvim',
    priority = 1000,
    lazy = false,
    config = function()
      local ef_themes = require 'ef-themes'
      local cache_path = vim.fn.stdpath 'data' .. '/last_theme.txt'

      -- --- LOGIKA ZATHURY (GENEROWANIE KOLORÓW W LOCIE) ---
      local function update_zathura()
        -- Funkcja pomocnicza do wyciągania kolorów z Neovima (zabezpieczona przed nil)
        local function get_color(hl_group, attr, fallback)
          local hl = vim.api.nvim_get_hl(0, { name = hl_group, link = false })
          if hl and hl[attr] then return string.format('#%06x', hl[attr]) end
          return fallback
        end

        -- Wyciągamy kolory z aktualnie załadowanego motywu Neovima
        local bg = get_color('Normal', 'bg', '#1E1E1E')
        local fg = get_color('Normal', 'fg', '#D4D4D4')
        local status_bg = get_color('StatusLine', 'bg', '#333333')
        local status_fg = get_color('StatusLine', 'fg', '#FFFFFF')
        local error_bg = get_color('ErrorMsg', 'bg', '#FF0000')
        local search_bg = get_color('Search', 'bg', '#FFFF00')

        -- KONWERSJA NA RGBA (Kluczowe dla naprawy błędu nieczytelnego zaznaczenia!)
        local r = tonumber(search_bg:sub(2, 3), 16) or 255
        local g = tonumber(search_bg:sub(4, 5), 16) or 255
        local b = tonumber(search_bg:sub(6, 7), 16) or 0
        -- Ustawiamy 50% przezroczystości (0.5), żeby tekst przebijał spod zaznaczenia
        local highlight_rgba = string.format('rgba(%d,%d,%d,0.5)', r, g, b)

        -- Tworzymy payload konfiguracyjny
        local z_config = string.format(
          [[
set default-bg "%s"
set default-fg "%s"
set statusbar-bg "%s"
set statusbar-fg "%s"
set inputbar-bg "%s"
set inputbar-fg "%s"
set notification-bg "%s"
set notification-fg "%s"
set highlight-color "%s"
set highlight-active-color "%s"
set recolor-lightcolor "%s"
set recolor-darkcolor "%s"
]],
          bg,
          fg,
          status_bg,
          status_fg,
          status_bg,
          status_fg,
          error_bg,
          fg,
          highlight_rgba,
          highlight_rgba,
          bg,
          fg
        )

        -- Zapis do pliku
        local config_path = vim.fn.expand '~/.config/zathura/zathura-colorsrc'
        local f = io.open(config_path, 'w')
        if f then
          f:write(z_config)
          f:close()
        end
      end
      -- ----------------------------------------------------

      local function get_cached_theme()
        local f = io.open(cache_path, 'r')
        if f then
          local theme = f:read('*all'):gsub('%s+', '')
          f:close()
          return theme
        end
        return 'ef-autumn'
      end

      local function save_theme_to_cache(theme)
        local f = io.open(cache_path, 'w')
        if f then
          f:write(theme)
          f:close()
        end
      end

      local initial = get_cached_theme()
      ef_themes.setup {
        dark = initial,
        light = initial,
        transparent = false,
        styles = {
          comments = { italic = false },
          keywords = { bold = true },
        },
      }
      vim.cmd.colorscheme 'ef-theme'
      vim.schedule(update_zathura)

      _G.CustomThemePicker = function()
        local items = {}
        local theme_list = ef_themes.all_themes
          or {
            'ef-autumn',
            'ef-dark',
            'ef-day',
            'ef-night',
            'ef-spring',
            'ef-summer',
            'ef-winter',
            'ef-maris-dark',
            'ef-maris-light',
            'ef-elea-dark',
            'ef-elea-light',
            'ef-bio',
            'ef-cherie',
            'ef-cyprus',
            'ef-deuteranopia-dark',
            'ef-duo-dark',
            'ef-duo-light',
            'ef-eagle',
            'ef-frost',
            'ef-melissa-dark',
            'ef-melissa-light',
            'ef-trio-dark',
          }

        for _, name in ipairs(theme_list) do
          table.insert(items, { text = name, item = name })
        end

        require('snacks').picker.pick {
          source = 'themes',
          items = items,
          layout = { preset = 'vscode' },
          format = function(item) return { { item.text, 'SnacksPickerLabel' } } end,
          confirm = function(picker, item)
            picker:close()
            if item and item.text then
              ef_themes.setup { dark = item.text, light = item.text }
              vim.cmd.colorscheme 'ef-theme'
              save_theme_to_cache(item.text)
              vim.schedule(update_zathura)
            end
          end,
          preview = function(_, item)
            if item and item.text then
              pcall(function()
                ef_themes.setup { dark = item.text, light = item.text }
                vim.cmd.colorscheme 'ef-theme'
              end)
            end
          end,
          on_close = function()
            local cached = get_cached_theme()
            pcall(function()
              ef_themes.setup { dark = cached, light = cached }
              vim.cmd.colorscheme 'ef-theme'
            end)
          end,
        }
      end
    end,
    keys = {
      { '<leader>tt', '<cmd>lua CustomThemePicker()<cr>', desc = 'Theme Picker' },
    },
  },
}
