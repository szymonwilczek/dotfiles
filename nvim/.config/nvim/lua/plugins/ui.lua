local DASHBOARD_WIDTH = 80

math.randomseed(os.time())

local ACCENT_GROUPS = { 'Keyword', 'Function', 'Constant', 'Type', 'String', 'Special', 'Identifier' }
local project_accent_group = ACCENT_GROUPS[math.random(#ACCENT_GROUPS)]

local function sync_dashboard_project_hl()
  local fg = vim.api.nvim_get_hl(0, { name = project_accent_group, link = false }).fg
  vim.api.nvim_set_hl(0, 'DashboardProjectName', { fg = fg, bold = true })
end
sync_dashboard_project_hl()
vim.api.nvim_create_autocmd('ColorScheme', { callback = sync_dashboard_project_hl })

local function dashboard_banner()
  local hl_map = {
    R = 'DiagnosticError',
    G = 'String',
    L = 'Special',
    Y = 'DiagnosticWarn',
    O = 'Constant',
    P = 'Keyword',
    C = 'Function',
    A = 'Comment',
    B = 'Type',
    W = 'Normal',
  }

  local banner_dir = vim.fn.stdpath 'config' .. '/banners'
  local files = vim.fn.glob(banner_dir .. '/*.txt', false, true)
  local chosen_file = #files > 0 and files[math.random(#files)] or nil

  return function()
    if not chosen_file then return {} end
    local raw_lines = vim.fn.readfile(chosen_file)

    local max_width = 0
    for _, line in ipairs(raw_lines) do
      local stripped = line:gsub('%[[RGLYOPCABW]%]', '')
      max_width = math.max(max_width, vim.fn.strwidth(stripped))
    end
    local pad = math.max(0, math.floor((DASHBOARD_WIDTH - max_width) / 2))
    local left_pad = (' '):rep(pad)

    local spans = {}
    for _, line in ipairs(raw_lines) do
      table.insert(spans, { left_pad })
      local segment_start, current_hl, i = 1, nil, 1
      while true do
        local tag_start, tag_end, letter = line:find('%[([RGLYOPCABW])%]', i)
        if not tag_start then break end
        if tag_start > segment_start then table.insert(spans, { line:sub(segment_start, tag_start - 1), hl = current_hl }) end
        current_hl = hl_map[letter]
        segment_start = tag_end + 1
        i = tag_end + 1
      end
      table.insert(spans, { line:sub(segment_start), hl = current_hl })
      table.insert(spans, { '\n' })
    end

    return { text = spans, align = 'left', padding = 1 }
  end
end

local function dashboard_project()
  return function()
    local cwd = vim.fn.getcwd()
    local github_root = vim.fn.expand '~/Dokumenty/GitHub/'
    local text
    if cwd:sub(1, #github_root) == github_root then
      text = cwd:sub(#github_root + 1):match '^[^/]+'
    else
      text = vim.fn.fnamemodify(cwd, ':~')
    end
    return { text = { { text:upper(), hl = 'DashboardProjectName' } }, align = 'center', padding = 1 }
  end
end

return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      picker = {
        enabled = false,
      },
      scroll = {
        enabled = false,
      },
      dashboard = {
        enabled = true,
        width = DASHBOARD_WIDTH,
        sections = {
          dashboard_banner(),
          dashboard_project(),
        },
      },
      lazygit = {
        configure = true,
      },
    },
    keys = {
      { '<leader>lg', function() Snacks.lazygit() end, desc = 'Lazygit' },
    },
    config = function(_, opts)
      require('snacks').config.style('dashboard', { wo = { fillchars = 'eob: ' } })
      require('snacks').setup(opts)
    end,
  },

  {
    'ibhagwan/fzf-lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = 'FzfLua',
    keys = {
      { '<leader>ff', function() require('fzf-lua').files() end, desc = 'Find Files' },
      { '<leader>fw', function() require('fzf-lua').live_grep() end, desc = 'Live Grep' },
      { '<leader>fr', function() require('fzf-lua').oldfiles() end, desc = 'Recent Files' },
      { '<A-x>', function() require('fzf-lua').commands() end, desc = 'Commands' },
    },
    opts = {
      'ivy',
      silent = true,
      fzf_opts = {
        ['--layout'] = 'reverse',
        ['--info'] = 'inline-right',
      },
      winopts = {
        height = 0.30,
        width = 1.0,
        row = 1.0,
        col = 0,
        border = 'none',
        preview = {
          layout = 'flex',
          horizontal = 'right:50%',
          vertical = 'down:40%',
          hidden = 'nohidden',
        },
      },
      files = {
        cmd = 'fd --type f --hidden --follow --exclude .git',
      },
      grep = {
        rg_opts = '--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --hidden --glob "!.git/*"',
      },
    },
  },

  {
    'famiu/bufdelete.nvim',
    keys = {
      { '<leader>q', function() require('bufdelete').bufdelete(0, false) end, desc = 'Zamknij bufor (SPC q)' },
    },
  },

  {
    's1n7ax/nvim-window-picker',
    name = 'window-picker',
    event = 'VeryLazy',
    version = '2.*',
    config = function()
      require('window-picker').setup {
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          bo = {
            filetype = { 'neo-tree', 'neo-tree-popup', 'notify', 'snacks_picker_input' },
            buftype = { 'terminal', 'quickfix' },
          },
        },
        hint = 'floating-big-letter',
        picker_config = {
          floating_big_letter = {
            font = 'ansi-shadow',
          },
        },
        show_prompt = false,
      }
    end,
  },
}
