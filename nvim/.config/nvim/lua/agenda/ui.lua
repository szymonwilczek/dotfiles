local data = require 'agenda.data'

local M = {}

M.buf = nil
M.prev_buf = nil
M.current_monday = nil
M.line_map = {} -- maps 1-indexed buffer lines to actions/data

local ns_id = vim.api.nvim_create_namespace 'agenda_ui'

M.collapsed_days = {}

local function setup_highlights()
  vim.api.nvim_set_hl(0, 'AgendaColorCyan', { link = 'Special', default = true })
  vim.api.nvim_set_hl(0, 'AgendaColorBlue', { link = 'Function', default = true })
  vim.api.nvim_set_hl(0, 'AgendaColorOrange', { link = 'Number', default = true })
  vim.api.nvim_set_hl(0, 'AgendaColorMagenta', { link = 'Keyword', default = true })
  vim.api.nvim_set_hl(0, 'AgendaColorGreen', { link = 'String', default = true })
  vim.api.nvim_set_hl(0, 'AgendaColorRed', { link = 'DiagnosticError', default = true })
  vim.api.nvim_set_hl(0, 'AgendaColorGray', { link = 'Comment', default = true })

  vim.api.nvim_set_hl(0, 'AgendaCalendarHeader', { link = 'Type', default = true })
  vim.api.nvim_set_hl(0, 'AgendaCalendarSelectedWeek', { link = 'Visual', default = true })
  vim.api.nvim_set_hl(0, 'AgendaCalendarToday', { link = 'Search', default = true })

  vim.api.nvim_set_hl(0, 'AgendaHeader', { link = 'Title', default = true })
  vim.api.nvim_set_hl(0, 'AgendaDay', { link = 'Identifier', default = true })
  vim.api.nvim_set_hl(0, 'AgendaCompleted', { link = 'Comment', default = true })
  vim.api.nvim_set_hl(0, 'AgendaTodo', { link = 'Normal', default = true })
  vim.api.nvim_set_hl(0, 'AgendaCheckbox', { link = 'Character', default = true })
  vim.api.nvim_set_hl(0, 'AgendaProgress', { link = 'DiagnosticWarn', default = true })
end

local function make_progress_bar(done, total)
  if total == 0 then return '' end
  local pct = math.floor((done / total) * 100)
  local bar_len = 5
  local filled = math.min(bar_len, math.max(0, math.floor((done / total) * bar_len + 0.5)))
  local empty = bar_len - filled

  local filled_str = string.rep('█', filled)
  local empty_str = string.rep('░', empty)

  return string.format('[%s%s] %3d%%', filled_str, empty_str, pct)
end

-- word wrapping helper returning segments
local function wrap_task_segments(task, max_width)
  local checkbox = task.done and '    ' or '  󰄱  '
  local text = task.text

  -- checkbox takes 5 display columns
  local available_width = max_width - 6

  local words = {}
  for word in string.gmatch(text, '%S+') do
    table.insert(words, word)
  end

  if #words == 0 then
    return {
      {
        { text = checkbox, hl = 'AgendaCheckbox' },
        { text = '', hl = task.done and 'AgendaCompleted' or 'AgendaTodo' },
      },
    }
  end

  local wrapped_lines = {}
  local current_line = ''
  for _, word in ipairs(words) do
    if current_line == '' then
      current_line = word
    else
      local next_line = current_line .. ' ' .. word
      if vim.fn.strdisplaywidth(next_line) > available_width then
        table.insert(wrapped_lines, current_line)
        current_line = word
      else
        current_line = next_line
      end
    end
  end
  if current_line ~= '' then table.insert(wrapped_lines, current_line) end

  local result = {}
  -- First line has checkbox
  table.insert(result, {
    { text = checkbox, hl = 'AgendaCheckbox' },
    { text = wrapped_lines[1], hl = task.done and 'AgendaCompleted' or 'AgendaTodo' },
  })
  -- Subsequent lines indented
  for i = 2, #wrapped_lines do
    table.insert(result, {
      { text = '      ', hl = 'Comment' },
      { text = wrapped_lines[i], hl = task.done and 'AgendaCompleted' or 'AgendaTodo' },
    })
  end

  return result
end

