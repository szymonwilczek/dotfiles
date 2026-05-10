return {
  'lervag/vimtex',
  lazy = false,
  init = function()
    vim.g.vimtex_view_method = 'zathura'
    vim.g.vimtex_compiler_method = 'latexmk'
    vim.g.vimtex_compiler_latexmk = {
      options = {
        '-shell-escape',
        '-verbose',
        '-file-line-error',
        '-synctex=1',
        '-interaction=nonstopmode',
      },
    }

    -- ascetic interface
    vim.g.vimtex_quickfix_mode = 0
    vim.g.vimtex_view_forward_search_on_start = 0
    vim.g.vimtex_log_ignore = {
      'Underfull',
      'Overfull',
      'specifier changed to',
    }

    vim.g.vimtex_mappings_prefix = '<leader>m'
  end,
}
