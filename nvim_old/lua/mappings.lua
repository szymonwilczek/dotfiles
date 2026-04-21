require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

map("n", "<leader>tt", function()
  require("base46").toggle_theme()
end, { desc = "Switch Theme" })
