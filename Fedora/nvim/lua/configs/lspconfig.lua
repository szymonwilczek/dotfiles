local nvchad_conf = require("nvchad.configs.lspconfig")

local servers = { "html", "cssls", "ts_ls", "jdtls", "rust_analyzer", "gopls"}

for _, lsp in ipairs(servers) do
  vim.lsp.config(lsp, {
    on_attach = nvchad_conf.on_attach,
    on_init = nvchad_conf.on_init,
    capabilities = nvchad_conf.capabilities,
  })
  vim.lsp.enable(lsp)
end

vim.lsp.config('asmodeus_lsp', {
  cmd = { "asmodeus-lsp" },
  filetypes = { "asmodeus" },
  root_markers = { ".git", "Cargo.toml" }, 
  
  on_attach = nvchad_conf.on_attach,
  on_init = nvchad_conf.on_init,
  capabilities = nvchad_conf.capabilities,
})

vim.lsp.enable('asmodeus_lsp')
