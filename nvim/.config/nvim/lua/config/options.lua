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
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    local diag_err = vim.api.nvim_get_hl(0, { name = 'DiagnosticError' })
    local diag_warn = vim.api.nvim_get_hl(0, { name = 'DiagnosticWarn' })
    local diag_info = vim.api.nvim_get_hl(0, { name = 'DiagnosticInfo' })

    local error_fg = diag_err.fg or '#ff0000'
    local warn_fg = diag_warn.fg or '#ffaa00'
    local info_fg = diag_info.fg or '#00aaff'

    vim.api.nvim_set_hl(0, 'GitLineOurs', { fg = error_fg, bold = true, reverse = true })
    vim.api.nvim_set_hl(0, 'GitLineSep', { fg = warn_fg, bold = true, reverse = true })
    vim.api.nvim_set_hl(0, 'GitLineTheirs', { fg = info_fg, bold = true, reverse = true })
  end,
})

vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
  callback = function()
    vim.fn.matchadd('GitLineOurs', '^<<<<<<<.*$')
    vim.fn.matchadd('GitLineSep', '^=\\{7\\}$')
    vim.fn.matchadd('GitLineTheirs', '^>>>>>>>.*$')
  end,
})
