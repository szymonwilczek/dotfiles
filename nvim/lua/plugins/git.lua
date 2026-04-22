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

      local function add_coauthor_workflow()
        local ft = vim.bo.filetype
        local author_cmd = "(git log --format='%aN <%aE>'; git log --all --format='%(trailers:key=Co-authored-by,valueonly=true)') | sed '/^$/d' | sort -u"
        local authors = vim.fn.systemlist(author_cmd)

        if #authors == 0 then
          vim.notify('Brak autorów w historii!', 'error')
          return
        end

        local Snacks = require 'snacks'
        Snacks.picker.select(authors, {
          prompt = 'Dodaj współautora: ',
          confirm = function(picker, item)
            picker:close()

            vim.schedule(function()
              if not item then return end

              local coauthor = 'Co-authored-by: ' .. item

              if ft == 'gitcommit' then
                local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
                vim.api.nvim_buf_set_lines(0, row, row, false, { coauthor })
              else
                local line = vim.api.nvim_get_current_line()
                local commit_hash = line:match '(%x%x%x%x%x%x%x+)'

                if not commit_hash then
                  vim.notify('Nie widzę hasha pod kursorem!', 'error')
                  return
                end

                local branch = vim.fn.systemlist('git branch --show-current')[1]
                local cmd = string.format('git commit --amend --no-edit --trailer "Co-authored-by: %s"', item)

                local head_hash = vim.fn.systemlist('git rev-parse HEAD')[1]
                local is_head = (commit_hash:sub(1, 7) == head_hash:sub(1, 7))

                if not is_head then
                  cmd = string.format(
                    'git checkout %s && git commit --amend --no-edit --trailer "Co-authored-by: %s" && git rebase --onto HEAD %s %s',
                    commit_hash,
                    item,
                    commit_hash,
                    branch
                  )
                end

                local out = vim.fn.system(cmd)

                if vim.v.shell_error ~= 0 then
                  vim.notify('Git error: ' .. out, 'error')
                else
                  require('neogit').refresh()
                end
              end
            end)
          end,
        }, function() end)
      end
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'NeogitLogView', 'NeogitStatus', 'gitcommit' },
        callback = function()
          vim.keymap.set('n', '<leader>w', add_coauthor_workflow, {
            buffer = true,
            desc = 'Git: Add Co-author',
            nowait = true,
          })
        end,
      })
    end,
  },
}
