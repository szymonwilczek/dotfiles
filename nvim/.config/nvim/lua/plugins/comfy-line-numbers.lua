return {
  'mluders/comfy-line-numbers.nvim',
  event = 'VeryLazy',
  keys = {
    {
      '<leader>r',
      function() vim.cmd 'ComfyLineNumbers toggle' end,
      desc = '[R]elative (Comfy) line numbers toggle',
    },
  },
  opts = {
    hidden_file_types = {
      'undotree',
      'neo-tree',
      'alpha',
      'mason',
      'lazy',
      'fidget',
      'help',
      'qf',
      'lspinfo',
      'notify',
    },
    hidden_buffer_types = { 'terminal', 'nofile' },
  },
  config = function(_, opts)
    local comfy = require 'comfy-line-numbers'
    comfy.setup(opts)

    _G.update_status_column = function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if not vim.api.nvim_win_is_valid(win) then goto continue end
        local buf = vim.api.nvim_win_get_buf(win)
        local buftype = vim.bo[buf].buftype
        local filetype = vim.bo[buf].filetype

        local is_normal_buffer = (buftype == '')
        local should_hide = vim.tbl_contains(opts.hidden_file_types or {}, filetype) or vim.tbl_contains(opts.hidden_buffer_types or {}, buftype)

        -- helper function to check if comfy-line-numbers are active
        local function is_comfy_enabled()
          local label1 = comfy.config.labels[1] or '1'
          local key = label1 .. comfy.config.up_key
          return vim.fn.maparg(key, 'n') ~= ''
        end

        if is_normal_buffer and not should_hide then
          vim.api.nvim_win_call(win, function()
            if is_comfy_enabled() then
              -- explicitly enable relative numbers for comfy rendering
              vim.wo[win].number = true
              vim.wo[win].relativenumber = true

              local total_lines = vim.api.nvim_buf_line_count(buf)
              local width = math.max(4, #tostring(total_lines))
              vim.wo[win].numberwidth = width
              vim.wo[win].statuscolumn = '%=%s%=%{v:virtnum > 0 ? "" : v:lua.get_label(v:lnum, v:relnum)} '
            else
              -- fallback to standard absolute line numbers if comfy is toggled off
              vim.wo[win].statuscolumn = ''
              vim.wo[win].relativenumber = false
              vim.wo[win].number = true
            end
          end)
        else
          -- force clean status column and disable number columns entirely in hidden/utility windows
          vim.api.nvim_win_call(win, function()
            vim.wo[win].statuscolumn = ''
            if should_hide then
              vim.wo[win].number = false
              vim.wo[win].relativenumber = false
            end
          end)
        end
        ::continue::
      end
    end
    _G.update_status_column()
  end,
}
