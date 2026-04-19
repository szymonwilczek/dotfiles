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
        close_if_last_window = false,
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
        },
        window = {
          width = 35,
          mappings = {
            ['<space>'] = 'none',

            ---
            ['W'] = function()
              vim.ui.input({ prompt = 'Podaj nową szerokość panelu: ' }, function(input)
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
      require('mini.pairs').setup()

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end
    end,
  },

  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    ---@module 'todo-comments'
    ---@type TodoOptions
    ---@diagnostic disable-next-line: missing-fields
    opts = { signs = false },
  },

  { 'wakatime/vim-wakatime', lazy = false },
}
