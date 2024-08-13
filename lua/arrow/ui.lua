local config = require("arrow.config")
local git = require("arrow.git")
local persist = require("arrow.persist")
local utils = require("arrow.utils")

local M = {}

local PADDING = 3

-- The buffer number that was open when Arrow was opened
local caller_buf = nil ---@type integer|nil

-- The buffer containing the Arrow menu UI.
-- If nil, the menu isn't open
local menu_buf = nil ---@type integer|nil

-- The currently selected action (which is performed when a file is opened).
-- If nil, the default action (open) will be performed
local selected_action = nil ---@type string|nil

local function max_mapping_key_length()
  local max_len = 0
  for _, mapping_key in pairs(config.mappings) do
    local len = string.len(mapping_key)
    if len > max_len then
      max_len = len
    end
  end
  return max_len
end

-- Gets the caller buffer file index in the arrow save list,
-- returns 0 if the caller buffer file isn't in the save list
local function caller_current_index()
  if not caller_buf then
    return 0
  end
  for i, filename in pairs(persist.filenames) do
    if utils.get_buffer_path(caller_buf) == filename then
      return i
    end
  end
  return 0
end

local function get_actions_menu()
  local mappings = config.mappings

  local pad = max_mapping_key_length()

  if #persist.filenames == 0 then
    return {
      string.format("%-" .. pad .. "s Save File", mappings.toggle),
    }
  end

  local already_saved = caller_current_index() > 0

  local separate_save_and_remove = config.separate_save_and_remove

  local menu_lines = {
    string.format("%" .. pad .. "s Edit Arrow File", mappings.edit),
    string.format("%" .. pad .. "s Clear All Items", mappings.clear_all_items),
    string.format("%" .. pad .. "s Delete mode", mappings.delete_mode),
    string.format("%" .. pad .. "s Next Item", mappings.next_item),
    string.format("%" .. pad .. "s Prev Item", mappings.prev_item),
    string.format("%" .. pad .. "s Toggle Cheatsheet", mappings.toggle_cheatsheet),
    string.format("%" .. pad .. "s Quit", mappings.quit),
  }

  for action_name, _ in pairs(config.actions) do
    local action_key = mappings[action_name]
    if action_key and action_name ~= "open" then
      table.insert(menu_lines, 4, string.format("%" .. pad .. "s " .. action_name, action_key))
    end
  end

  if separate_save_and_remove then
    table.insert(menu_lines, 1, string.format("%" .. pad .. "s Remove Current File", mappings.remove))
    table.insert(menu_lines, 1, string.format("%" .. pad .. "s Save Current File", mappings.toggle))
  else
    if already_saved == true then
      table.insert(menu_lines, 1, string.format("%" .. pad .. "s Remove Current File", mappings.toggle))
    else
      table.insert(menu_lines, 1, string.format("%" .. pad .. "s Save Current File", mappings.toggle))
    end
  end

  return menu_lines
end

local function format_filenames(file_names)
  local formatted_names = {}

  -- Table to count occurrences of file names
  local name_occurrences = {}

  local function get_file_name(full_path)
    local file_name = vim.fn.fnamemodify(full_path, ":t")
    if file_name == "" then
      file_name = full_path
    end
    return file_name
  end

  for _, full_path in ipairs(file_names) do
    local file_name = get_file_name(full_path)
    name_occurrences[file_name] = (name_occurrences[file_name] or 0) + 1
  end

  for _, full_path in ipairs(file_names) do
    local file_name = get_file_name(full_path)
    local dir_name = vim.fn.fnamemodify(full_path, ":h")
    if file_name ~= full_path and (name_occurrences[file_name] > 1 or config.always_show_path) then
      table.insert(formatted_names, string.format("%s    %s", file_name, dir_name))
    else
      table.insert(formatted_names, string.format("%s", file_name))
    end
  end

  return formatted_names
end

-- Function to close the menu and open the selected file
function M.close_menu()
  if menu_buf then
    local win = vim.fn.win_getid()
    vim.api.nvim_win_close(win, true)
    menu_buf = nil
  end
end

local function get_file_icon(file_name)
  if vim.fn.isdirectory(file_name) == 1 then
    return "", "Normal"
  end

  local webdevicons = require("nvim-web-devicons")
  local extension = vim.fn.fnamemodify(file_name, ":e")
  local icon, hl_group = webdevicons.get_icon(file_name, extension, { default = true })
  return icon, hl_group
end

local function get_filenames_menu()
  local icons = config.show_icons
  local lines = {}
  local to_highlight = {}

  local formatted_filenames = format_filenames(persist.filenames)

  for i, file_name in ipairs(formatted_filenames) do
    local index_key = config.index_keys:sub(i, i)

    if icons then
      local icon, hl_group = get_file_icon(persist.filenames[i])
      to_highlight[i] = hl_group
      file_name = icon .. " " .. file_name
    end

    table.insert(lines, string.format("%s %s", index_key, file_name))
  end

  if #persist.filenames == 0 then
    table.insert(lines, "No files yet.")
  end

  return lines, to_highlight
