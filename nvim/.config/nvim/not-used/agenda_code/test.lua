local M = {}

function M.run()
  local data = require 'agenda.data'

  local test_dir = vim.fn.stdpath 'cache' .. '/agenda_test'
  vim.fn.delete(test_dir, 'rf')
  vim.fn.mkdir(test_dir, 'p')

  data.setup {
    data_dir = test_dir,
  }

  print 'Running agenda tests...'

  -- get_monday_date
  -- Wednesday May 27, 2026 -> Monday should be May 25, 2026
  local test_time = os.time { year = 2026, month = 5, day = 27, hour = 14, min = 0, sec = 0 }
  local mon = data.get_monday_date(test_time)
  assert(mon == '2026-05-25', 'get_monday_date failed: got ' .. tostring(mon))
  print '✓ Test 1 passed: get_monday_date'

  -- shift_week
  local next_mon = data.shift_week('2026-05-25', 1)
  assert(next_mon == '2026-06-01', 'shift_week failed to shift forward: got ' .. tostring(next_mon))
  local prev_mon = data.shift_week('2026-05-25', -1)
  assert(prev_mon == '2026-05-18', 'shift_week failed to shift backward: got ' .. tostring(prev_mon))
  print '✓ Test 2 passed: shift_week'

  -- save & load project
  local proj_name = 'TEST_PROJ'
  data.save_project(proj_name, { icon = '🧪', color = 'red' })
  local projects = data.get_projects()
  assert(projects[proj_name] ~= nil, 'save_project failed: project not found')
  assert(projects[proj_name].color == 'red', 'save_project failed: color mismatch')
  print '✓ Test 3 passed: save & load project'

  -- get_week initialization
  local week = data.get_week '2026-05-25'
  assert(week.Monday ~= nil, 'get_week failed: Monday section missing')
  assert(type(week.Monday.projects) == 'table', 'get_week failed: projects is not a table')
  print '✓ Test 4 passed: get_week initialization'

  -- clean up
  vim.fn.delete(test_dir, 'rf')
  print 'ALL TESTS PASSED SUCCESSFULLY!'
end

return M
