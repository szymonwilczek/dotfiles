return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      {
        'mason-org/mason.nvim',
        ---@module 'mason.settings'
        ---@type MasonSettings
        ---@diagnostic disable-next-line: missing-fields
        opts = {},
      },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('gr', vim.lsp.buf.rename, '[R]e[n]ame')
          map('ga', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('gd', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          if vim.lsp.completion and client and client:supports_method('textDocument/completion', event.buf) then
            vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
          end

          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            map('<leader>h', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      ---@type table<string, vim.lsp.Config>
      local servers = {
        clangd = {},
        bashls = {},
        gopls = {
          settings = {
            gopls = {
              analyses = {
                unusedparams = true,
                shadow = true,
              },
              staticcheck = true,
              gofumpt = true,
            },
          },
        },
        -- pyright = {},
        -- rust_analyzer = {},
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- But for many setups, the LSP (`ts_ls`) will work just fine
        -- ts_ls = {},

        stylua = {},

        lua_ls = {
          on_init = function(client)
            client.server_capabilities.documentFormattingProvider = false

            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
            end

            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
              runtime = {
                version = 'LuaJIT',
                path = { 'lua/?.lua', 'lua/?/init.lua' },
              },
              workspace = {
                checkThirdParty = false,
                library = { '${3rd}/luv/library' },
              },
            })
          end,
          ---@type lspconfig.settings.lua_ls
          settings = {
            Lua = {
              format = { enable = false },
            },
          },
        },
      }

      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'shfmt',
        'shellcheck',
      })

      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      for name, server in pairs(servers) do
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
      end
    end,
  },

  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },

  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function() require('conform').format { async = true } end,
        mode = '',
        desc = '[F]ormat buffer',
      },
      {
        '<leader>fm',
        function() require('conform').format { async = true } end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    ---@module 'conform'
    ---@type conform.setupOpts
    opts = {
      notify_on_error = false,
      format_on_save = false,
      default_format_opts = {
        lsp_format = 'fallback',
      },
      formatters_by_ft = {
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        c = { 'clang-format' },
        cpp = { 'clang-format' },
        python = { 'ruff_fix', 'ruff_format', 'ruff_organize_imports' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        go = { 'goimports', 'gofmt' },
      },
    },
  },

  {
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {},
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      enabled = function()
        local disabled_filetypes = { 'markdown', 'gfm', 'rst', 'text', 'txt', 'mail', 'gitcommit' }
        return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype) and vim.bo.buftype ~= 'prompt' and vim.b.completion ~= false
      end,
      keymap = {
        preset = 'default',
        ['<A-j>'] = { 'select_next', 'fallback' },
        ['<A-k>'] = { 'select_prev', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Space>'] = { 'accept', 'fallback' },
        ['<C-space>'] = { 'show', 'hide' },
      },

      appearance = {
        nerd_font_variant = 'mono',
      },
      completion = {
        menu = {
          auto_show = true,
          direction_priority = { 's' },
        },
        trigger = {
          show_on_keyword = true,
          show_on_trigger_character = true,
        },
        list = {
          selection = { preselect = false, auto_insert = true },
        },
        documentation = {
          auto_show = false,
        },
      },
      sources = {
        default = { 'lazydev', 'lsp', 'path' },
        providers = {
          lazydev = {
            name = 'LazyDev',
            module = 'lazydev.integrations.blink',
            score_offset = 100,
          },
          lsp = {
            min_keyword_length = 1,
          },
          path = {
            min_keyword_length = 0,
          },
        },
      },
      fuzzy = { implementation = 'lua' },
      signature = {
        enabled = false,
      },
    },
  },

  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install {
        'lua',
        'markdown',
        'markdown_inline',
        'vim',
        'vimdoc',
        'query',
        'bash',
        'latex',
        'javascript',
        'typescript',
        'python',
        'yaml',
        'toml',
        'json',
        'html',
        'css',
      }

      vim.opt.foldmethod = 'manual'
      vim.opt.foldexpr = ''
      vim.opt.foldtext = ''

      local TREESITTER_LINE_THRESHOLD = 5000

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          if vim.api.nvim_buf_line_count(args.buf) > TREESITTER_LINE_THRESHOLD then return end
          local lang = vim.treesitter.language.get_lang(args.match)
          if not lang or not pcall(vim.treesitter.start, args.buf, lang) then return end
        end,
      })
    end,
  },
}
