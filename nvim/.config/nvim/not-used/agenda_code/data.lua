local M = {}

M.config = {
  data_dir = vim.fn.stdpath 'config' .. '/agenda',
  projects_file = nil,
  schedule_file = nil,
}

M.projects_cache = nil
M.schedule_cache = nil

local uv = vim.loop or vim.uv
local timers = {}

local function ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then vim.fn.mkdir(path, 'p') end
end

local function save_json_debounced(file_path, tbl)
  if not timers[file_path] then timers[file_path] = uv.new_timer() end
  local timer = timers[file_path]
  timer:stop()

  timer:start(
    50,
    0,
    vim.schedule_wrap(function()
      local ok, content = pcall(vim.json.encode, tbl)
      if not ok then
        vim.notify('agenda: Error encoding table to JSON', vim.log.levels.ERROR)
        return
      end

      uv.fs_open(file_path, 'w', 438, function(err, fd)
        if err then return end
        uv.fs_write(fd, content, 0, function() uv.fs_close(fd) end)
      end)
    end)
  )
  return true
end

-- initialize data layer with optional config overrides
function M.setup(opts)
  opts = opts or {}
  if opts.data_dir then M.config.data_dir = opts.data_dir end
  ensure_dir(M.config.data_dir)

  M.config.projects_file = M.config.data_dir .. '/projects.json'
  M.config.schedule_file = M.config.data_dir .. '/schedule.json'

  -- if database files dont exist, write defaults
  if vim.fn.filereadable(M.config.projects_file) == 0 then
    local default_projects = {
      LOTA = { icon = '', color = 'cyan' },
      GK = { icon = '', color = 'blue' },
      ['Serwis: Skrecior, arete, tmux-jot'] = {
        icon = '',
        color = 'orange',
        type = 'serwis',
        services = { 'skrecior', 'arete', 'tmux-jot' },
      },
      arete = { icon = '', color = 'magenta' },
      ['tmux-jot'] = { icon = '', color = 'green' },
    }
    -- write synchronously first time during setup
    local content = vim.json.encode(default_projects)
    local f = io.open(M.config.projects_file, 'w')
    if f then
      f:write(content)
      f:close()
    end
  end

  if vim.fn.filereadable(M.config.schedule_file) == 0 then
    local f = io.open(M.config.schedule_file, 'w')
    if f then
      f:write '{}'
      f:close()
    end
  end

  -- force reload
  M.projects_cache = nil
  M.schedule_cache = nil
end

function M.load_json(file_path)
  local f = io.open(file_path, 'r')
  if not f then return nil end
  local content = f:read '*all'
  f:close()
  if content == '' then return {} end
  local ok, res = pcall(vim.json.decode, content)
  if not ok then
    vim.notify('agenda: Error decoding ' .. file_path .. ': ' .. tostring(res), vim.log.levels.ERROR)
    return {}
  end
  return res
end

function M.get_monday_date(time)
  local t = os.date('*t', time or os.time())
  t.hour = 12
  t.min = 0
  t.sec = 0
  local noon_time = os.time(t)
  local iso_wday = (t.wday == 1) and 7 or (t.wday - 1)
  local monday_time = noon_time - (iso_wday - 1) * 86400
  return os.date('%Y-%m-%d', monday_time)
end

-- shift Monday date string by offset_weeks
function M.shift_week(monday_str, offset_weeks)
  local y, m, d = monday_str:match '(%d+)-(%d+)-(%d+)'
  if not y or not m or not d then return M.get_monday_date() end
  local time = os.time { year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12, min = 0, sec = 0 }
  local shifted_time = time + offset_weeks * 7 * 86400
  return os.date('%Y-%m-%d', shifted_time)
end

function M.get_projects()
  if not M.projects_cache then M.projects_cache = M.load_json(M.config.projects_file) or {} end
  return M.projects_cache
end

function M.save_project(name, details)
  local projects = M.get_projects()
  projects[name] = details
  M.projects_cache = projects
  return save_json_debounced(M.config.projects_file, projects)
