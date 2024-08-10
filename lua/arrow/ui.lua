local M = {}

local config = require("arrow.config")
local git = require("arrow.git")
local persist = require("arrow.persist")
local utils = require("arrow.utils")

local fileNames = {}
local to_highlight = {}

local current_index = 0

local function max_mapping_length()
  local max_len = 0
  for _, mapping in pairs(config.mappings) do
    local len = string.len(mapping)
    if len > max_len then
      max_len = len
    end
  end
  return max_len
end

local function getActionsMenu()
  local mappings = config.mappings

  local pad = max_mapping_length()

  if #vim.g.arrow_filenames == 0 then
    return {
      string.format("%-" .. pad .. "s Save File", mappings.toggle),
    }
  end

  local already_saved = current_index > 0

  local separate_save_and_remove = config.separate_save_and_remove

  local return_mappings = {
    string.format("%" .. pad .. "s Edit Arrow File", mappings.edit),
    string.format("%" .. pad .. "s Clear All Items", mappings.clear_all_items),
    string.format("%" .. pad .. "s Delete mode", mappings.delete_mode),
    string.format("%" .. pad .. "s Open Vertical", mappings.open_vertical),
    string.format("%" .. pad .. "s Open Horizontal", mappings.open_horizontal),
    string.format("%" .. pad .. "s Next Item", mappings.next_item),
    string.format("%" .. pad .. "s Prev Item", mappings.prev_item),
    string.format("%" .. pad .. "s Quit", mappings.quit),
  }

  if separate_save_and_remove then
    table.insert(return_mappings, 1, string.format("%" .. pad .. "s Remove Current File", mappings.remove))
    table.insert(return_mappings, 1, string.format("%" .. pad .. "s Save Current File", mappings.toggle))
  else
    if already_saved == true then
      table.insert(return_mappings, 1, string.format("%" .. pad .. "s Remove Current File", mappings.toggle))
    else
      table.insert(return_mappings, 1, string.format("%" .. pad .. "s Save Current File", mappings.toggle))
    end
  end

  return return_mappings
end

local function format_file_names(file_names)
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
local function closeMenu()
  local win = vim.fn.win_getid()
  vim.api.nvim_win_close(win, true)
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

local function renderBuffer(buffer)
  vim.api.nvim_set_option_value("modifiable", true, { buf = buffer })

  local icons = config.show_icons
  local buf = buffer or vim.api.nvim_get_current_buf()
  local lines = { "" }

  local formattedFleNames = format_file_names(fileNames)

  to_highlight = {}
  current_index = 0

  for i, fileName in ipairs(formattedFleNames) do
    local displayIndex = config.index_keys:sub(i, i)

    vim.api.nvim_buf_add_highlight(buf, -1, "ArrowDeleteMode", i + 3, 0, -1)

    local parsed_filename = fileNames[i]

    if fileNames[i]:sub(1, 2) == "./" then
      parsed_filename = fileNames[i]:sub(3)
    end

    if parsed_filename == vim.b[buf].filename then
      current_index = i
    end

    vim.keymap.set("n", "" .. displayIndex, function()
      M.openFile(i)
    end, { noremap = true, silent = true, buffer = buf, nowait = true })

    if icons then
      local icon, hl_group = get_file_icon(fileNames[i])

      to_highlight[i] = hl_group

      fileName = icon .. " " .. fileName
    end

    table.insert(lines, string.format("   %s %s", displayIndex, fileName))
  end

  -- Add a separator
  if #vim.g.arrow_filenames == 0 then
    table.insert(lines, "   No files yet.")
  end

  table.insert(lines, "")

  local actionsMenu = getActionsMenu()

  -- Add actions to the menu
  if not config.hide_handbook then
    for _, action in ipairs(actionsMenu) do
      table.insert(lines, "   " .. action)
    end
  end

  table.insert(lines, "")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
end

-- Function to create the menu buffer with a list format
local function createMenuBuffer(filename)
  local buf = vim.api.nvim_create_buf(false, true)

  vim.b[buf].filename = filename
  vim.b[buf].arrow_current_mode = ""
  renderBuffer(buf)

  return buf
end

