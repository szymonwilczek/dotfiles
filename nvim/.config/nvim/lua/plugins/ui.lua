return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      picker = {
        enabled = true,
        layout = {
          preset = 'ivy',
        },
        layouts = {
          ivy = {
            layout = {
              box = 'vertical',
              backdrop = false,
              row = -1,
              width = 0,
              height = 0.3,
              border = 'top',
              title = ' {title} {live} {flags}',
              title_pos = 'left',
              { win = 'input', height = 1, border = 'bottom' },
              {
                box = 'horizontal',
                { win = 'list', border = 'none' },
                { win = 'preview', title = '{preview}', width = 0.6, border = 'left' },
              },
            },
          },
        },
        preview = false,
        limit_live = 100,
        limit = 1000,
        matcher = {
          cwd_bonus = false,
          frecency = false,
          history_bonus = false,
        },
        sources = {
          grep = {
            need_search = true,
          },
        },
      },
      scroll = {
        enabled = false,
      },
      dashboard = {
        enabled = false,
      },
    },
    keys = {
      { '<leader>ff', function() Snacks.picker.files() end, desc = 'Find (F)iles' },
      { '<leader>fw', function() Snacks.picker.grep() end, desc = 'Find (W)ord' },
      { '<leader>fr', function() Snacks.picker.recent() end, desc = 'Find (R)ecent' },
      { '<leader>lg', function() Snacks.lazygit() end, desc = 'Lazygit' },
    },
    config = function(_, opts) require('snacks').setup(opts) end,
  },

  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require('bufferline').setup {
        options = {
          mode = 'buffers',
          separator_style = 'thin',
          show_buffer_close_icons = false,
          show_close_icon = false,
          offsets = {
            {
              filetype = 'neo-tree',
              text = function() return '  ' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t') end,
              highlight = 'Directory',
              text_align = 'center',
              separator = true,
            },
          },
        },
      }

      vim.keymap.set('n', '<TAB>', ':BufferLineCycleNext<CR>', { desc = 'Następna zakładka' })
      vim.keymap.set('n', '<S-TAB>', ':BufferLineCyclePrev<CR>', { desc = 'Poprzednia zakładka' })
    end,
  },

  {
    'famiu/bufdelete.nvim',
    keys = {
      { '<C-x>', function() require('bufdelete').bufdelete(0, false) end, desc = 'Zamknij bufor (Ctrl+X)' },
      { '<leader>q', function() require('bufdelete').bufdelete(0, false) end, desc = 'Zamknij bufor (SPC X)' },
    },
  },

  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    ---@module 'which-key'
    ---@type wk.Opts
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      delay = 400,
      icons = { mappings = vim.g.have_nerd_font },

      spec = {
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
        { 'gr', group = 'LSP Actions', mode = { 'n' } },
      },
    },
  },
  {
    's1n7ax/nvim-window-picker',
    name = 'window-picker',
    event = 'VeryLazy',
    version = '2.*',
    config = function()
      require('window-picker').setup {
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          bo = {
            filetype = { 'neo-tree', 'neo-tree-popup', 'notify', 'snacks_picker_input' },
            buftype = { 'terminal', 'quickfix' },
          },
        },
        hint = 'floating-big-letter',
        picker_config = {
          floating_big_letter = {
            font = 'ansi-shadow',
          },
        },
        show_prompt = false,
      }
    end,
  },
}
