local data = require 'agenda.data'
local ui = require 'agenda.ui'

local M = {}

M.data = data
M.ui = ui

-- plugin configuration
function M.setup(opts)
  data.setup(opts)
  vim.api.nvim_create_user_command('Agenda', function() M.open() end, {})
  vim.api.nvim_create_user_command('AgendaSync', function() M.git_sync() end, {})
  vim.api.nvim_create_autocmd('ColorScheme', {
    callback = function()
      if ui.buf and vim.api.nvim_buf_is_valid(ui.buf) then ui.render(ui.current_monday) end
    end,
  })
end

function M.open(monday_str)
  ui.open(monday_str)
  M.bind_buffer_keys(ui.buf)
end

function M.git_sync()
  local projects_file = data.config.projects_file
  local schedule_file = data.config.schedule_file

  if not projects_file or not schedule_file then return end

  local resolved_projects = vim.fn.resolve(projects_file)
  local resolved_schedule = vim.fn.resolve(schedule_file)
  local resolved_cwd = vim.fn.fnamemodify(resolved_projects, ':h')

  local cmd = string.format("git add %q %q && git commit -m 'agenda: sync'", resolved_projects, resolved_schedule)
  vim.notify('agenda: sync...', vim.log.levels.INFO)

  vim.fn.jobstart(cmd, {
    cwd = resolved_cwd,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify('agenda: synced!', vim.log.levels.INFO)
      else
        vim.notify('agenda: Błąd synchronizacji Git (exit code: ' .. exit_code .. ')', vim.log.levels.WARN)
      end
    end,
  })
end

-- Interactive Controller
local function toggle_task()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local map = ui.line_map[line]
  if not map or map.type ~= 'task' then return end

  local week_data = data.get_week(ui.current_monday)
  local day_data = week_data[map.day_name]
  if not day_data or not day_data.tasks[map.task_idx] then return end

  day_data.tasks[map.task_idx].done = not day_data.tasks[map.task_idx].done
  data.save_week(ui.current_monday, week_data)

  ui.render(ui.current_monday)
  vim.api.nvim_win_set_cursor(0, { line, 0 })
end

-- Interactive Controller: Add Task
local function add_task()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local map = ui.line_map[line]
  if not map or (map.type ~= 'day_header' and map.type ~= 'task') then
    vim.notify('agenda: Ustaw kursor na dniu lub zadaniu, aby dodać nowe zadanie.', vim.log.levels.WARN)
    return
  end

  local day_name = map.day_name
  local week_data = data.get_week(ui.current_monday)
  local projects_db = data.get_projects()

  local day_data = week_data[day_name] or { projects = {} }
  if #day_data.projects == 1 and day_data.projects[1] == 'POZA DOMEM' then
    vim.notify('agenda: Nie można dodawać zadań do statusu OUT OF HOME!', vim.log.levels.WARN)
    return
  end

  if not day_data.projects or #day_data.projects == 0 then
    vim.notify('agenda: Zadania można dodawać tylko do dni z przypisanymi projektami!', vim.log.levels.WARN)
    return
  end

  local target_proj_name = nil
  local target_proj = nil

  for _, p_name in ipairs(day_data.projects) do
    local proj = projects_db[p_name]
    if proj and proj.type == 'serwis' then
      target_proj_name = p_name
      target_proj = proj
      break
    end
  end

  local prompt_str = string.format('Dodaj ' .. (target_proj and 'usługę' or 'podzadanie') .. ' dla [%s]: ', day_name)

  local function insert_task(value)
    if not value or value == '' then return end

    if target_proj then
      -- append to project services
      target_proj.services = target_proj.services or {}
      table.insert(target_proj.services, value)
      data.save_project(target_proj_name, target_proj)

      -- self-healing aligns schedule.json
      data.get_week(ui.current_monday)
    else
      -- add as local subtask
      day_data.tasks = day_data.tasks or {}
      table.insert(day_data.tasks, { text = value, done = false })
      data.save_week(ui.current_monday, week_data)
    end

    ui.render(ui.current_monday)

    local new_line = line
    local new_week_data = data.get_week(ui.current_monday)
    for l, m in pairs(ui.line_map) do
      if m.type == 'task' and m.day_name == day_name and m.task_idx == #new_week_data[day_name].tasks then
        new_line = l
        break
      end
    end
    pcall(vim.api.nvim_win_set_cursor, 0, { new_line, 0 })
  end

  if package.loaded['snacks'] and require('snacks').input then
    require('snacks').input({ prompt = prompt_str }, insert_task)
  else
    vim.ui.input({ prompt = prompt_str }, insert_task)
  end
