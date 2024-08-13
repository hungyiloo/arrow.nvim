local M = {}

local buffer_persist = require("arrow.buffer_persist")
local commands = require("arrow.commands")
local config = require("arrow.config")
local git = require("arrow.git")
local persist = require("arrow.persist")
local save_keys = require("arrow.save_keys")
local utils = require("arrow.utils")

local function set_opt(opt, fallback)
  if opt ~= nil then
    return opt
  else
    return fallback
  end
end

function M.setup(opts)
  vim.cmd("highlight default link ArrowFileIndex CursorLineNr")
  vim.cmd("highlight default link ArrowCurrentFile Special")
  vim.cmd("highlight default link ArrowAction String")
  vim.cmd("highlight default link ArrowLocation Comment")
  vim.cmd("highlight default link ArrowDeleteMode Error")

  opts = opts or {}

  config.window = utils.join_two_keys_tables(config.window, opts.window or {})
  config.per_buffer_config = utils.join_two_keys_tables(config.per_buffer_config, opts.per_buffer_config or {})

  ---@type table<string, fun(target_file_name: string, current_file_name: string)>
  config.actions = utils.join_two_keys_tables(config.actions, opts.actions or {})

  config.save_path = set_opt(opts.save_path, config.save_path)
  config.always_show_path = set_opt(opts.always_show_path, config.always_show_path)
  config.show_icons = set_opt(opts.show_icons, config.show_icons)
  config.index_keys = set_opt(opts.index_keys, config.index_keys)
  config.show_cheatsheet = set_opt(opts.show_cheatsheet, config.show_cheatsheet)
  config.separate_by_branch = set_opt(opts.separate_by_branch, config.separate_by_branch)
  config.separate_save_and_remove = set_opt(opts.separate_save_and_remove, config.separate_save_and_remove)
  config.save_key = set_opt((save_keys[opts.save_key] or opts.save_key), config.save_key)

  if config.per_buffer_config.satellite then
    require("arrow.integration.satellite")
  end

  config.mappings = utils.join_two_keys_tables(config.mappings, opts.mappings or {})

  persist.load_cache_file()

  vim.api.nvim_create_augroup("arrow", { clear = true })

  vim.api.nvim_create_autocmd({ "DirChanged", "SessionLoadPost" }, {
    callback = function()
      git.refresh_git_branch()
      persist.load_cache_file()
    end,
    desc = "load save list on directory change",
    group = "arrow",
  })

  vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    callback = function()
      buffer_persist.load_buffer_bookmarks()
    end,
    desc = "load current file bookmarks",
    group = "arrow",
  })

  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = "LazyLoad",
    callback = function(data)
      if data.data == "arrow.nvim" then
        for _, bufnr in pairs(vim.api.nvim_list_bufs()) do
          buffer_persist.load_buffer_bookmarks(bufnr)
        end
      end
    end,
    desc = "load all open buffer bookmarks on lazy load",
    group = "arrow",
  })

  commands.setup()
end

M.open = commands.commands.open
M.next_buffer = commands.commands.next_buffer
M.prev_buffer = commands.commands.prev_buffer
M.save_current_buffer = commands.commands.save_current_buffer

M.open_bookmarks = commands.commands.open_bookmarks
M.next_bookmark = commands.commands.next_bookmark
M.prev_bookmark = commands.commands.prev_bookmark
M.bookmark_current_line = commands.commands.bookmark_current_line

return M
