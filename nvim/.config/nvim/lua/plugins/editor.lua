return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    lazy = false,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    keys = {
      { '<C-n>', '<cmd>Neotree toggle<cr>', desc = 'NeoTree toggle (Ctrl-n)' },
      { '<leader>ee', '<cmd>Neotree toggle<cr>', desc = 'NeoTree toggle (SPC e e)' },
    },
    config = function()
      require('neo-tree').setup {
        sources = {
          'filesystem',
          'buffers',
          'git_status',
          'document_symbols',
        },
        close_if_last_window = false,
        hide_root_node = true,
        retain_hidden_root_indent = true,
        filesystem = {
          follow_current_file = {
            enabled = true,
            use_libuv_file_watcher = true,
          },
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = false,
          },
          window = {
            mappings = {
              ['<tab>'] = function(state)
                local node = state.tree:get_node()
                if node.type == 'directory' then
                  state.commands['toggle_node'](state)
                elseif node.type == 'file' then
                  local nt_win = vim.api.nvim_get_current_win()
                  state.commands['open'](state)
                  vim.schedule(function()
                    if vim.api.nvim_win_is_valid(nt_win) then
                      vim.api.nvim_set_current_win(nt_win)
                      vim.cmd 'Neotree document_symbols'
                    end
                  end)
                end
              end,
            },
          },
          components = {
            icon = function(config, node, state)
              local common_components = require 'neo-tree.sources.common.components'
              local icon = common_components.icon(config, node, state)
              if node.type == 'directory' then
                local name = node.name:lower()
                if name == 'src' or name == 'source' then
                  icon.text = '󰚝'
                  icon.highlight = 'NeoTreeDirectoryIcon'
                elseif name == 'build' or name == 'bin' or name == 'dist' or name == 'target' then
                  icon.text = ''
                  icon.highlight = 'NeoTreeDirectoryIcon'
                elseif name == 'test' or name == 'tests' or name == 'spec' or name == 'specs' then
                  icon.text = '󰙅'
                  icon.highlight = 'NeoTreeDirectoryIcon'
                elseif name == '.git' then
                  icon.text = ''
                  icon.highlight = 'NeoTreeDirectoryIcon'
                elseif name == 'node_modules' then
                  icon.text = ''
                  icon.highlight = 'NeoTreeDirectoryIcon'
                elseif name == '.github' then
                  icon.text = ''
                  icon.highlight = 'NeoTreeDirectoryIcon'
                elseif name == 'config' or name == '.config' then
                  icon.text = ''
                  icon.highlight = 'NeoTreeDirectoryIcon'
                end
              end
              return icon
            end,
          },
        },
        document_symbols = {
          follow_cursor = true,
          window = {
            mappings = {
              ['<tab>'] = 'toggle_node',
              ['<S-Tab>'] = function() vim.cmd 'Neotree filesystem' end,
              ['<bs>'] = function() vim.cmd 'Neotree filesystem' end,
            },
          },
        },
        window = {
          width = 35,
          mappings = {
            ['<space>'] = 'none',
            ['z'] = 'none',
            ['<C-r>'] = 'none',

            ---
            ['W'] = function()
              vim.ui.input({ prompt = 'New panel width: ' }, function(input)
                if input and tonumber(input) then
                  vim.cmd('vertical resize ' .. input)
                else
                  if input then vim.notify('To nie jest liczba, mordo!', vim.log.levels.ERROR) end
                end
              end)
            end,
            ---
            ['>'] = function() vim.cmd 'vertical resize +5' end,
            ['<'] = function() vim.cmd 'vertical resize -5' end,
            ---
          },
        },
      }
    end,
  },

  { 'NMAC427/guess-indent.nvim', opts = {} },

  {
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.ai').setup {
        mappings = {
          around_next = 'aa',
          inside_next = 'ii',
        },
        n_lines = 500,
      }
      require('mini.surround').setup()
      -- require('mini.pairs').setup()

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'neo-tree',
        callback = function() vim.b.ministatusline_disable = true end,
      })
    end,
  },
  { 'wakatime/vim-wakatime', lazy = false },
}
