local buffer_persist = require("arrow.buffer_persist")
local buffer_ui = require("arrow.buffer_ui")
local persist = require("arrow.persist")
local ui = require("arrow.ui")
local utils = require("arrow.utils")

local M = {}

function M.cmd(cmd, args)
  cmd = (cmd ~= nil and cmd ~= "") and cmd or "open"
  local command = M.commands[cmd]
  if command then
    command(unpack(args))
  else
    M.error("Unknown arrow command: " .. cmd, { title = "Arrow" })
  end
end

M.commands = {
  open = function(file_number) ---@type fun(file_number: string|integer|nil)
    file_number = tonumber(file_number)
    if file_number then
      ui.open_file(file_number)
    else
      ui.open_menu()
    end
  end,
  next_buffer = function()
    persist.next()
  end,
  prev_buffer = function()
    persist.previous()
  end,
  save_current_buffer = function()
    local filename = utils.get_current_buffer_path()
    persist.save(filename)
  end,
  open_bookmarks = function()
    buffer_ui.openMenu()
  end,
  next_bookmark = function()
    local cur_buffer = vim.api.nvim_get_current_buf()
    local cur_line = vim.api.nvim_win_get_cursor(0)[1]

    buffer_ui.next_item(cur_buffer, cur_line)
  end,
  prev_bookmark = function()
    local cur_buffer = vim.api.nvim_get_current_buf()
    local cur_line = vim.api.nvim_win_get_cursor(0)[1]

    buffer_ui.prev_item(cur_buffer, cur_line)
  end,
  bookmark_current_line = function()
    local cur_buffer = vim.api.nvim_get_current_buf()
    local cur_line = vim.api.nvim_win_get_cursor(0)[1]
    local cur_col = vim.api.nvim_win_get_cursor(0)[2]

    buffer_ui.toggle_line(cur_buffer, cur_line, cur_col)

    buffer_persist.update()
    buffer_persist.sync_buffer_bookmarks()
    buffer_persist.clear_buffer_ext_marks(cur_buffer)
    buffer_persist.redraw_bookmarks(cur_buffer, buffer_persist.get_bookmarks_by(cur_buffer))
  end,
}

function M.setup()
  vim.api.nvim_create_user_command("Arrow", function(cmd)
    local arrow_command, arrow_args = M.parse(cmd.args)
    M.cmd(arrow_command, arrow_args)
  end, {
    nargs = "?",
    desc = "Arrow",
    complete = function(_, line)
      local prefix = M.parse(line)
      return vim.tbl_filter(function(key)
        return key:find(prefix, 1, true) == 1
      end, vim.tbl_keys(M.commands))
    end,
  })
end

function M.parse(args)
  local parts = vim.split(vim.trim(args), "%s+")
  if parts[1]:find("Arrow") then
    table.remove(parts, 1)
  end
  if args:sub(-1) == " " then
    parts[#parts + 1] = ""
  end
  return table.remove(parts, 1) or "", parts
end

function M.error(msg, opts)
  opts = opts or {}
  opts.level = vim.log.levels.ERROR
  vim.notify(msg, opts)
end

return M
