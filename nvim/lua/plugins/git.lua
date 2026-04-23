return {
  {
    'lewis6991/gitsigns.nvim',
    ---@module 'gitsigns'
    ---@type Gitsigns.Config
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      signs = {
        add = { text = '+' }, ---@diagnostic disable-line: missing-fields
        change = { text = '~' }, ---@diagnostic disable-line: missing-fields
        delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
        topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
        changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
      },
    },
  },

  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim',
      'nvim-telescope/telescope.nvim',
    },
    keys = {
      { '<leader>gs', '<cmd>Neogit<cr>', desc = 'Neogit status' },
    },
    config = function()
      local neogit = require 'neogit'
      neogit.setup {
        disable_commit_confirmation = true,
        integrations = { diffview = true },
      }

      local function git_sign_off()
        local name = vim.fn.systemlist('git config user.name')[1] or ''
        local email = vim.fn.systemlist('git config user.email')[1] or ''
        local signoff = string.format('Signed-off-by: %s <%s>', name, email)

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local insert_pos = #lines
        for i, line in ipairs(lines) do
          if line:match '^#' then
            insert_pos = i - 1
            break
          end
        end

        if insert_pos > 0 and lines[insert_pos] ~= '' and not lines[insert_pos]:match '^#' then
          vim.api.nvim_buf_set_lines(0, insert_pos, insert_pos, false, { '', signoff })
        else
          vim.api.nvim_buf_set_lines(0, insert_pos, insert_pos, false, { signoff })
        end
      end

      local function add_coauthor_picker()
        local target_buf = vim.api.nvim_get_current_buf()

        -- after signed-off-by
        local lines = vim.api.nvim_buf_get_lines(target_buf, 0, -1, false)
        local signoff_idx = nil

        for i, line in ipairs(lines) do
          if line:match '^Signed%-off%-by:' then signoff_idx = i end
        end

        if not signoff_idx then
          vim.notify('Error: You have to sign commit first!', vim.log.levels.ERROR)
          return
        end

        local author_cmd = "git log --all --format='%aN <%aE>' | sort -u"
        local authors = vim.fn.systemlist(author_cmd)

        if #authors == 0 then
          vim.notify('No other authors in commit history!', 'error')
          return
        end

        local Snacks = require 'snacks'
        Snacks.picker.select(authors, {
          prompt = 'Pick co-author: ',
        }, function(item)
          if not item then return end

          vim.schedule(function()
            local coauthor = 'Co-authored-by: ' .. item
            vim.api.nvim_buf_set_lines(target_buf, signoff_idx, signoff_idx, false, { coauthor, '' })
            vim.api.nvim_win_set_cursor(0, { signoff_idx + 2, 0 })
          end)
        end)
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'gitcommit',
        callback = function()
          local opts = { buffer = true, noremap = true, silent = true }

          -- yeah, emacs bindings

          -- C-c C-s (Sign-off)
          vim.keymap.set({ 'n', 'i' }, '<C-c><C-s>', git_sign_off, opts)
          vim.keymap.set('n', '<leader>s', git_sign_off, vim.tbl_extend('force', opts, { desc = 'Git: Sign-off' }))

          -- C-c C-w (Co-author)
          vim.keymap.set({ 'n', 'i' }, '<C-c><C-w>', add_coauthor_picker, opts)
        end,
      })
    end,
  },
}
