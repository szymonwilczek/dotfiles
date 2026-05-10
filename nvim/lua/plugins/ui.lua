return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      picker = {
        enabled = true,
        layout = { preset = 'default' },
      },
      scroll = {
        animate = {
          duration = { step = 5, total = 80 },
          easing = 'linear',
        },
        animate_repeat = {
          delay = 50,
          duration = { step = 3, total = 30 },
        },
      },
      dashboard = {
        enabled = false,
      },
    },
    keys = {
      { '<leader>ff', function() Snacks.picker.files() end, desc = 'Znajdź pliki (Snacks)' },
      { '<leader>fw', function() Snacks.picker.grep() end, desc = 'Live Grep (Snacks)' },
      { '<leader>fr', function() Snacks.picker.recent() end, desc = 'Ostatnio używane pliki' },
      { '<leader>lg', function() Snacks.lazygit() end, desc = 'Lazygit (Snacks)' },
      { '<leader>of', function() Snacks.picker.files { cwd = '~/orgfiles' } end, desc = 'Org: Przeglądaj pliki' },
      { '<leader>os', function() Snacks.picker.grep { cwd = '~/orgfiles' } end, desc = 'Org: Szukaj w notatkach' },
    },
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
              -- text = nil,
              highlight = 'Directory',
              text_align = 'left',
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
      { '<leader>x', function() require('bufdelete').bufdelete(0, false) end, desc = 'Zamknij bufor (SPC X)' },
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
