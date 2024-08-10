local M = {}

local config = require("arrow.config")
local persist = require("arrow.persist")
local utils = require("arrow.utils")

local function show_right_index(index)
  return config.getState("index_keys"):sub(index, index)
end

function M.is_on_arrow_file(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local file_path = utils.get_buffer_path(bufnr)
  return persist.is_saved(file_path)
end

function M.text_for_statusline(bufnr, index)
  index = index or M.is_on_arrow_file(bufnr)

  if index then
    return show_right_index(index)
  else
    return ""
  end
end

function M.text_for_statusline_with_icons(bufnr)
  local index = M.is_on_arrow_file(bufnr)

  if index then
    return "󱡁 " .. show_right_index(index)
  else
    return ""
  end
end

return M
