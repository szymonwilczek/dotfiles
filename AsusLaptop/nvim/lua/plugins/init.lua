return {
  {
    "stevearc/conform.nvim",
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "L3MON4D3/LuaSnip",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require "cmp"
      local lspkind = require "lspkind"

      cmp.setup {
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert {
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm { select = true },
        },
        sources = cmp.config.sources {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
          { name = "buffer" },
        },
        formatting = {
          format = lspkind.cmp_format {
            mode = "symbol",
            maxwidth = 50,
            ellipsis_char = "...",
            show_labelDetails = true,
          },
        },
      }

      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = "buffer" } },
      })
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
    end,
  },
  {
    "onsails/lspkind.nvim",
    lazy = true,
  },
  {
    "hrsh7th/cmp-nvim-lsp",
    lazy = true,
  },
  {
    "L3MON4D3/LuaSnip",
    build = "make install_jsregexp",
    lazy = true,
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

        disable = function(_, buf)
          local max_filesize = 100 * 1024

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
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup {
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = "<Tab>",
          },
        },
        panel = { enabled = false },
        filetypes = {
          javascript = true,
          typescript = true,
          python = true,
          lua = true,
          cpp = true,
          c = true,
        },
        server_opts = {
          telemetry = {
            telemetryLevel = "off",
          },
        },
      }
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
    dependencies = "copilot.lua",
    config = function()
      require("copilot_cmp").setup()
    end,
  },

  { "wakatime/vim-wakatime",       lazy = false },
  { "szymonwilczek/vim-be-better", lazy = false },
  {
    "neoclide/coc.nvim",
    branch = "release",
    lazy = false,
    config = function()
      vim.cmd [[
      let g:coc_global_extensions = [
        \ 'coc-tsserver',
        \ 'coc-json',
        \ 'coc-yaml',
        \ 'coc-html',
        \ 'coc-css',
        \ 'coc-lua',
        \ 'coc-go',
        \ 'coc-python',
        \ ]
    ]]
    end,
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},

    config = function(_, opts)
      require("flash").setup(opts)

      local keymap = vim.keymap.set
      local flash = require("flash")
      keymap({ "n", "x", "o" }, "s", flash.jump, { desc = "Flash" })
      keymap({ "n", "x", "o" }, "S", flash.treesitter, { desc = "Flash Treesitter" })
      keymap("o", "r", flash.remote, { desc = "Remote Flash" })
      keymap({ "o", "x" }, "R", flash.treesitter_search, { desc = "Treesitter Search" })
      keymap("c", "<C-s>", flash.toggle, { desc = "Toggle Flash Search" })
    end,
  },
  {
    "kdheepak/lazygit.nvim",
    lazy = false,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "Open LazyGit" },
      {
        "<leader>lgt",
        function()
          require("telescope").extensions.lazygit.lazygit()
        end,
        desc = "LazyGit Telescope",
      },
    },
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("telescope").load_extension "lazygit"
    end,
  },
  {
    "rmagatti/auto-session",
    lazy = false,
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
      suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
    },
  },
  {
    "folke/snacks.nvim",
    lazy = false,
    ---@type snacks.Config
    opts = {
      lazygit = {
        configure = true,
      }
    }
  }
}
