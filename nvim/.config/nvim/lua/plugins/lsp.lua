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
      -- Modular list of filetypes where LSP auto-completion should be disabled
      local disabled_completion_filetypes = {
        'markdown',
        'gfm',
        'rst',
        'text',
        'txt',
        'mail',
        'gitcommit',
      }

      local function is_completion_disabled(bufnr)
        local ft = vim.bo[bufnr].filetype
        local bt = vim.bo[bufnr].buftype
        return bt ~= '' or vim.tbl_contains(disabled_completion_filetypes, ft) or vim.b[bufnr].completion == false
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local bufnr = event.buf
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
          end

          -- Jump to Definition / Declaration / Implementation / Type Def / References
          map('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('gi', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
          map('gy', vim.lsp.buf.type_definition, '[G]oto T[y]pe Definition')
          map('gr', vim.lsp.buf.references, '[G]oto [R]eferences')

          -- Actions & Refactor
          map('ga', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

          -- Documentation / Hover
          map('K', vim.lsp.buf.hover, 'Hover Documentation')

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          if not is_completion_disabled(bufnr) and vim.lsp.completion and client and client:supports_method('textDocument/completion', bufnr) then
            local completion_provider = client.server_capabilities.completionProvider
            if completion_provider then
              local triggers = completion_provider.triggerCharacters or {}
              local chars = {
                'a',
                'b',
                'c',
                'd',
                'e',
                'f',
                'g',
                'h',
                'i',
                'j',
                'k',
                'l',
                'm',
                'n',
                'o',
                'p',
                'q',
                'r',
                's',
                't',
                'u',
                'v',
                'w',
                'x',
                'y',
                'z',
                'A',
                'B',
                'C',
                'D',
                'E',
                'F',
                'G',
                'H',
                'I',
                'J',
                'K',
                'L',
                'M',
                'N',
                'O',
                'P',
                'Q',
                'R',
                'S',
                'T',
                'U',
                'V',
                'W',
                'X',
                'Y',
                'Z',
                '0',
                '1',
                '2',
                '3',
                '4',
                '5',
                '6',
                '7',
                '8',
                '9',
                '_',
                '-',
              }
              for _, char in ipairs(chars) do
                if not vim.tbl_contains(triggers, char) then table.insert(triggers, char) end
              end
              completion_provider.triggerCharacters = triggers
            end

            vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
          end

          if client and client:supports_method('textDocument/inlayHint', bufnr) then
            map('<leader>h', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }) end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      ---@type table<string, vim.lsp.Config>
      local servers = {
        clangd = {},
        bashls = {},
        astro = {},
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
        astro = { 'prettierd', 'prettier', stop_after_first = true },
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
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install {
        'astro',
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
        'tsx',
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
