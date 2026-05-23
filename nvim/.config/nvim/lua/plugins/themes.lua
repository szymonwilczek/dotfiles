return {
  {
    'szymonwilczek/arete.nvim',
    -- 'arete.nvim',
    -- dir = vim.fn.expand '~/Dokumenty/GitHub/arete.nvim',
    -- name = 'arete',
    lazy = false,
    priority = 1000,
    config = function()
      local arete = require 'arete'
      local cache_path = vim.fn.stdpath 'data' .. '/arete_last_theme.txt'
      local default_theme = 'ef-bio'

      local function read_cached_theme()
        local f = io.open(cache_path, 'r')
        if not f then return default_theme end
        local theme = f:read('*all'):gsub('%s+', '')
        f:close()
        return theme ~= '' and theme or default_theme
      end

      local function save_theme_to_cache(theme)
        local f = io.open(cache_path, 'w')
        if not f then return end
        f:write(theme)
        f:close()
      end

      local function discover_themes()
        local names = {}
        local init = vim.api.nvim_get_runtime_file('lua/arete/init.lua', false)[1]
        if not init then return names end

        local root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(init)))
        local pattern = root .. '/colors/*.lua'
        for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
          local name = vim.fn.fnamemodify(path, ':t:r')
          if name ~= 'arete-fixture' and name ~= 'ef-theme' then table.insert(names, name) end
        end
        table.sort(names)
        return names
      end

      arete.setup {
        transparent = false,
        styles = {
          comments = { italic = true },
          keywords = { bold = true },
          types = { bold = true },
        },
      }

      local cached = read_cached_theme()
      vim.cmd.colorscheme(cached)

      vim.api.nvim_create_autocmd('VimEnter', {
        once = true,
        callback = function() vim.api.nvim_exec_autocmds('ColorScheme', { modeline = false }) end,
      })

      _G.CustomThemePicker = function()
        local items = {}
        for _, name in ipairs(discover_themes()) do
          table.insert(items, { text = name, item = name })
        end

        local original = vim.g.colors_name or read_cached_theme()
        local confirmed = false

        require('snacks').picker.pick {
          source = 'themes',
          items = items,
          layout = { preset = 'vscode' },
          format = function(item) return { { item.text, 'SnacksPickerLabel' } } end,
          confirm = function(picker, item)
            picker:close()
            if item and item.text then
              confirmed = true
              vim.cmd.colorscheme(item.text)
              save_theme_to_cache(item.text)
            end
          end,
          preview = function(_, item)
            if item and item.text then pcall(vim.cmd.colorscheme, item.text) end
          end,
          on_close = function()
            if confirmed then return end
            pcall(vim.cmd.colorscheme, original)
          end,
        }
      end

      vim.api.nvim_create_user_command('AretePick', CustomThemePicker, { desc = 'Pick an arete theme' })
      vim.api.nvim_create_user_command('AreteReload', function()
        local current = vim.g.colors_name or read_cached_theme()
        vim.fn.delete(vim.fn.stdpath 'cache' .. '/arete', 'rf')
        vim.cmd.colorscheme(current)
      end, { desc = 'Drop arete cache and reload the current theme' })

      vim.api.nvim_create_user_command('AreteVerify', function()
        local failed = {}
        local total = 0
        for _, name in ipairs(discover_themes()) do
          total = total + 1
          local ok, err = pcall(function() require('arete').load(name, { cache = false, clear = false, force = true }) end)
          if not ok then table.insert(failed, name .. ': ' .. tostring(err)) end
        end
        if #failed == 0 then
          vim.notify('arete: all ' .. total .. ' themes load cleanly', vim.log.levels.INFO)
        else
          vim.notify('arete: ' .. #failed .. ' themes failed:\n' .. table.concat(failed, '\n'), vim.log.levels.ERROR)
        end
      end, { desc = 'Load every arete theme once and report failures' })
    end,
    keys = {
      { '<leader>tt', '<cmd>lua CustomThemePicker()<cr>', desc = 'Theme Picker' },
    },
  },
}
