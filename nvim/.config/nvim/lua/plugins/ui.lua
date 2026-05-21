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
    config = function(_, opts)
      require('snacks').setup(opts)

      local function apply_picker_hl()
        local palette = nil
        local ok, ef_themes = pcall(require, 'ef-themes')
        if ok and vim.g.colors_name == 'ef-theme' then
          local cache_path = vim.fn.stdpath 'data' .. '/last_theme.txt'
          local f = io.open(cache_path, 'r')
          local theme_name = 'ef-autumn'
          if f then
            theme_name = f:read('*all'):gsub('%s+', '')
            f:close()
          end
          palette = ef_themes.get_palette(theme_name)
        end

        local function get_hl_color(group, attr)
          local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
          local val = hl[attr]
          if val then return string.format('#%06x', val) end
          return nil
        end

        local bg = 'none'
        local border_fg = (palette and (palette.cyan_cooler or palette.cyan)) or get_hl_color('FloatBorder', 'fg') or '#316c71'
        local accent = (palette and palette.cyan) or get_hl_color('Identifier', 'fg') or '#316c71'
        local match = (palette and (palette.accent_1 or palette.yellow)) or get_hl_color('Special', 'fg') or '#c48702'
        local selected_bg = (palette and (palette.bg_active or palette.bg_hover)) or get_hl_color('Visual', 'bg') or '#56524f'
        local fg_dim = (palette and palette.fg_dim) or get_hl_color('Comment', 'fg') or '#887c8a'

        vim.api.nvim_set_hl(0, 'SnacksPicker', { bg = bg, nocombine = true })
        vim.api.nvim_set_hl(0, 'SnacksPickerBorder', { fg = border_fg, bg = bg, nocombine = true })
        vim.api.nvim_set_hl(0, 'SnacksPickerTitle', { fg = accent, bold = true, bg = bg })

        vim.api.nvim_set_hl(0, 'SnacksPickerInput', { bg = bg, nocombine = true })
        vim.api.nvim_set_hl(0, 'SnacksPickerInputBorder', { fg = border_fg, bg = bg, nocombine = true })
        vim.api.nvim_set_hl(0, 'SnacksPickerInputTitle', { fg = accent, bold = true, bg = bg })

        vim.api.nvim_set_hl(0, 'SnacksPickerList', { bg = bg, nocombine = true })
        vim.api.nvim_set_hl(0, 'SnacksPickerListBorder', { fg = border_fg, bg = bg, nocombine = true })

        vim.api.nvim_set_hl(0, 'SnacksPickerPreview', { bg = bg, nocombine = true })
        vim.api.nvim_set_hl(0, 'SnacksPickerPreviewBorder', { fg = border_fg, bg = bg, nocombine = true })
        vim.api.nvim_set_hl(0, 'SnacksPickerPreviewTitle', { fg = accent, bold = true, bg = bg })

        vim.api.nvim_set_hl(0, 'SnacksPickerMatch', { fg = match, bold = true })
        vim.api.nvim_set_hl(0, 'SnacksPickerSelected', { bg = selected_bg })
        vim.api.nvim_set_hl(0, 'SnacksPickerSearch', { fg = match, bold = true })
        vim.api.nvim_set_hl(0, 'SnacksPickerLabel', { fg = accent })
        vim.api.nvim_set_hl(0, 'SnacksPickerDelim', { fg = fg_dim })
      end

      apply_picker_hl()

      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = '*',
        callback = apply_picker_hl,
      })
    end,
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