local function render_highlights(buffer)
  local actionsMenu = getActionsMenu()
  local mappings = config.mappings

  vim.api.nvim_buf_clear_namespace(buffer, -1, 0, -1)
  local menuBuf = buffer or vim.api.nvim_get_current_buf()

  vim.api.nvim_buf_add_highlight(menuBuf, -1, "ArrowCurrentFile", current_index, 0, -1)

  for i, _ in ipairs(fileNames) do
    if vim.b.arrow_current_mode == "delete_mode" then
      vim.api.nvim_buf_add_highlight(menuBuf, -1, "ArrowDeleteMode", i, 3, 4)
    else
      vim.api.nvim_buf_add_highlight(menuBuf, -1, "ArrowFileIndex", i, 3, 4)
    end
  end

  if config.show_icons then
    for k, v in pairs(to_highlight) do
      vim.api.nvim_buf_add_highlight(menuBuf, -1, v, k, 5, 8)
    end
  end

  local mapping_len = max_mapping_length()
  for i = #fileNames + 3, #fileNames + #actionsMenu + 3 do
    vim.api.nvim_buf_add_highlight(menuBuf, -1, "ArrowAction", i - 1, 3, 3 + mapping_len)
  end

  -- Find the line containing "d - Delete Mode"
  local deleteModeLine = -1
  local verticalModeLine = -1
  local horizontalModelLine = -1

  for i, action in ipairs(actionsMenu) do
    if action:find(mappings.delete_mode .. " Delete mode") then
      deleteModeLine = i - 1
    end

    if action:find(mappings.open_vertical .. " Open Vertical") then
      verticalModeLine = i - 1
    end

    if action:find(mappings.open_horizontal .. " Open Horizontal") then
      horizontalModelLine = i - 1
    end
  end

  if deleteModeLine >= 0 then
    if vim.b.arrow_current_mode == "delete_mode" then
      vim.api.nvim_buf_add_highlight(menuBuf, -1, "ArrowDeleteMode", #fileNames + deleteModeLine + 2, 0, -1)
    end
  end

  if verticalModeLine >= 0 then
    if vim.b.arrow_current_mode == "vertical_mode" then
      vim.api.nvim_buf_add_highlight(menuBuf, -1, "ArrowAction", #fileNames + verticalModeLine + 2, 0, -1)
    end
  end

  if horizontalModelLine >= 0 then
    if vim.b.arrow_current_mode == "horizontal_mode" then
      vim.api.nvim_buf_add_highlight(menuBuf, -1, "ArrowAction", #fileNames + horizontalModelLine + 2, 0, -1)
    end
  end

  local pattern = "%s%s%s%s%S.*$"
  local line_number = 1

  while line_number <= #fileNames + 1 do
    local line_content = vim.api.nvim_buf_get_lines(menuBuf, line_number - 1, line_number, false)[1]

    local match_start, match_end = string.find(line_content, pattern)
    if match_start and match_end then
      vim.api.nvim_buf_add_highlight(menuBuf, -1, "ArrowLocation", line_number - 1, match_start - 1, match_end)
    end

    line_number = line_number + 1
  end
end

-- Function to open the selected file
function M.openFile(fileNumber)
  local fileName = vim.g.arrow_filenames[fileNumber]

  if vim.b.arrow_current_mode == "delete_mode" then
    persist.remove(fileName)

    fileNames = vim.g.arrow_filenames

    renderBuffer(vim.api.nvim_get_current_buf())
    render_highlights(vim.api.nvim_get_current_buf())
  else
    if not fileName then
      print("Invalid file number")

      return
    end

    local action

    fileName = vim.fn.fnameescape(fileName)

    if vim.b.arrow_current_mode == "" or not vim.b.arrow_current_mode then
      action = config.open_action
    elseif vim.b.arrow_current_mode == "vertical_mode" then
      action = config.vertical_action
    elseif vim.b.arrow_current_mode == "horizontal_mode" then
      action = config.horizontal_action
    end

    closeMenu()

    action(fileName, vim.b.filename)
  end
end

function M.getWindowConfig()
  local show_handbook = not config.hide_handbook
  local parsedFileNames = format_file_names(fileNames)
  local separate_save_and_remove = config.separate_save_and_remove

  local max_width = 0
  if show_handbook then
    max_width = 13 + max_mapping_length() - 1
    if separate_save_and_remove then
      max_width = max_width + 2
    end
  end
  for _, v in pairs(parsedFileNames) do
    if #v > max_width then
      max_width = #v
    end
  end

  local width = max_width + 12
  local height = #fileNames + 2

  if show_handbook then
    height = height + 10
    if separate_save_and_remove then
      height = height + 1
    end
  end

  local current_config = {
    width = width,
    height = height,
    row = math.ceil((vim.o.lines - height) / 2),
    col = math.ceil((vim.o.columns - width) / 2),
  }

  local is_empty = #vim.g.arrow_filenames == 0

  if is_empty and show_handbook then
    current_config.height = 5
    current_config.width = 18
  elseif is_empty then
    current_config.height = 3
    current_config.width = 18
  end

  local res = vim.tbl_deep_extend("force", current_config, config.window)

  if res.width == "auto" then
    res.width = current_config.width
  end
  if res.height == "auto" then
    res.height = current_config.height
  end
  if res.row == "auto" then
    res.row = current_config.row
  end
  if res.col == "auto" then
    res.col = current_config.col
  end

  return res
end

---@type fun(bufnr?: integer)
function M.openMenu(bufnr)
  git.refresh_git_branch()

  local call_buffer = bufnr or vim.api.nvim_get_current_buf()

  if vim.g.arrow_filenames == 0 then
    persist.load_cache_file()
  end

  to_highlight = {}
  fileNames = vim.g.arrow_filenames
  local filename = utils.get_current_buffer_path()

  local menuBuf = createMenuBuffer(filename)

  local window_config = M.getWindowConfig()

  local win = vim.api.nvim_open_win(menuBuf, true, window_config)

  local mappings = config.mappings

  local separate_save_and_remove = config.separate_save_and_remove

  local menuKeymapOpts = { noremap = true, silent = true, buffer = menuBuf, nowait = true }

  vim.keymap.set("n", mappings.quit, closeMenu, menuKeymapOpts)
  vim.keymap.set("n", mappings.edit, function()
    closeMenu()
    persist.open_cache_file_editor()
  end, menuKeymapOpts)

  if separate_save_and_remove then
    vim.keymap.set("n", mappings.toggle, function()
      filename = filename or utils.get_current_buffer_path()

      persist.save(filename)
      closeMenu()
    end, menuKeymapOpts)

    vim.keymap.set("n", mappings.remove, function()
      filename = filename or utils.get_current_buffer_path()

      persist.remove(filename)
      closeMenu()
    end, menuKeymapOpts)
  else
    vim.keymap.set("n", mappings.toggle, function()
      persist.toggle(filename)
      closeMenu()
    end, menuKeymapOpts)
  end

  vim.keymap.set("n", mappings.clear_all_items, function()
    persist.clear()
    closeMenu()
  end, menuKeymapOpts)

  vim.keymap.set("n", mappings.next_item, function()
    closeMenu()
    persist.next()
  end, menuKeymapOpts)

  vim.keymap.set("n", mappings.prev_item, function()
    closeMenu()
    persist.previous()
  end, menuKeymapOpts)

  vim.keymap.set("n", "<Esc>", closeMenu, menuKeymapOpts)

  vim.keymap.set("n", mappings.delete_mode, function()
    if vim.b.arrow_current_mode == "delete_mode" then
      vim.b.arrow_current_mode = ""
    else
      vim.b.arrow_current_mode = "delete_mode"
    end

    renderBuffer(menuBuf)
    render_highlights(menuBuf)
  end, menuKeymapOpts)

  vim.keymap.set("n", mappings.open_vertical, function()
    if vim.b.arrow_current_mode == "vertical_mode" then
      vim.b.arrow_current_mode = ""
    else
      vim.b.arrow_current_mode = "vertical_mode"
    end

    renderBuffer(menuBuf)
    render_highlights(menuBuf)
  end, menuKeymapOpts)

  vim.keymap.set("n", mappings.open_horizontal, function()
    if vim.b.arrow_current_mode == "horizontal_mode" then
      vim.b.arrow_current_mode = ""
    else
      vim.b.arrow_current_mode = "horizontal_mode"
    end

    renderBuffer(menuBuf)
    render_highlights(menuBuf)
  end, menuKeymapOpts)

  vim.api.nvim_set_hl(0, "ArrowCursor", { nocombine = true, blend = 100 })
  vim.opt.guicursor:append("a:ArrowCursor/ArrowCursor")

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = 0,
    desc = "Disable Cursor",
    once = true,
    callback = function()
      current_index = 0

      vim.cmd("highlight clear ArrowCursor")
      vim.schedule(function()
        vim.opt.guicursor:remove("a:ArrowCursor/ArrowCursor")
      end)
    end,
  })

  -- disable cursorline for this buffer
  vim.wo.cursorline = false

  vim.api.nvim_set_current_win(win)

  render_highlights(menuBuf)
end

-- Command to trigger the menu
return M
