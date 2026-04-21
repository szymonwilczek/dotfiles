local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "prettierd" },
    typescript = { "prettierd" },
    c = { "clang_format" },
    cpp = { "clang_format" },
    rust = { "rustfmt "},
    go = { "gofumpt", "goimports" },
    cs = { "csharpier" },
  },
}

return options