end

-- Interactive Controller: Delete Task OR Clear day project assignment
local function delete_task()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local map = ui.line_map[line]
  if not map then return end

  local week_data = data.get_week(ui.current_monday)

  -- deletion on day header
  if map.type == 'day_header' then
    local day_polish = {
      Monday = 'Poniedziałek',
      Tuesday = 'Wtorek',
      Wednesday = 'Środa',
      Thursday = 'Czwartek',
      Friday = 'Piątek',
      Saturday = 'Sobota',
      Sunday = 'Niedziela',
    }
    week_data[map.day_name].projects = {}
    week_data[map.day_name].tasks = {}
    data.save_week(ui.current_monday, week_data)

    data.get_week(ui.current_monday) -- self-healing
    ui.render(ui.current_monday)
    pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
    return
  end

  if map.type ~= 'task' then return end

  -- deletion on task
  local day_data = week_data[map.day_name]
  if not day_data or not day_data.tasks[map.task_idx] then return end

  local task_text = day_data.tasks[map.task_idx].text
  local projects_db = data.get_projects()

  local target_proj_name = nil
  local target_proj = nil
  for _, p_name in ipairs(day_data.projects) do
    local proj = projects_db[p_name]
    if proj and proj.type == 'serwis' and proj.services then
      for _, s_name in ipairs(proj.services) do
        if s_name == task_text then
          target_proj_name = p_name
          target_proj = proj
          break
        end
      end
    end
    if target_proj then break end
  end

  if target_proj then
    local new_services = {}
    for _, s_name in ipairs(target_proj.services) do
      if s_name ~= task_text then table.insert(new_services, s_name) end
    end
    target_proj.services = new_services
    data.save_project(target_proj_name, target_proj)
  end

  -- Always remove from local day tasks and save
  table.remove(day_data.tasks, map.task_idx)
  data.save_week(ui.current_monday, week_data)

  ui.render(ui.current_monday)
  local prev_line = math.max(1, line - 1)
  pcall(vim.api.nvim_win_set_cursor, 0, { prev_line, 0 })
end

