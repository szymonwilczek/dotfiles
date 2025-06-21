---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "rosepine",
  transparency = true,

  -- hl_override = {
  -- 	Comment = { italic = true },
  -- 	["@comment"] = { italic = true },
  -- },
}

M.nvdash = {
  load_on_startup = true,
  header = {
    "                                                                       ",
    "                                                                       ",
    "                                                                       ",
    "                                                                       ",
    "                                                                       ",
    "                                                                     ",
    "       ████ ██████           █████      ██                     ",
    "      ███████████             █████                             ",
    "      █████████ ███████████████████ ███   ███████████   ",
    "     █████████  ███    █████████████ █████ ██████████████   ",
    "    █████████ ██████████ █████████ █████ █████ ████ █████   ",
    "  ███████████ ███    ███ █████████ █████ █████ ████ █████  ",
    " ██████  █████████████████████ ████ █████ █████ ████ ██████ ",
    "                                                                       ",
    "                                                                       ",
    "                                                                       ",
    "                                                                       ",
    "                                                                       ",
  },
}
M.ui = {
  statusline = {
    theme = "vscode_colored",
  },
}

M.lsp = {
  signature = true
}

M.colorify = {
  enabled = true,
  mode = "virtual",
  virt_text = "󱓻 ",
  highlight = { hex = true, lspvars = true },
}

return M
