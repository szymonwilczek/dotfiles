-- General
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', ';', ':', { desc = 'Command mode through ;' })

-- Navigation
vim.keymap.set('i', '<C-h>', '<Left>', { desc = 'Move left' })
vim.keymap.set('i', '<C-l>', '<Right>', { desc = 'Move right' })
vim.keymap.set('i', '<C-j>', '<Down>', { desc = 'Move down' })
vim.keymap.set('i', '<C-k>', '<Up>', { desc = 'Move up' })
vim.keymap.set('i', '<C-b>', '<C-o>b', { desc = 'Jump a word back' })
vim.keymap.set('n', '<A-x>', require('telescope.builtin').commands, { desc = 'Telescope: [M]-x (Commands)' }) -- straight from emacs, love that

-- Move
vim.keymap.set('n', '<C-S-h>', '<C-w>H', { desc = 'Move window to the left' })
vim.keymap.set('n', '<C-S-l>', '<C-w>L', { desc = 'Move window to the right' })
vim.keymap.set('n', '<C-S-j>', '<C-w>J', { desc = 'Move window to the lower' })
vim.keymap.set('n', '<C-S-k>', '<C-w>K', { desc = 'Move window to the upper' })

-- Focus
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Resize
local resize_amount = 2
---- Normal Mode
vim.keymap.set('n', '<A-k>', (':resize +%d<CR>'):format(resize_amount), { silent = true, desc = 'Increase height' })
vim.keymap.set('n', '<A-j>', (':resize -%d<CR>'):format(resize_amount), { silent = true, desc = 'Decrease height' })
vim.keymap.set('n', '<A-h>', (':vertical resize -%d<CR>'):format(resize_amount), { silent = true, desc = 'Decrease width' })
vim.keymap.set('n', '<A-l>', (':vertical resize +%d<CR>'):format(resize_amount), { silent = true, desc = 'Increase width' })
---- Insert Mode
vim.keymap.set('i', '<A-k>', ('<C-o>:resize +%d<CR>'):format(resize_amount), { silent = true })
vim.keymap.set('i', '<A-j>', ('<C-o>:resize -%d<CR>'):format(resize_amount), { silent = true })
vim.keymap.set('i', '<A-h>', ('<C-o>:vertical resize -%d<CR>'):format(resize_amount), { silent = true })
vim.keymap.set('i', '<A-l>', ('<C-o>:vertical resize +%d<CR>'):format(resize_amount), { silent = true })

-- Split
vim.keymap.set('n', '<leader>s', '<cmd>vsplit<cr>', { desc = '[S]plit Vertical' })
vim.keymap.set('n', '<leader>h', '<cmd>vsplit<cr>', { desc = 'Split Vertical (backup)' })
vim.keymap.set('n', '<leader>v', '<cmd>split<cr>', { desc = 'Split Horizontal' })

-- Yank
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- Theme
vim.keymap.set('n', '<leader>tt', function()
  if vim.o.background == 'dark' then
    vim.o.background = 'light'
  else
    vim.o.background = 'dark'
  end
  print('Motyw: ' .. (vim.o.background == 'dark' and 'Ciemny 🍂' or 'Jasny ☀️'))
end, { desc = '[T]oggle [T]heme' })

-- Relative Line Numbers
vim.keymap.set('n', '<leader>r', function() vim.wo.relativenumber = not vim.wo.relativenumber end, { desc = '[R]elative line numbers toggle' })

-- vim.api.nvim_create_autocmd('FileType', {
--   pattern = 'gitcommit',
--   callback = function()
--     vim.keymap.set('n', '<leader>f', function()
--       local name = vim.fn.systemlist('git config user.name')[1] or 'User'
--       local email = vim.fn.systemlist('git config user.email')[1] or 'email@example.com'
--       local signoff = string.format('Signed-off-by: %s <%s>', name, email)
--       vim.api.nvim_buf_set_lines(0, -1, -1, false, { '', signoff })
--     end, { buffer = true, desc = 'Git: Add Signed-off-by' })
--   end,
-- })
