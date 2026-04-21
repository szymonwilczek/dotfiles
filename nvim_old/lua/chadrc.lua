---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "cole",
  theme_toggle = { "kanagawa", "cole" },
  transparency = true,
}

local function get_greeting()
  local hour = tonumber(os.date "%H")
  if hour >= 5 and hour < 14 then
    return " ☀️ Good Morning!"
  elseif hour >= 14 and hour < 18 then
    return " ☕ Good Afternoon, Sir."
  elseif hour >= 18 and hour < 23 then
    return " 🌙 Good Evening, time for coding?"
  else
    return " 🦉 Night Owl as usual..."
  end
end

local function get_custom_header()
  local greeting = get_greeting()
  
  local cat = {
    "                                  ",
    "       _                          ",
    "       \\`*-.                     ",
    "        )  _`-.                   ", 
    "       .  : `. .                  ", 
    "       : _   '  \\                ",
    "       ; *` _.   `*-._            ",
    "       `-.-'          `-.         ",
    "         ;       `        `.      ",
    "         :.       .         \\    ",
    "         . \\  .   :   .-'   .    ",
    "         '  `+.;  ;  '      :     ",
    "         :  '  |   ;       ;-.    ",
    "         ; '   : :`-:      _.`* ; ",
    " [bug] .*' /  .*' ; .*`- +'  `*'  ",
    "      `*-* `*-* `*-*'             ",
    "                                  ",
    " " .. greeting,
    "                                  ",

  }
  return cat
end

M.nvdash = {
  load_on_startup = true,
  header = get_custom_header(),
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
