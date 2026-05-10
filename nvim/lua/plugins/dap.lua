return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio', -- Biblioteka asynchroniczna wymagana przez dap-ui
      'leoluz/nvim-dap-go', -- Gotowy adapter dla języka Go
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      -- 1. Inicjalizacja interfejsu (z domyślnym układem okien)
      dapui.setup()

      -- 2. Inicjalizacja adaptera dla Go (automatycznie podepnie 'dlv')
      require('dap-go').setup()

      -- 3. Automatyzacja UI: Otwieraj okna debuggera, gdy startuje sesja,
      -- i zamykaj, kiedy program kończy działanie.
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
    end,
    keys = {
      -- Standardowe bindowania znane z klasycznych IDE (F5, F10, F11)
      { '<F5>', function() require('dap').continue() end, desc = 'DAP: Start/Continue' },
      { '<F10>', function() require('dap').step_over() end, desc = 'DAP: Step Over' },
      { '<F11>', function() require('dap').step_into() end, desc = 'DAP: Step Into' },
      { '<F12>', function() require('dap').step_out() end, desc = 'DAP: Step Out' },

      -- Skróty pod leaderem do operacji na samym debuggerze
      { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'DAP: Toggle Breakpoint' },
      { '<leader>du', function() require('dapui').toggle() end, desc = 'DAP: Toggle UI manually' },
    },
  },
}
