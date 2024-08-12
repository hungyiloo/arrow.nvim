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
  ["Open Vertical"] = "v",
  ["Open Horizontal"] = "h",
  quit = "q",
  remove = "x",
  next_item = "]",
  prev_item = "[",
}

M.index_keys = "123456789zcbnmZXVBNM,afghjklAFGHJKLwrtyuiopWRTYUIOP"

---@type table<string, fun(target_file_name: string, current_file_name: string|nil)>
M.actions = {
  open = function(filename)
    vim.cmd("edit " .. filename)
  end,

  ["Open Vertical"] = function(filename)
    vim.cmd("vsplit " .. filename)
  end,

  ["Open Horizontal"] = function(filename)
    vim.cmd("vsplit " .. filename)
  end,
}

M.save_path = function()
  return vim.fn.stdpath("cache") .. "/arrow"
end

---@type fun(): string
M.save_key = function()
  return vim.uv.cwd() or ""
end

return M
