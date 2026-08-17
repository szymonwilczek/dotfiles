-- General & Diagnostics
vim.keymap.set('n', '<C-w>d', vim.diagnostic.open_float, { desc = 'Show diagnostics under cursor' })
vim.keymap.set('n', ']d', function() vim.diagnostic.jump { count = 1, float = true } end, { desc = 'Next diagnostic' })
vim.keymap.set('n', '[d', function() vim.diagnostic.jump { count = -1, float = true } end, { desc = 'Prev diagnostic' })
vim.keymap.set('n', '<leader>dq', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', ';', ':', { desc = 'Command mode through ;' })

-- Close buffer without closing window/split
vim.keymap.set('n', '<leader>q', function()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].modified then
    vim.notify('Bufor zawiera niezapisane zmiany!', vim.log.levels.WARN)
    return
  end
  vim.cmd 'bprevious'
  vim.api.nvim_buf_delete(bufnr, { force = false })
end, { desc = 'Zamknij bufor (SPC q)' })

-- Navigation
vim.keymap.set('i', '<C-h>', '<Left>', { desc = 'Move left' })
vim.keymap.set('i', '<C-l>', '<Right>', { desc = 'Move right' })
vim.keymap.set('i', '<C-j>', '<Down>', { desc = 'Move down' })
vim.keymap.set('i', '<C-k>', '<Up>', { desc = 'Move up' })
vim.keymap.set('i', '<C-b>', '<C-o>b', { desc = 'Jump a word back' })
vim.keymap.set('n', '<A-x>', function() require('fzf-lua').commands() end, { desc = '[M]-x (Commands)' }) -- straight from emacs, love that

-- Completion & Snippet navigation
vim.keymap.set('i', '<A-j>', function()
  if vim.fn.pumvisible() == 1 then return '<C-n>' end
  return '<A-j>'
end, { expr = true, silent = true, desc = 'Select next completion item' })

vim.keymap.set('i', '<A-k>', function()
  if vim.fn.pumvisible() == 1 then return '<C-p>' end
  return '<A-k>'
end, { expr = true, silent = true, desc = 'Select prev completion item' })

vim.keymap.set('i', '<Tab>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-y>'
  elseif vim.snippet.active { direction = 1 } then
    return '<cmd>lua vim.snippet.jump(1)<CR>'
  else
    return '<Tab>'
  end
end, { expr = true, silent = true, desc = 'Accept completion item / snippet placeholder' })

vim.keymap.set('i', '<S-Tab>', function()
  if vim.snippet.active { direction = -1 } then
    return '<cmd>lua vim.snippet.jump(-1)<CR>'
  else
    return '<S-Tab>'
  end
end, { expr = true, silent = true, desc = 'Prev snippet placeholder' })

vim.keymap.set('i', '<CR>', function()
  if vim.fn.pumvisible() == 1 then return '<C-y>' end
  return '<CR>'
end, { expr = true, silent = true, desc = 'Confirm completion / newline' })

vim.keymap.set('i', '<C-Space>', function()
  if vim.lsp.completion and vim.lsp.completion.get then
    vim.lsp.completion.get()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-x><C-o>', true, false, true), 'n', false)
  end
end, { desc = 'Trigger native LSP completion' })

-- Split
vim.keymap.set('n', '<leader>s', '<cmd>vsplit<cr>', { desc = '[S]plit Vertical' })
vim.keymap.set('n', '<leader>v', '<cmd>split<cr>', { desc = 'Split Horizontal' })

-- Yank
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.keymap.set('n', '<TAB>', '<cmd>bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<S-TAB>', '<cmd>bprev<CR>', { desc = 'Previous buffer' })
