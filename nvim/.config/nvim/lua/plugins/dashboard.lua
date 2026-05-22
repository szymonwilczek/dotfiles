return {
  'goolord/alpha-nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = 'VimEnter',
  config = function()
    local alpha = require 'alpha'

    local function get_theme_color(group)
      local hl = vim.api.nvim_get_hl(0, { name = group, link = true })
      local color = hl.fg or hl.foreground
      if color then return string.format('#%06x', color) end
      return '#cccccc'
    end

    local function setup_dynamic_colors()
      local theme_map = {
        red = 'DiagnosticError',
        green = 'String',
        blue = 'Special',
        yellow = 'DiagnosticWarn',
        orange = 'Number',
        pink = 'Keyword',
        cyan = 'Function',
        gray = 'Comment',
        brown = 'Constant',
        white = 'Normal',
      }

      for name, group in pairs(theme_map) do
        local hex = get_theme_color(group)
        vim.api.nvim_set_hl(0, 'AlphaColor' .. name, { fg = hex })
      end
    end

    setup_dynamic_colors()

    local function get_colored_banner()
      local banner_path = vim.fn.stdpath 'config' .. '/banners/'
      local banners = vim.fn.readdir(banner_path)
      if #banners == 0 then return { val = { 'Brak bannerów' }, hl = {} } end

      math.randomseed(os.clock() * 1000000000)
      local file = banner_path .. banners[math.random(#banners)]

      local lines = {}
      local hl_map = {}
      local tags = {
        ['[R]'] = 'AlphaColorred',
        ['[G]'] = 'AlphaColorgreen',
        ['[L]'] = 'AlphaColorblue',
        ['[Y]'] = 'AlphaColoryellow',
        ['[O]'] = 'AlphaColororange',
        ['[P]'] = 'AlphaColorpink',
        ['[C]'] = 'AlphaColorcyan',
        ['[A]'] = 'AlphaColorgray',
        ['[B]'] = 'AlphaColorbrown',
        ['[W]'] = 'AlphaColorwhite',
      }

      local f = io.open(file, 'r')
      if f then
        for raw_line in f:lines() do
          local clean_line = ''
          local line_hls = {}
          local current_hl = 'AlphaColorwhite'
          local current_start = 0
          local remaining = raw_line

          while remaining ~= '' do
            local first_s, first_e, first_tag = nil, nil, nil
            for tag, _ in pairs(tags) do
              local pat = tag:gsub('%[', '%%['):gsub('%]', '%%]')
              local s, e = remaining:find(pat)
              if s and (not first_s or s < first_s) then
                first_s, first_e, first_tag = s, e, tag
              end
            end

            if not first_s then
              clean_line = clean_line .. remaining
              if #clean_line > current_start then table.insert(line_hls, { current_hl, current_start, #clean_line }) end
              break
            end

            local before = remaining:sub(1, first_s - 1)
            clean_line = clean_line .. before
            if #clean_line > current_start then table.insert(line_hls, { current_hl, current_start, #clean_line }) end

            current_hl = tags[first_tag]
            current_start = #clean_line
            remaining = remaining:sub(first_e + 1)
          end

          if #line_hls == 0 then table.insert(line_hls, { 'AlphaColorwhite', 0, 0 }) end
          table.insert(lines, clean_line)
          table.insert(hl_map, line_hls)
        end
        f:close()
      end
      return { val = lines, hl = hl_map }
    end

    local banner_data = get_colored_banner()

    local function get_greeting()
      local hour = tonumber(os.date '%H')
      if hour >= 5 and hour < 14 then
        return '☀️ Good Morning'
      elseif hour >= 14 and hour < 18 then
        return '☕ Good Afternoon'
      elseif hour >= 18 and hour < 23 then
        return '🌙 Good Evening'
      else
        return '🦉 Night Mode...'
      end
    end

    local function draw_dashboard()
      local date_part = '󰸗 ' .. os.date '%d.%m.%Y'
      local separator = ' | '
      local time_part = '󱑒 ' .. os.date '%H:%M'

      local footer_text = date_part .. separator .. time_part

      local date_len = #date_part
      local sep_len = #separator
      local total_len = #footer_text

      alpha.setup {
        layout = {
          { type = 'padding', val = 8 },
          {
            type = 'text',
            val = banner_data.val,
            opts = { hl = banner_data.hl, position = 'center' },
          },
          { type = 'padding', val = 2 },
          {
            type = 'text',
            val = get_greeting(),
            opts = { hl = 'AlphaColoryellow', position = 'center' },
          },
          { type = 'padding', val = 2 },
          {
            type = 'text',
            val = footer_text,
            opts = {
              hl = {
                { 'AlphaColorgreen', 0, date_len },
                { 'AlphaColorgray', date_len, date_len + sep_len },
                { 'AlphaColorblue', date_len + sep_len, total_len },
              },
              position = 'center',
            },
          },
        },
        opts = {
          keymap = {
            press = {},
            queue_press = {},
          },
        },
      }
    end

    draw_dashboard()

    vim.api.nvim_create_autocmd('ColorScheme', {
      callback = function()
        setup_dynamic_colors()
        draw_dashboard()
      end,
    })
  end,
}
