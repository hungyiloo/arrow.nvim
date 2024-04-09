local M = {}

local persist = require("arrow.persist")
local config = require("arrow.config")
local utils = require("arrow.utils")

local function show_right_index(index)
	return config.getState("index_keys"):sub(index, index)
end

end

function M.is_on_arrow_file(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local file_path
    local bufname = vim.fn.bufname(bufnr)
    if config.getState("global_bookmarks") == true then
        file_path = vim.fn.expand(bufname .. ":p")
    else
        file_path = utils.get_buffer_path(bufnr)
    end

    return persist.is_saved(file_path)
end

function M.text_for_statusline(index)
	index = index or M.in_on_arrow_file()

	if index then
		return show_right_index(index)
	else
		return ""
	end
end

function M.text_for_statusline_with_icons()
	local index = M.in_on_arrow_file()

	if index then
		return "󱡁 " .. show_right_index(index)
	else
		return ""
	end
end

return M
