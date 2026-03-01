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
      "hrsh7th/cmp-cmdline",
    },
    config = function()
      local cmp = require "cmp"
      local lspkind = require "lspkind"
      local luasnip = require "luasnip"

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert {
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm { select = true },
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
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
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      }
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile", "VeryLazy" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    dependencies = { { "windwp/nvim-ts-autotag" }, },
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
    "vyfor/cord.nvim",
    lazy = false,
    build = ":Cord update",
    config = function()
      require("cord").setup()
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
  { "wakatime/vim-wakatime", lazy = false },
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
        config = {
          os = { editPreset = "nvim-remote" },
          gui = {
            nerdFontsVersion = "3",
            showIcons = false,
          },
          git = {
            overrideGpg = true,
          },
        },
      },
    },
    keys = {
      {
        "<leader>lg",
        function()
          Snacks.lazygit()
        end,
        desc = "Lazygit (Snacks)",
      },
    },
  },
  {
    "thekylehuang/cole.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme "cole"
    end,
  },
}
