return {
  {
    'oonamo/ef-themes.nvim',
    priority = 1000,
    lazy = false,
    config = function()
      local ef_themes = require 'ef-themes'
      local cache_path = vim.fn.stdpath 'data' .. '/last_theme.txt'

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
