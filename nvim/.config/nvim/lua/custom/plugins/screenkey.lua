return {
  'NStefan002/screenkey.nvim',
  lazy = false,
  branch = 'main',
  cmd = 'Screenkey',
  keys = {
    { '<leader>sk', '<cmd>Screenkey toggle<cr>', desc = 'Toggle Screenkey' },
  },
  opts = {
    win_opts = {
      row = vim.o.lines - vim.o.cmdheight - 1,
      col = vim.o.columns - 1,
      relative = 'editor',
      anchor = 'SE',
      width = 40,
      height = 1,
      border = 'rounded',
      title = ' Screenkey ',
      title_pos = 'center',
    },
    hl_groups = {
      ['Normal'] = { link = 'Normal' },
      ['NormalFloat'] = { link = 'Normal' },
      ['FloatBorder'] = { link = 'WinSeparator' },
      ['FloatTitle'] = { link = 'Title' },
      ['screenkey.hl.key'] = { link = 'Directory' },
      ['screenkey.hl.map'] = { link = 'Constant' },
      ['screenkey.hl.sep'] = { link = 'Comment' },
    },
    compress_after = 3,
    clear_after = 3,
    show_leader = true,
  },
}
