return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup {}
    end,
  },

  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot", -- Ładuje wtyczkę, gdy wywołasz komendę :Copilot
    event = "InsertEnter", -- Ładuje wtyczkę, gdy wejdziesz w tryb wstawiania (i zaczniesz pisać)
    config = function()
      require("copilot").setup {
        -- Tutaj możesz dodać swoją konfigurację Copilota, np.:
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = "<Tab>",
          },
        },
        panel = { enabled = false }, -- Czasem warto wyłączyć panel, jeśli używasz nvim-cmp
        filetypes = { -- Możesz ograniczyć, dla jakich typów plików ma działać Copilot
          javascript = true,
          typescript = true,
          python = true,
          lua = true,
          cpp = true,
          c = true,
          -- Włącz dla wszystkich innych plików, które nie są wyłączone:
          -- ['*'] = true,
        },
      }
    end,
  },
  -- Zazwyczaj będziesz też potrzebować integracji z nvim-cmp:
  {
    "zbirenbaum/copilot-cmp",
    dependencies = "copilot.lua",
    config = function()
      require("copilot_cmp").setup()
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile", "VeryLazy" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    dependencies = {
      { "windwp/nvim-ts-autotag" },
    },
    config = function()
      require("nvim-ts-autotag").setup {}
      local treesitter = require "nvim-treesitter.configs"

      treesitter.setup {
        ensure_installed = {
          "tsx",
          "typescript",
          "toml",
          "json",
          "yaml",
          "go",
          "css",
          "html",
          "lua",
          "vim",
          "vimdoc",
          "bash",
          "java",
        },
        highlight = {
          enable = true,
          use_languagetree = true,
        },

        auto_install = true,
        -- list of language that will be disabled
        -- disable = { },
        --
        -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
        disable = function(_, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,

        indent = {
          enable = true,
          disable = {},
        },
      }
    end,
  },
}