end

function M.get_week(monday_str)
  if not M.schedule_cache then M.schedule_cache = M.load_json(M.config.schedule_file) or {} end

  local schedule = M.schedule_cache
  local is_new = false
  if not schedule[monday_str] then
    schedule[monday_str] = {
      Monday = { projects = {}, tasks = {} },
      Tuesday = { projects = {}, tasks = {} },
      Wednesday = { projects = {}, tasks = {} },
      Thursday = { projects = {}, tasks = {} },
      Friday = { projects = {}, tasks = {} },
      Saturday = { projects = {}, tasks = {} },
      Sunday = { projects = {}, tasks = {} },
    }
    is_new = true
  end

  local week_data = schedule[monday_str]
  local projects_db = M.get_projects()
  local modified = is_new

  for _, day_data in pairs(week_data) do
    if type(day_data) == 'table' then
      day_data.projects = day_data.projects or {}
      day_data.tasks = day_data.tasks or {}

      -- check if day has a maintainence project
      local has_serwis = false
      local service_tasks = {}
      for _, p_name in ipairs(day_data.projects) do
        local proj = projects_db[p_name]
        if proj and proj.type == 'serwis' and proj.services then
          has_serwis = true
          for _, s_name in ipairs(proj.services) do
            local exists = false
            for _, t in ipairs(service_tasks) do
              if t.text == s_name then
                exists = true
                break
              end
            end
            if not exists then table.insert(service_tasks, { text = s_name, done = false }) end
          end
        end
      end

      if has_serwis then
        -- keep status of existing tasks that match, add new ones
        local new_tasks = {}
        for _, st in ipairs(service_tasks) do
          local found = nil
          for _, existing in ipairs(day_data.tasks) do
            if existing.text == st.text then
              found = existing
              break
            end
          end
          if found then
            table.insert(new_tasks, found)
          else
            table.insert(new_tasks, st)
            modified = true
          end
        end

        if #day_data.tasks ~= #new_tasks then modified = true end
        day_data.tasks = new_tasks
      else
        -- no serwis projects, clear all tasks only if there are no projects at all
        if #day_data.projects == 0 and #day_data.tasks > 0 then
          day_data.tasks = {}
          modified = true
        end
      end
    end
  end

  if modified then
    schedule[monday_str] = week_data
    save_json_debounced(M.config.schedule_file, schedule)
  end

  return week_data
end

function M.save_week(monday_str, week_data)
  if not M.schedule_cache then M.schedule_cache = M.load_json(M.config.schedule_file) or {} end
  M.schedule_cache[monday_str] = week_data
  return save_json_debounced(M.config.schedule_file, M.schedule_cache)
end

function M.rename_project(old_name, new_name)
  if old_name == new_name then return end
  local projects = M.get_projects()
  if not projects[old_name] then return end

  -- copy details and delete old
  projects[new_name] = projects[old_name]
  projects[old_name] = nil
  M.projects_cache = projects
  save_json_debounced(M.config.projects_file, projects)

  -- update references in schedule.json
  if not M.schedule_cache then M.schedule_cache = M.load_json(M.config.schedule_file) or {} end
  local schedule = M.schedule_cache
  local modified = false
  for _, week_data in pairs(schedule) do
    if type(week_data) == 'table' then
      for _, day_data in pairs(week_data) do
        if type(day_data) == 'table' and day_data.projects then
          for idx, p_name in ipairs(day_data.projects) do
            if p_name == old_name then
              day_data.projects[idx] = new_name
              modified = true
            end
          end
        end
      end
    end
  end

  if modified then save_json_debounced(M.config.schedule_file, schedule) end
end

function M.delete_project(name)
  local projects = M.get_projects()
  if not projects[name] then return false end
  projects[name] = nil
  M.projects_cache = projects
  save_json_debounced(M.config.projects_file, projects)
  return true
end

return M