end

local function render_highlights(to_highlight)
  if not menu_buf then
    return
  end

  local actions_menu = get_actions_menu()
  local mappings = config.mappings

  vim.api.nvim_buf_clear_namespace(menu_buf, -1, 0, -1)
  vim.api.nvim_buf_add_highlight(menu_buf, -1, "ArrowCurrentFile", caller_current_index(), 0, -1)

  for i, _ in ipairs(persist.filenames) do
    if selected_action == "delete_mode" then
      vim.api.nvim_buf_add_highlight(menu_buf, -1, "ArrowDeleteMode", i, PADDING, PADDING + #mappings.delete_mode)
    else
      vim.api.nvim_buf_add_highlight(menu_buf, -1, "ArrowFileIndex", i, PADDING, PADDING + #mappings.delete_mode)
    end
  end

  if config.show_icons then
    for k, v in pairs(to_highlight) do
      vim.api.nvim_buf_add_highlight(menu_buf, -1, v, k, 5, 8)
    end
  end

  local mapping_len = max_mapping_key_length()
  for i = #persist.filenames, #persist.filenames + #actions_menu do
    vim.api.nvim_buf_add_highlight(menu_buf, -1, "ArrowAction", i + 2, PADDING, PADDING + mapping_len)
  end

  if selected_action == "delete_mode" then
    for i, action in ipairs(actions_menu) do
      if action:find(mappings.delete_mode .. " Delete mode") then
        local deleteModeLine = i - 1
        vim.api.nvim_buf_add_highlight(
          menu_buf,
          -1,
          "ArrowDeleteMode",
          #persist.filenames + deleteModeLine + 2,
          0,
          -1
        )
      end
    end
  elseif selected_action ~= nil and selected_action ~= "" then
    -- if we're in an action mode, look for the matching action line and highlight it
    local matching_action = config.actions[selected_action]
    local matching_mapping = mappings[selected_action]
    if matching_action and matching_mapping then
      for i, action in ipairs(actions_menu) do
        if action:find(matching_mapping .. " " .. selected_action) then
          local action_line = i - 1
          vim.api.nvim_buf_add_highlight(menu_buf, -1, "ArrowAction", #persist.filenames + action_line + 2, 0, -1)
        end
      end
    end
  end

  local pattern = "%s%s%s%s%S.*$"
  local line_number = 1

  while line_number <= #persist.filenames + 1 do
    local line_content = vim.api.nvim_buf_get_lines(menu_buf, line_number - 1, line_number, false)[1]

    local match_start, match_end = string.find(line_content, pattern)
    if match_start and match_end then
      vim.api.nvim_buf_add_highlight(menu_buf, -1, "ArrowLocation", line_number - 1, match_start - 1, match_end)
    end

    line_number = line_number + 1
  end
end

local function render_buffer()
  if not menu_buf then
    return
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = menu_buf })

  -- Start building the buffer lines to render
  local lines = { "" }
  local filenames_menu, filename_highlights = get_filenames_menu()
  local actions_menu = get_actions_menu()

  -- Add filenames to the menu
  for _, filename in ipairs(filenames_menu) do
    table.insert(lines, string.rep(" ", PADDING) .. filename)
  end

  -- Add a separator
  table.insert(lines, "")

  -- Add actions to the menu
  if config.show_cheatsheet then
    for _, action in ipairs(actions_menu) do
      table.insert(lines, string.rep(" ", PADDING) .. action)
    end
  end

  table.insert(lines, "")

  vim.api.nvim_buf_set_lines(menu_buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = menu_buf })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = menu_buf })

  -- set filename keymaps
  for i, filename in pairs(filenames_menu) do
    local index_key = filename:sub(1, 1)
    vim.keymap.set("n", index_key, function()
      M.open_file(i)
    end, { noremap = true, silent = true, buffer = menu_buf, nowait = true })
  end

  render_highlights(filename_highlights)
end

local function create_menu_buffer()
  menu_buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = menu_buf,
    desc = "Disable cursor after entering Arrow",
    callback = function()
      vim.api.nvim_set_hl(0, "ArrowCursor", { nocombine = true, blend = 100 })
      vim.opt.guicursor:append("a:ArrowCursor/ArrowCursor")
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = menu_buf,
    desc = "Reenable cursor after leaving Arrow",
    callback = function()
      M.close_menu()
      vim.cmd("highlight clear ArrowCursor")
      vim.schedule(function()
        vim.opt.guicursor:remove("a:ArrowCursor/ArrowCursor")
      end)
    end,
  })

  selected_action = nil
  render_buffer(menu_buf)

  return menu_buf
end

