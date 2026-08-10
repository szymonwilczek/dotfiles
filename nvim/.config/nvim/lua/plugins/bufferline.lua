return {
  {
    'akinsho/bufferline.nvim',
    version = '*',
    event = 'VeryLazy',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      local function sync_offset_highlights()
        local dir_fg = vim.api.nvim_get_hl(0, { name = 'NeoTreeDirectoryIcon', link = false }).fg
        local neotree_bg = vim.api.nvim_get_hl(0, { name = 'NeoTreeNormal', link = false }).bg or vim.api.nvim_get_hl(0, { name = 'Normal', link = false }).bg
        local sep_fg = vim.api.nvim_get_hl(0, { name = 'WinSeparator', link = false }).fg
        vim.api.nvim_set_hl(0, 'NeoTreeOffsetTitle', { fg = dir_fg, bg = neotree_bg })
        vim.api.nvim_set_hl(0, 'BufferLineOffsetSeparator', { fg = sep_fg, bg = neotree_bg })
      end

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
              highlight = 'NeoTreeOffsetTitle',
              text_align = 'center',
              separator = '| ',
            },
          },
        },
      }
      sync_offset_highlights()
      vim.api.nvim_create_autocmd({ 'ColorScheme', 'VimEnter' }, { callback = sync_offset_highlights })
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'neo-tree',
        callback = function() vim.schedule(sync_offset_highlights) end,
      })

      vim.keymap.set('n', '<TAB>', ':BufferLineCycleNext<CR>', { desc = 'Następna zakładka' })
      vim.keymap.set('n', '<S-TAB>', ':BufferLineCyclePrev<CR>', { desc = 'Poprzednia zakładka' })
    end,
  },
}
