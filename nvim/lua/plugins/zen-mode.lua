return {
  'folke/zen-mode.nvim',
  cmd = 'ZenMode',
  keys = {
    { '<leader>z', function() require('zen-mode').toggle() end, desc = 'Toggle Zen Mode' },
  },
  opts = {
    window = {
      backdrop = 0.95,
      -- width = 100,
      options = {
        signcolumn = 'no',
        number = true,
        relativenumber = false,
        cursorline = true,
        foldcolumn = '0',
      },
    },
    plugins = {
      options = {
        enabled = true,
        ruler = false,
        showcmd = false,
      },
      gitsigns = { enabled = true },
      tmux = { enabled = true },
    },
  },
}