-- handles user selection of a file in the arrow save list
function M.open_file(file_number)
  local filename = persist.filenames[file_number]

  if selected_action == "delete_mode" then
    persist.remove(filename)
    render_buffer(vim.api.nvim_get_current_buf())
  else
    if not filename then
      print("Invalid file number")
      return
    end

    local action
    filename = vim.fn.fnameescape(filename)

    if selected_action == "" or not selected_action then
      action = config.actions.open
    else
      action = config.actions[selected_action]
    end

    local caller_filename = utils.get_buffer_path(caller_buf)
    M.close_menu()
    action(filename, caller_filename)
  end
end

function M.get_window_config()
  -- Calculate the width of the window based on the max length of the
  -- filenames and the max length of the actions menu lines
  local width = 0
  local actions_menu = get_actions_menu()
  for _, actions_menu_line in pairs(actions_menu) do
    if #actions_menu_line > width then
      width = #actions_menu_line
    end
  end

  local filenames_menu = get_filenames_menu()
  for _, filename in pairs(filenames_menu) do
    if #filename - PADDING > width then
      -- why do we need to subtract window_padding here?
      -- if we don't, filenames are double padded on the right hand side (?!)
      width = #filename - PADDING
    end
  end
  width = width + PADDING * 2 -- add some padding

  local height = math.max(3, #persist.filenames + 2)
  if config.show_cheatsheet then
    height = height + 1 + #actions_menu
  end

  local auto_window = {
    width = width,
    height = height,
    row = math.ceil((vim.o.lines - height) / 2),
    col = math.ceil((vim.o.columns - width) / 2),
  }

  local res = vim.tbl_deep_extend("force", auto_window, config.window)

  if res.width == "auto" then
    res.width = auto_window.width
  end
  if res.height == "auto" then
    res.height = auto_window.height
  end
  if res.row == "auto" then
    res.row = auto_window.row
  end
  if res.col == "auto" then
    res.col = auto_window.col
  end

  return res
end

---@type fun(bufnr?: integer)
function M.open_menu(bufnr)
  if menu_buf then
    return
  end

  git.refresh_git_branch()
  caller_buf = bufnr or vim.api.nvim_get_current_buf()

  if persist.filenames == 0 then
    persist.load_cache_file()
  end

  local filename = utils.get_buffer_path(caller_buf)
  menu_buf = create_menu_buffer()
  local window_config = M.get_window_config()
  local win = vim.api.nvim_open_win(menu_buf, true, window_config)

  local mappings = config.mappings
  local separate_save_and_remove = config.separate_save_and_remove
  local menu_keymap_opts = { noremap = true, silent = true, buffer = menu_buf, nowait = true }

  vim.keymap.set("n", mappings.quit, M.close_menu, menu_keymap_opts)
  vim.keymap.set("n", mappings.toggle_cheatsheet, M.toggle_cheatsheet, menu_keymap_opts)
  vim.keymap.set("n", mappings.edit, function()
    M.close_menu()
    persist.open_cache_file_editor()
  end, menu_keymap_opts)

  if separate_save_and_remove then
    vim.keymap.set("n", mappings.toggle, function()
      persist.save(filename)
      M.close_menu()
    end, menu_keymap_opts)

    vim.keymap.set("n", mappings.remove, function()
      persist.remove(filename)
      M.close_menu()
    end, menu_keymap_opts)
  else
    vim.keymap.set("n", mappings.toggle, function()
      persist.toggle(filename)
      M.close_menu()
    end, menu_keymap_opts)
  end

  vim.keymap.set("n", mappings.clear_all_items, function()
    persist.clear()
    M.close_menu()
  end, menu_keymap_opts)

  vim.keymap.set("n", mappings.next_item, function()
    M.close_menu()
    persist.next()
  end, menu_keymap_opts)

  vim.keymap.set("n", mappings.prev_item, function()
    M.close_menu()
    persist.previous()
  end, menu_keymap_opts)

  vim.keymap.set("n", "<Esc>", M.close_menu, menu_keymap_opts)

  vim.keymap.set("n", mappings.delete_mode, function()
    if selected_action == "delete_mode" then
      selected_action = ""
    else
      selected_action = "delete_mode"
    end

    render_buffer(menu_buf)
  end, menu_keymap_opts)

  for mapping_name, mapping_key in pairs(mappings) do
    if config.actions[mapping_name] then
      vim.keymap.set("n", mapping_key, function()
        if selected_action == mapping_name then
          selected_action = ""
        else
          selected_action = mapping_name
        end

        render_buffer(menu_buf)
      end, menu_keymap_opts)
    end
  end

  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = menu_buf,
    desc = "Cleanup Arrow state after closing UI",
    once = true,
    callback = function()
      menu_buf = nil
      caller_buf = nil
    end,
  })

  -- disable cursorline for this buffer
  vim.wo.cursorline = false

  vim.api.nvim_set_current_win(win)
end

function M.toggle_cheatsheet()
  config.show_cheatsheet = not config.show_cheatsheet

  -- we can't just rerender, because the window size might change
  M.close_menu()
  vim.schedule(function()
    M.open_menu()
  end)
end

return M
