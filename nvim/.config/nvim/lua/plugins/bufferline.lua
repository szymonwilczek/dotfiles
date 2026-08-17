return {
  {
    'akinsho/bufferline.nvim',
    version = '*',
    event = 'VeryLazy',
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = {
      options = {
        mode = 'buffers',
        separator_style = 'thin',
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    },
    keys = {
      { '<TAB>', '<cmd>BufferLineCycleNext<CR>', desc = 'Next buffer' },
      { '<S-TAB>', '<cmd>BufferLineCyclePrev<CR>', desc = 'Previous buffer' },
    },
  },
}