-- Interactive Controller: Create Project
local function add_project()
  local function prompt_color(name, icon, type, services)
    local colors = { 'cyan', 'blue', 'orange', 'magenta', 'green', 'red', 'gray' }
    local is_serwis = (type == 'serwis')
    local type_label = is_serwis and 'serwisu' or 'projektu'

    vim.ui.select(colors, {
      prompt = string.format('Kolor %s (podpowiedzi motywu arete: cyan, blue, orange, magenta, green, red, gray):', type_label),
    }, function(color)
      if not color then return end

      local details = { icon = icon, color = color }
      if is_serwis then
        details.type = 'serwis'
        details.services = services
      end

      data.save_project(name, { icon = icon, color = color, type = details.type, services = details.services })

      if ui.buf and vim.api.nvim_buf_is_valid(ui.buf) then ui.render(ui.current_monday) end
    end)
  end

  local function prompt_services(name, icon)
    local function parse_services(services_str)
      local services = {}
      if services_str and services_str ~= '' then
        for s in string.gmatch(services_str, '([^,]+)') do
          s = s:gsub('^%s+', ''):gsub('%s+$', '')
          if s ~= '' then table.insert(services, s) end
        end
      end
      prompt_color(name, icon, 'serwis', services)
    end

    local prompt_text = 'Podaj podzadania oddzielone przecinkami (np. skrecior, arete): '
    if package.loaded['snacks'] and require('snacks').input then
      require('snacks').input({ prompt = prompt_text }, parse_services)
    else
      vim.ui.input({ prompt = prompt_text }, parse_services)
    end
  end

  local function prompt_type(name, icon)
    vim.ui.select({ 'Projekt całodniowy', 'Projekt typu Serwis (wiele małych zadań)' }, {
      prompt = 'Typ projektu:',
    }, function(choice)
      if not choice then return end
      if choice:match 'Serwis' then
        prompt_services(name, icon)
      else
        prompt_color(name, icon, 'normal', nil)
      end
    end)
  end

  local function prompt_icon(name)
    if not name or name == '' then return end

    local icon_prompt = 'Wpisz ikonę dla ' .. name .. ' (np. 🚀) [opcjonalne, Enter = pusta]: '
    if package.loaded['snacks'] and require('snacks').input then
      require('snacks').input({ prompt = icon_prompt, default = '' }, function(icon) prompt_type(name, icon or '') end)
    else
      vim.ui.input({ prompt = icon_prompt, default = '' }, function(icon) prompt_type(name, icon or '') end)
    end
  end

  local name_prompt = 'Nazwa nowego projektu/serwisu: '
  if package.loaded['snacks'] and require('snacks').input then
    require('snacks').input({ prompt = name_prompt }, prompt_icon)
  else
    vim.ui.input({ prompt = name_prompt }, prompt_icon)
  end
end