-- Generate right-side panel segments (Calendar in Polish, Today, Upcoming)
local function build_right_side(monday_str, today_str, projects_db, week_data)
  local r_lines = {}
  local function add_r_line(segs) table.insert(r_lines, segs) end

  local y, m, d = monday_str:match '(%d+)-(%d+)-(%d+)'
  if not y then return {} end
  local year, month = tonumber(y), tonumber(m)

  local months = { 'STYCZEŃ', 'LUTY', 'MARZEC', 'KWIECIEŃ', 'MAJ', 'CZERWIEC', 'LIPIEC', 'SIERPIEŃ', 'WRZESIEŃ', 'PAŹDZIERNIK', 'LISTOPAD', 'GRUDZIEŃ' }
  local month_name = months[month] or 'MIESIĄC'

  -- title & header
  add_r_line { { text = string.format('%s %d', month_name, year), hl = 'AgendaHeader' } }
  add_r_line { { text = ' Pn Wt Śr Cz Pt So Nd', hl = 'AgendaCalendarHeader' } }

  local first_day_time = os.time { year = year, month = month, day = 1, hour = 12 }
  local wday = os.date('*t', first_day_time).wday
  local first_wday = (wday == 1) and 7 or (wday - 1)

  local num_days = os.date('*t', os.time { year = year, month = month + 1, day = 0 }).day

  local viewed_mon_time = os.time { year = year, month = month, day = tonumber(d), hour = 12 }
  local viewed_sun_time = viewed_mon_time + 6 * 86400
  local viewed_mon_str = os.date('%Y-%m-%d', viewed_mon_time)
  local viewed_sun_str = os.date('%Y-%m-%d', viewed_sun_time)

  local day_count = 0
  local row_segs = {}

  -- Pad before first day of month
  for i = 1, first_wday - 1 do
    table.insert(row_segs, { text = '   ' })
    day_count = day_count + 1
  end

  for day = 1, num_days do
    local day_str = string.format('%2d', day)
    local cur_date_str = string.format('%04d-%02d-%02d', year, month, day)

    local in_viewed_week = (cur_date_str >= viewed_mon_str and cur_date_str <= viewed_sun_str)
    local is_today = (cur_date_str == today_str)

    local hl = nil
    if in_viewed_week then
      hl = is_today and 'AgendaCalendarToday' or 'AgendaCalendarSelectedWeek'
    elseif is_today then
      hl = 'AgendaCalendarToday'
    end

    if hl == 'AgendaCalendarToday' then
      local space_hl = in_viewed_week and 'AgendaCalendarSelectedWeek' or nil
      if day < 10 then
        table.insert(row_segs, { text = ' ', hl = space_hl })
        table.insert(row_segs, { text = tostring(day), hl = hl })
        table.insert(row_segs, { text = ' ', hl = space_hl })
      else
        table.insert(row_segs, { text = tostring(day), hl = hl })
        table.insert(row_segs, { text = ' ', hl = space_hl })
      end
    elseif hl == 'AgendaCalendarSelectedWeek' then
      table.insert(row_segs, { text = day_str .. ' ', hl = hl })
    else
      table.insert(row_segs, { text = day_str .. ' ' })
    end
    day_count = day_count + 1

    if day_count % 7 == 0 or day == num_days then
      -- Trim trailing space for the last element in calendar row to prevent highlighting artifacts
      row_segs[#row_segs].text = row_segs[#row_segs].text:gsub('%s+$', '')
      add_r_line(row_segs)
      row_segs = {}
    end
  end

  -- Divider
  add_r_line { { text = '-------------------------', hl = 'AgendaColorGray' } }

  -- Today's Focus
  local english_days = { 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' }
  local day_polish_name =
    { Monday = 'Poniedziałek', Tuesday = 'Wtorek', Wednesday = 'Środa', Thursday = 'Czwartek', Friday = 'Piątek', Saturday = 'Sobota', Sunday = 'Niedziela' }
  local today_wday_name = english_days[tonumber(os.date '%w') + 1]
  local today_data = week_data[today_wday_name] or { projects = {}, tasks = {} }

  add_r_line { { text = 'DZISIAJ NA CELOWNIKU:', hl = 'AgendaHeader' } }

  local focus_hl = 'AgendaTodo'
  local focus_proj_parts = {}
  for _, p_name in ipairs(today_data.projects) do
    if p_name == 'POZA DOMEM' then
      table.insert(focus_proj_parts, p_name)
      focus_hl = 'AgendaColorRed'
    else
      local proj = projects_db[p_name] or { icon = '' }
      local prefix = (proj.icon and proj.icon ~= '') and (proj.icon .. ' ') or ''
      table.insert(focus_proj_parts, prefix .. p_name)
    end
  end
  local focus_proj_str = #focus_proj_parts > 0 and table.concat(focus_proj_parts, ', ') or '💤 REST / OPEN'
  add_r_line { { text = focus_proj_str, hl = #today_data.projects > 0 and focus_hl or 'AgendaColorGray' } }

  if #today_data.tasks > 0 then
    local active = 0
    for _, t in ipairs(today_data.tasks) do
      if not t.done then active = active + 1 end
    end

    local has_serwis = false
    for _, p_name in ipairs(today_data.projects) do
      local proj = projects_db[p_name]
      if proj and proj.type == 'serwis' then
        has_serwis = true
        break
      end
    end

    local label = has_serwis and 'Usługi' or 'Podzadania'
    add_r_line { { text = string.format('  %s: %d do zrobienia', label, active), hl = 'AgendaColorOrange' } }
  end

  add_r_line { { text = '' } }

  -- upcoming
  add_r_line { { text = 'NADCHODZĄCE:', hl = 'AgendaHeader' } }

  local now_time = os.time()
  for offset = 1, 2 do
    local u_time = now_time + offset * 86400
    local u_day_name = english_days[tonumber(os.date('%w', u_time)) + 1]
    local u_polish = day_polish_name[u_day_name] or u_day_name
    local u_week_monday = data.get_monday_date(u_time)
    local u_proj_str = '💤 REST / OPEN'

    local target_week_data = (u_week_monday == monday_str) and week_data or data.get_week(u_week_monday)
    local u_data = target_week_data[u_day_name]
    local u_hl = 'AgendaColorGray'
    if u_data then
      local parts = {}
      for _, p_name in ipairs(u_data.projects) do
        if p_name == 'POZA DOMEM' then
          table.insert(parts, p_name)
          u_hl = 'AgendaColorRed'
        else
          local proj = projects_db[p_name] or { icon = '' }
          local prefix = (proj.icon and proj.icon ~= '') and (proj.icon .. ' ') or ''
          table.insert(parts, prefix .. p_name)
        end
      end
      if #parts > 0 then u_proj_str = table.concat(parts, ', ') end
    end

    add_r_line { { text = string.format('- %s: %s', u_polish, u_proj_str), hl = u_hl } }
  end

  return r_lines
end

function M.render(monday_str)
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then return end

  M.current_monday = monday_str

  local week_data = data.get_week(monday_str)
  local projects_db = data.get_projects()
  local today_str = os.date '%Y-%m-%d'

  -- calculate width/responsiveness
  local win_width = vim.api.nvim_win_get_width(0)
  local show_calendar = (win_width >= 85)

  -- layout constraints
  local left_width = show_calendar and 65 or (win_width - 2)
  local total_width = show_calendar and 93 or 65

  local pad = 0
  if win_width > total_width then pad = math.floor((win_width - total_width) / 2) end
  local pad_str = string.rep(' ', pad)

  local buffer_lines = {}
  local highlights = {}
  M.line_map = {}

  -- dynamic segment-by-segment line builder to avoid byte/column offset issues
  local function build_line(left_segments, right_segments, map_data)
    local left_empty = true
    for _, seg in ipairs(left_segments or {}) do
      if seg.text and seg.text ~= '' then
        left_empty = false
        break
      end
    end

    local right_empty = true
    if right_segments then
      for _, seg in ipairs(right_segments) do
        if seg.text and seg.text ~= '' then
          right_empty = false
          break
        end
      end
    end

    if left_empty and right_empty then
      table.insert(buffer_lines, '')
      M.line_map[#buffer_lines] = map_data or { type = 'empty' }
      return
    end

    local line_idx = #buffer_lines
    local line_bytes = ''
    local left_display_width = 0

    -- apply screen centering padding
    if pad > 0 then
      line_bytes = line_bytes .. pad_str
      left_display_width = left_display_width + pad
    end

    -- append left segments
    for _, seg in ipairs(left_segments or {}) do
      local start_byte = #line_bytes
      line_bytes = line_bytes .. seg.text
      local end_byte = #line_bytes
      left_display_width = left_display_width + vim.fn.strdisplaywidth(seg.text)

      if seg.hl then table.insert(highlights, { line = line_idx, start = start_byte, finish = end_byte, hl = seg.hl }) end
    end

    -- pad left column to align columns
    local target_width = pad + left_width
    if left_display_width < target_width then
      local diff = target_width - left_display_width
      line_bytes = line_bytes .. string.rep(' ', diff)
    end

    -- merge separator & right column
    local full_line = line_bytes
    if show_calendar then
      local sep_start = #full_line
      full_line = full_line .. ' │ '
      table.insert(highlights, { line = line_idx, start = sep_start + 1, finish = sep_start + 2, hl = 'AgendaColorGray' })

      if right_segments then
        for _, seg in ipairs(right_segments) do
          local start_byte = #full_line
          full_line = full_line .. seg.text
          local end_byte = #full_line

          if seg.hl then table.insert(highlights, { line = line_idx, start = start_byte, finish = end_byte, hl = seg.hl }) end
        end
      end
    end

    -- trim trailing whitespace to comply with Neovim clean line standards
    full_line = full_line:gsub('%s+$', '')

    table.insert(buffer_lines, full_line)
    M.line_map[#buffer_lines] = map_data or { type = 'empty' }
  end

  -- pre-compile right side panels
  local right_lines = build_right_side(monday_str, today_str, projects_db, week_data)
  local right_line_idx = 1

  local function get_next_right_line()
    if show_calendar and right_line_idx <= #right_lines then
      local l = right_lines[right_line_idx]
      right_line_idx = right_line_idx + 1
      return l
    end
    return nil
  end

  -- render Header
  local y, m, d = monday_str:match '(%d+)-(%d+)-(%d+)'
  local start_time = os.time { year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 }
  local end_time = start_time + 6 * 86400

  local header_text = string.format('TYDZIEŃ %s (%s - %s)', os.date('%V', start_time), os.date('%d.%m', start_time), os.date('%d.%m', end_time))
  build_line({ { text = header_text, hl = 'AgendaHeader' } }, get_next_right_line(), { type = 'header' })
  build_line({ { text = string.rep('=', left_width), hl = 'AgendaColorGray' } }, get_next_right_line(), { type = 'divider' })

  -- render Left Days & Merge Right Columns
  local day_keys = { 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday' }
  local day_polish =
    { Monday = 'Poniedziałek', Tuesday = 'Wtorek', Wednesday = 'Środa', Thursday = 'Czwartek', Friday = 'Piątek', Saturday = 'Sobota', Sunday = 'Niedziela' }

  for _, day in ipairs(day_keys) do
    local day_data = week_data[day] or { projects = {}, tasks = {} }

    local name = day_polish[day]
    local name_display_w = vim.fn.strdisplaywidth(name)
    local name_pad = 12 - name_display_w
    local padded_name = name .. string.rep(' ', name_pad)

    local left_segs = {}
    table.insert(left_segs, { text = string.format('[%s] %s - ', day:sub(1, 1), padded_name), hl = 'AgendaDay' })

    if #day_data.projects == 0 then
      table.insert(left_segs, { text = '💤 REST / OPEN', hl = 'AgendaColorGray' })
    else
      for idx, p_name in ipairs(day_data.projects) do
        if p_name == 'POZA DOMEM' then
          table.insert(left_segs, { text = p_name, hl = 'AgendaColorRed' })
        else
          local proj = projects_db[p_name] or { icon = '', color = 'gray' }
          local color_hl = 'AgendaColor' .. (proj.color:sub(1, 1):upper() .. proj.color:sub(2))
          local prefix = (proj.icon and proj.icon ~= '') and (proj.icon .. ' ') or ''

          local is_collapsed = M.collapsed_days[monday_str .. ':' .. day] == true
          local arrow = ''
          if proj.type == 'serwis' or #day_data.tasks > 0 then arrow = is_collapsed and ' ' or ' ' end

          table.insert(left_segs, { text = prefix .. p_name .. arrow, hl = color_hl })
        end
        if idx < #day_data.projects then table.insert(left_segs, { text = ', ' }) end
      end
    end

    -- calculate tasks stats (if there are tasks)
    local total_tasks = #day_data.tasks
    if total_tasks > 0 then
      local done = 0
      for _, t in ipairs(day_data.tasks) do
        if t.done then done = done + 1 end
      end
      local progress_txt = make_progress_bar(done, total_tasks)
      local current_display_width = 0
      for _, s in ipairs(left_segs) do
        current_display_width = current_display_width + vim.fn.strdisplaywidth(s.text)
      end
      local bar_width = vim.fn.strdisplaywidth(progress_txt)
      local space_needed = left_width - current_display_width - bar_width
      if space_needed > 0 then table.insert(left_segs, { text = string.rep(' ', space_needed) }) end
      table.insert(left_segs, { text = progress_txt, hl = 'AgendaProgress' })
    end

    build_line(left_segs, get_next_right_line(), { type = 'day_header', day_name = day })

    -- wrap and render tasks
    local is_collapsed = M.collapsed_days[monday_str .. ':' .. day] == true
    if not is_collapsed then
      for idx, task in ipairs(day_data.tasks) do
        local wrapped = wrap_task_segments(task, left_width)
        for _, line_segs in ipairs(wrapped) do
          build_line(line_segs, get_next_right_line(), { type = 'task', day_name = day, task_idx = idx })
        end
      end
    end
  end

  -- consume remaining right-side lines if agenda column is shorter
  while right_line_idx <= #right_lines do
    build_line({}, get_next_right_line(), { type = 'empty' })
  end

  -- footer
  build_line({ { text = string.rep('-', left_width), hl = 'AgendaColorGray' } }, nil, { type = 'divider' })
  build_line({ { text = ' [q] Zamknij | [r] Przypisz | [e] Edytuj | [p] Dodaj Projekt' } }, nil, { type = 'legend' })
  build_line({ { text = ' [a] Dodaj Zadanie | [t/Spacja] Wykonaj | [x/d] Usuń Zadanie' } }, nil, { type = 'legend' })
  build_line({ { text = ' [<]/[>] Poprz/Nast Tydzień | [s] Przenieś | [zc] Zwiń Dzień' } }, nil, { type = 'legend' })
  build_line({ { text = ' [o] OUT OF HOME' } }, nil, { type = 'legend' })

  -- write lines to buffer
  vim.api.nvim_buf_set_option(M.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, buffer_lines)
  vim.api.nvim_buf_set_option(M.buf, 'modifiable', false)

  -- apply highlights
  vim.api.nvim_buf_clear_namespace(M.buf, ns_id, 0, -1)
  for _, hl in ipairs(highlights) do
    pcall(vim.api.nvim_buf_add_highlight, M.buf, ns_id, hl.hl, hl.line, hl.start, hl.finish)
  end
end

-- open the buffer window
function M.open(monday_str)
  M.prev_buf = vim.api.nvim_get_current_buf()

  -- find or create agenda buffer
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
    M.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(M.buf, 'Agenda Planner')
  end

  -- set buffer properties
  vim.api.nvim_buf_set_option(M.buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(M.buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(M.buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(M.buf, 'filetype', 'agenda')

  -- switch window
  vim.api.nvim_win_set_buf(0, M.buf)

  -- stylings
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'
  vim.wo.cursorline = true

  -- folding disabled
  vim.wo.foldmethod = 'manual'
  vim.wo.foldcolumn = '0'

  -- for responsiveness
  local augroup = vim.api.nvim_create_augroup('AgendaResize', { clear = true })
  vim.api.nvim_create_autocmd('VimResized', {
    group = augroup,
    buffer = M.buf,
    callback = function() M.render(M.current_monday) end,
  })

  M.bind_keys()
  setup_highlights()
  M.render(monday_str or data.get_monday_date())
end

function M.bind_keys()
  local opts = { silent = true, buffer = M.buf }

  -- quit
  vim.keymap.set('n', 'q', function()
    if M.prev_buf and vim.api.nvim_buf_is_valid(M.prev_buf) then
      vim.api.nvim_win_set_buf(0, M.prev_buf)
    else
      vim.cmd 'bd'
    end
  end, opts)

  -- prev / next Week navigation
  vim.keymap.set('n', '<', function()
    local prev_mon = data.shift_week(M.current_monday, -1)
    M.render(prev_mon)
  end, opts)
  vim.keymap.set('n', '[', function()
    local prev_mon = data.shift_week(M.current_monday, -1)
    M.render(prev_mon)
  end, opts)

  vim.keymap.set('n', '>', function()
    local next_mon = data.shift_week(M.current_monday, 1)
    M.render(next_mon)
  end, opts)
  vim.keymap.set('n', ']', function()
    local next_mon = data.shift_week(M.current_monday, 1)
    M.render(next_mon)
  end, opts)
end

return M
