return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio',
    },
    keys = {
      { '<F5>', function() require('dap').continue() end, desc = 'DAP: Start/Continue' },
      { '<F10>', function() require('dap').step_over() end, desc = 'DAP: Step Over' },
      { '<F11>', function() require('dap').step_into() end, desc = 'DAP: Step Into' },
      { '<F12>', function() require('dap').step_out() end, desc = 'DAP: Step Out' },
      { '<leader>b', function() require('dap').toggle_breakpoint() end, desc = 'DAP: Toggle Breakpoint (SPC b)' },
      { '<leader>B', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'DAP: Set Conditional Breakpoint' },
      { '<leader>?', function() require('dapui').eval() end, desc = 'DAP: Hover Value (SPC ?)' },
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      dapui.setup()

      dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
      dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
      dap.listeners.before.event_exited['dapui_config'] = function() dapui.close() end

      dap.adapters.gdb = {
        type = 'executable',
        command = 'gdb',
        args = { '-i', 'dap' },
      }

      dap.configurations.c = {
        {
          name = 'Launch Executable',
          type = 'gdb',
          request = 'launch',
          program = function() return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/build/', 'file') end,
          cwd = '${workspaceFolder}',
          stopAtBeginningOfMainSubprogram = false,
        },
        {
          name = 'Attach to Process',
          type = 'gdb',
          request = 'attach',
          pid = function() return require('dap.utils').pick_process() end,
        },
      }
      dap.configurations.cpp = dap.configurations.c
    end,
  },
}