-- helper: parse the populated text buffer
local function parse_edit_buffer(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local name = nil
  local services = {}
  local is_serwis = false

  for _, line in ipairs(lines) do
    if not line:match '^#' then
      local n_match = line:match '^Nazwa:%s*(.*)'
      if n_match then name = n_match:gsub('^%s+', ''):gsub('%s+$', '') end

      local s_match = line:match '^%-%s*(.*)'
      if s_match then
        local svc = s_match:gsub('^%s+', ''):gsub('%s+$', '')
        if svc ~= '' then table.insert(services, svc) end
      end

      -- ONLY mark as serwis if the buffer explicitly contains "Usługi:"!
      if line:match '^Usługi:' then is_serwis = true end
    end
  end

  return name, is_serwis, services
end

-- Interactive Controller: Edit Project details via floating text buffer
local function edit_project()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local map = ui.line_map[line]
  if not map or (map.type ~= 'day_header' and map.type ~= 'task') then
    vim.notify('agenda: Ustaw kursor na dniu lub zadaniu, aby edytować projekt/serwis.', vim.log.levels.WARN)
    return
  end

  local day_name = map.day_name
  local week_data = data.get_week(ui.current_monday)
  local day_data = week_data[day_name] or { projects = {} }

  if #day_data.projects == 1 and day_data.projects[1] == 'POZA DOMEM' then
    vim.notify('agenda: Nie można edytować statusu OUT OF HOME!', vim.log.levels.WARN)
    return
  end

  if #day_data.projects == 0 then
    vim.notify('agenda: Brak przypisanych projektów/serwisów do edycji na ten dzień!', vim.log.levels.WARN)
    return
  end

  local projects_db = data.get_projects()

  local function open_edit_buffer(proj_name)
    local proj = projects_db[proj_name]
    if not proj then return end

    -- create scratch edit buffer
    local edit_buf = vim.api.nvim_create_buf(false, true)

    local is_serwis = (proj.type == 'serwis')
    local type_label = is_serwis and 'serwisu' or 'projektu'

    vim.api.nvim_buf_set_name(edit_buf, 'Edycja ' .. type_label .. ' ' .. proj_name)
    vim.api.nvim_buf_set_option(edit_buf, 'buftype', 'acwrite')
    vim.api.nvim_buf_set_option(edit_buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(edit_buf, 'swapfile', false)

    local instructions = {
      '# Edycja ' .. type_label .. ': ' .. proj_name,
      "# Zmień nazwę po 'Nazwa: ' (maks. 30 znaków).",
      '# Edytuj ' .. (is_serwis and 'usługi' or 'podzadania') .. " dodając/zmieniając linie zaczynające się od '- '.",
      '# Wykonaj :w lub :wq, aby zapisać, albo :q!, aby anulować.',
      '',
      'Nazwa: ' .. proj_name,
    }

    -- Always append the tasks/services section
    table.insert(instructions, '')
    table.insert(instructions, is_serwis and 'Usługi:' or 'Podzadania:')

    local task_list = {}
    if is_serwis then
      task_list = proj.services or {}
    else
      -- normal project: load the day's tasks
      for _, t in ipairs(day_data.tasks or {}) do
        table.insert(task_list, t.text)
      end
    end

    for _, s in ipairs(task_list) do
      table.insert(instructions, '- ' .. s)
    end

    vim.api.nvim_buf_set_lines(edit_buf, 0, -1, false, instructions)

    -- calculate dimensions
    local width = 80
    local height = math.max(10, #instructions + 4)
    local edit_win = vim.api.nvim_open_win(edit_buf, true, {
      relative = 'editor',
      width = width,
      height = height,
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      border = 'rounded',
      style = 'minimal',
    })
    vim.api.nvim_win_set_option(edit_win, 'wrap', false)
    vim.api.nvim_win_set_option(edit_win, 'sidescrolloff', 0)
    vim.api.nvim_win_set_option(edit_win, 'number', true)
    vim.api.nvim_win_set_option(edit_win, 'relativenumber', false)
    vim.api.nvim_win_set_option(edit_win, 'statuscolumn', '')
    vim.api.nvim_win_set_option(edit_win, 'signcolumn', 'no')

    -- force options to persist after autocommands run
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(edit_win) then
        vim.api.nvim_win_set_option(edit_win, 'number', true)
        vim.api.nvim_win_set_option(edit_win, 'relativenumber', false)
        vim.api.nvim_win_set_option(edit_win, 'statuscolumn', '')
        vim.api.nvim_win_set_option(edit_win, 'signcolumn', 'no')
      end
    end)

    -- for buffer writing
    vim.api.nvim_create_autocmd('BufWriteCmd', {
      buffer = edit_buf,
      callback = function()
        local name, is_now_serwis, services = parse_edit_buffer(edit_buf)
        if not name or name == '' then
          vim.notify('agenda: Nazwa nie może być pusta!', vim.log.levels.ERROR)
          return
        end

        name = name:sub(1, 30) -- cap at 30 chars

        local updated_details = { icon = proj.icon or '', color = proj.color or 'cyan' }
        if is_now_serwis then
          updated_details.type = 'serwis'
          updated_details.services = services
        end

        if name ~= proj_name then
          if projects_db[name] then
            vim.notify('agenda: Projekt/serwis o nazwie ' .. name .. ' już istnieje!', vim.log.levels.ERROR)
            return
          end
          data.save_project(name, updated_details)
          data.rename_project(proj_name, name)
        else
          data.save_project(proj_name, updated_details)
        end

        -- Update locally or globally depending on project type
        if is_now_serwis then
          data.get_week(ui.current_monday) -- healing alignment
        else
          local new_tasks = {}
          for _, text in ipairs(services) do
            local done = false
            for _, existing in ipairs(day_data.tasks or {}) do
              if existing.text == text then
                done = existing.done
                break
              end
            end
            table.insert(new_tasks, { text = text, done = done })
          end
          day_data.tasks = new_tasks
          data.save_week(ui.current_monday, week_data)
        end

        vim.notify('agenda: Zapisano ' .. type_label .. ': ' .. name, vim.log.levels.INFO)
        vim.api.nvim_buf_set_option(edit_buf, 'modified', false)
        pcall(vim.api.nvim_win_close, edit_win, true)

        ui.render(ui.current_monday)
      end,
    })

    -- map helper keys to quickly quit
    local map_opts = { silent = true, buffer = edit_buf, noremap = true }
    vim.keymap.set('n', 'q', ':q!<CR>', map_opts)
    vim.keymap.set('n', '<Esc>', ':q!<CR>', map_opts)
  end

  if #day_data.projects == 1 then
    open_edit_buffer(day_data.projects[1])
  else
    vim.ui.select(day_data.projects, {
      prompt = 'Wybierz do edycji:',
    }, function(choice)
      if choice then open_edit_buffer(choice) end
    end)
  end
end

-- Interactive Controller: Assign Projects to Day
local function reassign_projects()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local map = ui.line_map[line]
  if not map or (map.type ~= 'day_header' and map.type ~= 'task') then
    vim.notify('agenda: Ustaw kursor na dniu, aby przypisać projekty/serwisy.', vim.log.levels.WARN)
    return
  end

  local day_name = map.day_name
  local week_data = data.get_week(ui.current_monday)
  local projects_db = data.get_projects()

  -- create selection items
  local items = {}
  for p_name, p_details in pairs(projects_db) do
    local icon_str = (p_details.icon and p_details.icon ~= '') and (p_details.icon .. ' ') or ''
    table.insert(items, { text = icon_str .. p_name, value = p_name })
  end

  local function save_assignments(selected_vals)
    local final_projects = {}
    for _, val in ipairs(selected_vals) do
      table.insert(final_projects, val)
    end

    week_data[day_name].projects = final_projects
    data.save_week(ui.current_monday, week_data)

    data.get_week(ui.current_monday) -- self-healing
    ui.render(ui.current_monday)
    pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
  end

  if package.loaded['snacks'] and require('snacks').picker then
    require('snacks').picker.pick {
      items = items,
      layout = { preset = 'select' },
      format = function(item) return { { item.text, 'SnacksPickerLabel' } } end,
      confirm = function(picker, item)
        picker:close()
        local selected = picker:selected()
        local selected_vals = {}

        if #selected > 0 then
          for _, sel in ipairs(selected) do
            table.insert(selected_vals, sel.value)
          end
        elseif item then
          table.insert(selected_vals, item.value)
        end

        save_assignments(selected_vals)
      end,
    }
  else
    vim.ui.select(items, {
      prompt = 'Wybierz projekty/serwisy do przypisania:',
      format_item = function(item) return item.text end,
    }, function(choice)
      if not choice then return end
      save_assignments { choice.value }
    end)
  end
end

-- Interactive Controller: Shift Task or Day projects
local function shift_item()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local map = ui.line_map[line]
  if not map or (map.type ~= 'day_header' and map.type ~= 'task') then return end

  local week_data = data.get_week(ui.current_monday)
  local days = { 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday' }
  local day_polish =
    { Monday = 'Poniedziałek', Tuesday = 'Wtorek', Wednesday = 'Środa', Thursday = 'Czwartek', Friday = 'Piątek', Saturday = 'Sobota', Sunday = 'Niedziela' }

  local prompt_str = map.type == 'task' and 'Przenieś zadanie do dnia:'
    or 'Przenieś/Zamień projekty i zadania dnia ' .. day_polish[map.day_name] .. ' z dniem:'

  vim.ui.select(days, {
    prompt = prompt_str,
    format_item = function(day) return day_polish[day] end,
  }, function(target_day)
    if not target_day or target_day == map.day_name then return end

    if map.type == 'task' then
      local task = table.remove(week_data[map.day_name].tasks, map.task_idx)
      table.insert(week_data[target_day].tasks, task)
      data.save_week(ui.current_monday, week_data)

      data.get_week(ui.current_monday)
      ui.render(ui.current_monday)
      vim.notify('Przeniesiono zadanie do: ' .. day_polish[target_day], vim.log.levels.INFO)
    else
      local temp = week_data[map.day_name]
      week_data[map.day_name] = week_data[target_day]
      week_data[target_day] = temp
      data.save_week(ui.current_monday, week_data)

      data.get_week(ui.current_monday)
      ui.render(ui.current_monday)
      vim.notify('Zamieniono plany dni: ' .. day_polish[map.day_name] .. ' <-> ' .. day_polish[target_day], vim.log.levels.INFO)
    end
  end)
end

-- Interactive Controller: Toggle custom fold for day
local function toggle_fold()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local map = ui.line_map[line]
  if not map or not map.day_name then return end

  local key = ui.current_monday .. ':' .. map.day_name
  ui.collapsed_days[key] = not ui.collapsed_days[key]

  ui.render(ui.current_monday)

  -- restore cursor line
  local target_line = 1
  for l, m in pairs(ui.line_map) do
    if m.day_name == map.day_name then
      if map.type == 'day_header' and m.type == 'day_header' then
        target_line = l
        break
      elseif map.type == 'task' and m.type == 'task' and m.task_idx == map.task_idx then
        target_line = l
        break
      elseif map.type == 'task' and m.type == 'day_header' then
        target_line = l
      end
    end
  end
  pcall(vim.api.nvim_win_set_cursor, 0, { target_line, 0 })
end

-- Interactive Controller: Toggle OUT OF HOME (ZAJETY) status
local function toggle_out_of_home()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local map = ui.line_map[line]
  if not map or not map.day_name then
    vim.notify('agenda: Ustaw kursor na dniu lub zadaniu, aby wstawić status OUT OF HOME.', vim.log.levels.WARN)
    return
  end

  local day_name = map.day_name
  local week_data = data.get_week(ui.current_monday)
  local day_data = week_data[day_name] or { projects = {}, tasks = {} }

  local has_out_of_home = false
  for _, p_name in ipairs(day_data.projects or {}) do
    if p_name == 'POZA DOMEM' then
      has_out_of_home = true
      break
    end
  end

  local day_polish = {
    Monday = 'Poniedziałek',
    Tuesday = 'Wtorek',
    Wednesday = 'Środa',
    Thursday = 'Czwartek',
    Friday = 'Piątek',
    Saturday = 'Sobota',
    Sunday = 'Niedziela',
  }
  local polish_day = day_polish[day_name] or day_name

  if has_out_of_home then
    day_data.projects = {}
    day_data.tasks = {}
    vim.notify('agenda: Usunięto status OUT OF HOME dla dnia ' .. polish_day, vim.log.levels.INFO)
  else
    day_data.projects = { 'POZA DOMEM' }
    day_data.tasks = {}
    vim.notify('agenda: Ustawiono status OUT OF HOME dla dnia ' .. polish_day, vim.log.levels.INFO)
  end

  data.save_week(ui.current_monday, week_data)
  ui.render(ui.current_monday)
  pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
end

-- bind interactive actions to keys inside the buffer
function M.bind_buffer_keys(buf)
  local opts = { silent = true, buffer = buf }

  vim.keymap.set('n', 't', toggle_task, opts)
  vim.keymap.set('n', '<Space>', toggle_task, { silent = true, buffer = buf, nowait = true })
  vim.keymap.set('n', 'a', add_task, opts)
  vim.keymap.set('n', 'd', delete_task, opts)
  vim.keymap.set('n', 'x', delete_task, opts)
  vim.keymap.set('n', 'r', reassign_projects, opts)
  vim.keymap.set('n', 'p', add_project, opts)
  vim.keymap.set('n', 'e', edit_project, opts)
  vim.keymap.set('n', 's', shift_item, opts)
  vim.keymap.set('n', 'S', M.git_sync, opts)
  vim.keymap.set('n', 'zc', toggle_fold, opts)
  vim.keymap.set('n', 'o', toggle_out_of_home, opts)
end

return M
