return {
  'mikavilpas/yazi.nvim',
  event = 'VeryLazy',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  keys = {
    {
      '<leader>yy',
      '<cmd>Yazi<cr>',
      desc = 'Open Yazi at current file',
    },
    {
      '<leader>yw',
      '<cmd>Yazi cwd<cr>',
      desc = 'Open Yazi in working directory',
    },
  },
  opts = {
    open_for_directories = false,
  },
}
