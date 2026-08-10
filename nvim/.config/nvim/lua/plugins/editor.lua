return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    cmd = 'Neotree',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    keys = {
      { '<C-n>', '<cmd>Neotree toggle<cr>', desc = 'NeoTree toggle (Ctrl-n)' },
      { '<leader>ee', '<cmd>Neotree toggle<cr>', desc = 'NeoTree toggle (SPC e e)' },
    },
    config = function()
      require('nvim-web-devicons').setup {
        override = {
          pem = { icon = '', color = '#D4843E', name = 'Pem' },
          default_icon = { icon = '', color = '#889096', name = 'Default' },
        },
      }
      local function sync_default_icon_color() vim.api.nvim_set_hl(0, 'DevIconDefault', { link = 'NeoTreeDirectoryIcon' }) end
      sync_default_icon_color()
      vim.api.nvim_create_autocmd('ColorScheme', { callback = sync_default_icon_color })

      local function sync_neotree_separator() vim.api.nvim_set_hl(0, 'NeoTreeWinSeparator', { link = 'NeoTreeDotfile' }) end
      sync_neotree_separator()
      vim.api.nvim_create_autocmd('ColorScheme', { callback = sync_neotree_separator })

      require('neo-tree').setup {
        default_component_configs = {
          indent = {
            with_markers = false,
            with_expanders = true,
            expander_collapsed = '',
            expander_expanded = '',
            expander_highlight = 'NeoTreeDirectoryIcon',
          },
          icon = {
            folder_closed = '',
            folder_open = '',
            provider = function(icon, node, state)
              if node.type == 'file' or node.type == 'terminal' then
                local devicons = require 'nvim-web-devicons'
                local name = node.type == 'terminal' and 'terminal' or node.name
                local devicon, hl = devicons.get_icon(name, nil, { default = true })
                icon.text = devicon or icon.text
                icon.highlight = hl or icon.highlight
              end
            end,
          },
          diagnostics = {
            symbols = {
              hint = 'H ',
              info = 'I ',
              warn = 'W ',
              error = 'E ',
            },
          },
          git_status = {
            symbols = {
              untracked = 'U ',
              ignored = '◌ ',
              unstaged = '󰄱 ',
              staged = ' ',
              conflict = ' ',
              added = 'A ',
              deleted = 'D ',
              modified = 'M ',
              renamed = 'R ',
            },
          },
        },
        sources = {
          'filesystem',
          'buffers',
          'git_status',
          'document_symbols',
        },
        close_if_last_window = false,
        hide_root_node = true,
        retain_hidden_root_indent = true,
        filesystem = {
          follow_current_file = {
            enabled = true,
            use_libuv_file_watcher = true,
          },
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = false,
          },
          window = {
            mappings = {
              ['<tab>'] = function(state)
                local node = state.tree:get_node()
                if node.type == 'directory' then
                  state.commands['toggle_node'](state)
                elseif node.type == 'file' then
                  local nt_win = vim.api.nvim_get_current_win()
                  state.commands['open'](state)
                  vim.schedule(function()
                    if vim.api.nvim_win_is_valid(nt_win) then
                      vim.api.nvim_set_current_win(nt_win)
                      vim.cmd 'Neotree document_symbols'
                    end
                  end)
                end
              end,
            },
          },
          components = {
            icon = function(config, node, state)
              local common_components = require 'neo-tree.sources.common.components'
              local icon = common_components.icon(config, node, state)
              if node.type == 'directory' then
                local name = node.name:lower()
                if name:sub(1, 1) == '.' then name = name:sub(2) end

                if name == 'src' then
                  icon.text = ''
                  icon.highlight = 'NeoTreeDirectoryIcon'
                elseif not node:is_expanded() then
                  local closed_icons = {
                    build = '󱁿',
                    test = '󱥾',
                    bin = '󰛫',
                    git = '',
                    github = '',
                    public = '󱞊',
                    private = '󰉐',
                    temp = '󱧊',
                    tmp = '󱧊',
                    readme = '󱧶',
                    docs = '󱧶',
                    screenshots = '󰉏',
                    icons = '󰉏',
                  }
                  local special_icon = closed_icons[name]
                  if special_icon then
                    icon.text = special_icon
                    icon.highlight = 'NeoTreeDirectoryIcon'
                  end
                end
              end
              return icon
            end,
          },
        },
        document_symbols = {
          follow_cursor = true,
          window = {
            mappings = {
              ['<tab>'] = 'toggle_node',
              ['<S-Tab>'] = function() vim.cmd 'Neotree filesystem' end,
              ['<bs>'] = function() vim.cmd 'Neotree filesystem' end,
            },
          },
        },
        window = {
          width = 35,
          mappings = {
            ['<space>'] = 'none',
            ['z'] = 'none',
            ['<C-r>'] = 'none',

            ---
            ['W'] = function()
              vim.ui.input({ prompt = 'New panel width: ' }, function(input)
                if input and tonumber(input) then
                  vim.cmd('vertical resize ' .. input)
                else
                  if input then vim.notify('To nie jest liczba, mordo!', vim.log.levels.ERROR) end
                end
              end)
            end,
            ---
            ['>'] = function() vim.cmd 'vertical resize +5' end,
            ['<'] = function() vim.cmd 'vertical resize -5' end,
            ---
          },
        },
      }

      vim.api.nvim_create_autocmd('TermClose', {
        pattern = '*',
        callback = function()
          if package.loaded['neo-tree.sources.manager'] then
            require('neo-tree.sources.manager').refresh 'filesystem'
            require('neo-tree.sources.manager').refresh 'git_status'
          end
        end,
      })
    end,
  },

  { 'NMAC427/guess-indent.nvim', opts = {} },

  {
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.ai').setup {
        mappings = {
          around_next = 'aa',
          inside_next = 'ii',
        },
        n_lines = 500,
      }
      require('mini.surround').setup()
      -- require('mini.pairs').setup()

      local statusline = require 'mini.statusline'
      statusline.setup {
        use_icons = vim.g.have_nerd_font,
        content = {
          inactive = function() return '%#MiniStatuslineInactive# %t%=' end,
        },
      }
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_filename = function()
        local full = vim.api.nvim_buf_get_name(0)
        if full == '' then return '[No Name]%m%r' end
        local rel = vim.fn.fnamemodify(full, ':.')
        return (rel:gsub('%%', '%%%%')) .. '%m%r'
      end

      local function section_filesize()
        local name = vim.api.nvim_buf_get_name(0)
        if name == '' then return '' end
        local size = vim.fn.getfsize(name)
        if size <= 0 then return '' end
        if size < 1024 then
          return string.format('%dB', size)
        elseif size < 1048576 then
          return string.format('%.2fKiB', size / 1024)
        else
          return string.format('%.2fMiB', size / 1048576)
        end
      end

      local function section_diagnostics()
        local counts = vim.diagnostic.count(0)
        local err = counts[vim.diagnostic.severity.ERROR] or 0
        local warn = counts[vim.diagnostic.severity.WARN] or 0
        return '%#MiniStatuslineFileinfo#[%#DiagnosticError#' .. err .. ' %#DiagnosticWarn# ' .. warn .. '%#MiniStatuslineFileinfo#]'
      end

      local function section_branch()
        local branch = vim.b.minigit_summary_string or vim.b.gitsigns_head
        if branch == nil or branch == '' then return '' end
        return '%#MiniStatuslineFileinfo#[%#Constant#' .. branch .. '%#MiniStatuslineFileinfo#]'
      end

      statusline.config.content.active = function()
        local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
        local filename = statusline.section_filename { trunc_width = 140 }
        local location = statusline.section_location { trunc_width = 75 }
        local filetype = statusline.section_fileinfo { trunc_width = math.huge }
        local encoding = vim.bo.fileencoding or vim.bo.encoding
        local size = section_filesize()
        local diagnostics = section_diagnostics()
        local branch = section_branch()

        local left = {
          '%#' .. mode_hl .. '# ' .. mode .. ' ',
          '%#MiniStatuslineFilename# ' .. filename .. ' ',
        }

        local right = {
          '%#' .. mode_hl .. '# ' .. location .. ' ',
        }
        if filetype ~= '' then table.insert(right, '%#MiniStatuslineFileinfo# ' .. filetype .. ' ') end
        table.insert(right, ' ' .. diagnostics .. ' ')
        table.insert(right, '%#MiniStatuslineFileinfo# ' .. encoding .. ' ' .. size .. ' ')
        if branch ~= '' then table.insert(right, ' ' .. branch .. ' ') end

        return table.concat(left) .. '%#MiniStatuslineFilename#%=' .. table.concat(right)
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'neo-tree',
        callback = function() vim.b.ministatusline_disable = true end,
      })
    end,
  },
  { 'wakatime/vim-wakatime', lazy = false },
}
