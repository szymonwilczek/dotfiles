return {
  {
    name = "agenda",
    dir = vim.fn.stdpath("config"),
    lazy = false,
    priority = 900,
    opts = {
      -- data_dir = vim.fn.stdpath("config") .. "/agenda",
    },
    config = function(_, opts)
      require("agenda").setup(opts)
    end,
    keys = {
      { "<leader>oa", function() require("agenda").open() end, desc = "Open Agenda Planner" },
      { "<leader>as", function() require("agenda").git_sync() end, desc = "Sync Agenda to Git" },
    },
  }
}
