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
          files = {
            hidden = true,
            ignored = true,
          },
          grep = {
            need_search = true,
            hidden = true,
            ignored = true,
          },
        },
      },
      scroll = {
        enabled = false,
      },
      dashboard = {
        enabled = false,
      },
      lazygit = {
        configure = true,
        config = {
          os = {
            edit = '[ -z "$NVIM" ] && (nvim -- {{filename}}) || (nvim --server "$NVIM" --remote-send "q" && nvim --server "$NVIM" --remote {{filename}})',
            editAtLine = '[ -z "$NVIM" ] && (nvim +{{line}} -- {{filename}}) || (nvim --server "$NVIM" --remote-send "q" && nvim --server "$NVIM" --remote {{filename}} && nvim --server "$NVIM" --remote-send ":{{line}}<CR>")',
          },
        },
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
    'famiu/bufdelete.nvim',
    keys = {
      { '<C-x>', function() require('bufdelete').bufdelete(0, false) end, desc = 'Zamknij bufor (Ctrl+X)' },
      { '<leader>q', function() require('bufdelete').bufdelete(0, false) end, desc = 'Zamknij bufor (SPC q)' },
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
