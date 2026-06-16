vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.o.number = true
vim.o.mouse = 'a'
vim.o.showmode = false

vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = 'yes'

vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.o.inccommand = 'split'

vim.o.cursorline = true
vim.o.scrolloff = 10
vim.opt.guicursor = 'n-v-c-sm-i-ci-ve:block,r-cr-o:hor20'

vim.o.confirm = true

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- diagnostic config
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = false,
  virtual_lines = false,
  jump = { float = true },
}

-- folds
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldcolumn = '0'
vim.opt.foldtext = ''
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- conflict markers
local error_fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticError' }).fg
local info_fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticInfo' }).fg
local warn_fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticWarn' }).fg
vim.api.nvim_set_hl(0, 'ConflictMarkerBegin', { fg = error_fg, bold = true, reverse = true })
vim.api.nvim_set_hl(0, 'ConflictMarkerSeparator', { fg = warn_fg, bold = true, reverse = true })
vim.api.nvim_set_hl(0, 'ConflictMarkerEnd', { fg = info_fg, bold = true, reverse = true })
