return {
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
}
