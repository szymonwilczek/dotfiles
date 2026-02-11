require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Terminal Left window focus" })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Terminal Right window focus" })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Terminal Down window focus" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Terminal Up window focus" })

map("n", "<leader>tt", function()
  require("base46").toggle_theme()
end, { desc = "Switch Theme" })
