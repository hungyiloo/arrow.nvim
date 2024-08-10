local M = {}

M.show_icons = true
M.hide_handbook = false
M.separate_by_branch = false
M.separate_save_and_remove = false

M.window = {
  relative = "editor",
  width = "auto",
  height = "auto",
  row = "auto",
  col = "auto",
  style = "minimal",
  border = "single",
}

M.per_buffer_config = {
  lines = 4,
  sort_automatically = true,
  ---@type { enable: boolean, overlap: boolean, priority: integer } | nil
  satellite = nil,
  zindex = 50,
}

M.mappings = {
  edit = "e",
  delete_mode = "d",
  clear_all_items = "C",
  toggle = "s",
  open_vertical = "v",
  open_horizontal = "h",
  quit = "q",
  remove = "x",
  next_item = "]",
  prev_item = "[",
}

M.index_keys = "123456789zcbnmZXVBNM,afghjklAFGHJKLwrtyuiopWRTYUIOP"

---@type fun(target_file_name: string, current_file_name: string)
M.open_action = function(filename, _)
  vim.cmd(string.format(":edit %s", filename))
end

---@type fun(target_file_name: string, current_file_name: string)
M.vertical_action = function(filename, _)
  vim.cmd(string.format(":vsplit %s", filename))
end

---@type fun(target_file_name: string, current_file_name: string)
M.horizontal_action = function(filename, _)
  vim.cmd(string.format(":split %s", filename))
end

M.save_path = function()
  return vim.fn.stdpath("cache") .. "/arrow"
end

---@type fun(): string
M.save_key = function ()
  return vim.uv.cwd() or ""
end

return M
