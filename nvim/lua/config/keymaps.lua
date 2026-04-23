vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
vim.keymap.set('i', '<A-h>', '<Left>', { desc = 'Move left' })
vim.keymap.set('i', '<A-l>', '<Right>', { desc = 'Move right' })
vim.keymap.set('i', '<A-j>', '<Down>', { desc = 'Move down' })
vim.keymap.set('i', '<A-k>', '<Up>', { desc = 'Move up' })
vim.keymap.set('i', '<A-b>', '<C-o>b', { desc = 'Jump a word back' })
vim.keymap.set('n', ';', ':', { desc = 'Command mode through ;' })
vim.keymap.set('n', '<A-x>', require('telescope.builtin').commands, { desc = 'Telescope: [M]-x (Commands)' }) -- straight from emacs, love that

-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.keymap.set('n', '<leader>tt', function()
  if vim.o.background == 'dark' then
    vim.o.background = 'light'
  else
    vim.o.background = 'dark'
  end
  print('Motyw: ' .. (vim.o.background == 'dark' and 'Ciemny 🍂' or 'Jasny ☀️'))
end, { desc = '[T]oggle [T]heme' })

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'gitcommit',
  callback = function()
    vim.keymap.set('n', '<leader>s', function()
      local name = vim.fn.systemlist('git config user.name')[1] or 'User'
      local email = vim.fn.systemlist('git config user.email')[1] or 'email@example.com'
      local signoff = string.format('Signed-off-by: %s <%s>', name, email)
      vim.api.nvim_buf_set_lines(0, -1, -1, false, { '', signoff })
    end, { buffer = true, desc = 'Git: Add Signed-off-by' })
  end,
})
