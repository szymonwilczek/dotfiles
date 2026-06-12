-- General
vim.keymap.set('n', '<leader>dq', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', ';', ':', { desc = 'Command mode through ;' })

-- Navigation
vim.keymap.set('i', '<C-h>', '<Left>', { desc = 'Move left' })
vim.keymap.set('i', '<C-l>', '<Right>', { desc = 'Move right' })
vim.keymap.set('i', '<C-j>', '<Down>', { desc = 'Move down' })
vim.keymap.set('i', '<C-k>', '<Up>', { desc = 'Move up' })
vim.keymap.set('i', '<C-b>', '<C-o>b', { desc = 'Jump a word back' })
vim.keymap.set('n', '<A-x>', function() require('snacks').picker.commands() end, { desc = 'Snacks: [M]-x (Commands)' }) -- straight from emacs, love that

-- Move
vim.keymap.set('n', '<C-S-h>', '<C-w>H', { desc = 'Move window to the left' })
vim.keymap.set('n', '<C-S-l>', '<C-w>L', { desc = 'Move window to the right' })
vim.keymap.set('n', '<C-S-j>', '<C-w>J', { desc = 'Move window to the lower' })
vim.keymap.set('n', '<C-S-k>', '<C-w>K', { desc = 'Move window to the upper' })

-- Resize
-- local resize_amount = 2
-- ---- Normal Mode
-- vim.keymap.set('n', '<A-k>', (':resize +%d<CR>'):format(resize_amount), { silent = true, desc = 'Increase height' })
-- vim.keymap.set('n', '<A-j>', (':resize -%d<CR>'):format(resize_amount), { silent = true, desc = 'Decrease height' })
-- vim.keymap.set('n', '<A-h>', (':vertical resize -%d<CR>'):format(resize_amount), { silent = true, desc = 'Decrease width' })
-- vim.keymap.set('n', '<A-l>', (':vertical resize +%d<CR>'):format(resize_amount), { silent = true, desc = 'Increase width' })
-- ---- Insert Mode
-- vim.keymap.set('i', '<A-k>', ('<C-o>:resize +%d<CR>'):format(resize_amount), { silent = true })
-- vim.keymap.set('i', '<A-j>', ('<C-o>:resize -%d<CR>'):format(resize_amount), { silent = true })
-- vim.keymap.set('i', '<A-h>', ('<C-o>:vertical resize -%d<CR>'):format(resize_amount), { silent = true })
-- vim.keymap.set('i', '<A-l>', ('<C-o>:vertical resize +%d<CR>'):format(resize_amount), { silent = true })

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

-- toggle Cursor and Cursorline visibility
local original_guicursor = vim.o.guicursor
local original_cursorline = vim.o.cursorline
vim.keymap.set('n', '<leader>tc', function()
  if vim.o.guicursor == 'a:hor1-Ignore' then
    vim.o.guicursor = original_guicursor
    vim.o.cursorline = original_cursorline
  else
    original_guicursor = vim.o.guicursor
    original_cursorline = vim.o.cursorline
    vim.o.guicursor = 'a:hor1-Ignore'
    vim.o.cursorline = false
  end
end, { desc = '[T]oggle [C]ursor visibility' })

vim.keymap.set('n', '<TAB>', '<cmd>bnext<CR>', { desc = 'Następny bufor' })
vim.keymap.set('n', '<S-TAB>', '<cmd>bprev<CR>', { desc = 'Poprzedni bufor' })
