local M = {}

local commands = require("arrow.commands")
local config = require("arrow.config")
local git = require("arrow.git")
local persist = require("arrow.persist")
local save_keys = require("arrow.save_keys")
local ui = require("arrow.ui")
local utils = require("arrow.utils")

function M.setup(opts)
  vim.cmd("highlight default link ArrowFileIndex CursorLineNr")
  vim.cmd("highlight default link ArrowCurrentFile SpecialChar")
  vim.cmd("highlight default link ArrowAction Character")
  vim.cmd("highlight default link ArrowLocation Comment")
  vim.cmd("highlight default link ArrowDeleteMode DiagnosticError")

  opts = opts or {}

  config.window = utils.join_two_keys_tables(config.window, opts.window or {})
  config.per_buffer_config = utils.join_two_keys_tables(config.per_buffer_config, opts.per_buffer_config or {})

  ---@type table<string, fun(target_file_name: string, current_file_name: string)>
  local actions = opts.custom_actions or {}
  config.open_action = actions.open or config.open_action
  config.vertical_action = actions.split_vertical or config.vertical_action
  config.horizontal_action = actions.split_horizontal or config.horizontal_action

  config.save_path = opts.save_path or config.save_path
  config.leader_key = opts.leader_key
  config.buffer_leader_key = opts.buffer_leader_key
  config.always_show_path = opts.always_show_path ~= nil and opts.always_show_path or config.always_show_path
  config.show_icons = opts.show_icons ~= nil and opts.show_icons or config.show_icons
  config.index_keys = opts.index_keys ~= nil and opts.index_keys or config.index_keys
  config.hide_handbook = opts.hide_handbook ~= nil and opts.hide_handbook or config.hide_handbook
  config.separate_by_branch = opts.separate_by_branch ~= nil and opts.separate_by_branch or config.separate_by_branch
  config.global_bookmarks = opts.global_bookmarks ~= nil and opts.global_bookmarks or config.global_bookmarks
  config.separate_save_and_remove = opts.separate_save_and_remove ~= nil and opts.separate_save_and_remove
    or config.separate_save_and_remove
  config.save_key = opts.save_key ~= nil and (save_keys[opts.save_key] or opts.save_key) or config.save_key

  if config.leader_key then
    vim.keymap.set("n", config.leader_key, ui.openMenu, { noremap = true, silent = true, nowait = true })
  end

  if config.buffer_leader_key then
    vim.keymap.set(
      "n",
      config.buffer_leader_key,
      require("arrow.buffer_ui").openMenu,
      { noremap = true, silent = true, nowait = true }
    )
  end

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
    desc = "load cache file on DirChanged",
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
