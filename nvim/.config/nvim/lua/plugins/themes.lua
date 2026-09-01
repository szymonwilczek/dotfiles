return {
  {
    -- 'szymonwilczek/arete.nvim',
    'arete.nvim',
    dir = vim.fn.expand '~/Dokumenty/GitHub/arete.nvim',
    name = 'arete',
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
        local themes = discover_themes()
        local original = vim.g.colors_name or read_cached_theme()
        require('fzf-lua').fzf_exec(themes, {
          prompt = 'Arete Themes> ',
          actions = {
            ['default'] = function(selected)
              if selected and selected[1] then
                vim.cmd.colorscheme(selected[1])
                save_theme_to_cache(selected[1])
              end
            end,
          },
          winopts = { height = 0.4, width = 0.5, row = 0.3 },
        })
      end

      vim.api.nvim_create_user_command('AretePick', CustomThemePicker, { desc = 'Pick an arete theme' })
      vim.api.nvim_create_user_command('AreteReload', function()
        local current = vim.g.colors_name or read_cached_theme()
        vim.fn.delete(vim.fn.stdpath 'cache' .. '/arete', 'rf')
        for name in pairs(package.loaded) do
          if name == 'arete' or name:match '^arete%.' then package.loaded[name] = nil end
        end
        if vim.loader then vim.loader.reset() end
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
