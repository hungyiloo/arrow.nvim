# arrow.nvim

> [!WARNING] 
> A wild fork has appeared!
> This is a personal fork of the original [arrow.nvim](https://github.com/otavioschwanck/arrow.nvim). To fix Windows compatibility and a whole raft of bugs, I made sweeping changes

Arrow.nvim is a plugin made to quickly locate files (like harpoon) using a single UI and single keymap. 

Arrow is highly customizable.

Arrow also provides per buffer bookmarks that let you quickly jump around a file. (Their positions are automatically updated/persisted while you modify the file)

### Per Project / Global bookmarks:
![arrow.nvim](https://i.imgur.com/mPdSC5s.png)
![arrow.nvim_gif](https://i.imgur.com/LcvG406.gif)
![arrow_buffers](https://i.imgur.com/Lll9YvY.gif)

## Installation

### Lazy

```lua
return {
  "hungyiloo/arrow.nvim",
  opts = {
    show_icons = true,
  },
  cmd = "Arrow",
  keys = {
    { mode = "n", "<leader>h", function() require("arrow").open() end, desc = "Arrow", nowait = true },
    { mode = "n", "<leader>m", function() require("arrow").open_bookmarks() end, desc = "Arrow Buffer Bookmarks", nowait = true },
  }
}
```

## Usage

Map `function() require("arrow").open() end` or `"<cmd>Arrow<cr>"` to a key of your choice to open Arrow.

For in-buffer bookmarks, map `function() require("arrow").open_bookmarks() end` or `"<cmd>Arrow open_bookmarks<cr>"`.

## Compared with Harpoon

- Only a single keymap needed to access the save list
- A more beautiful UI to manage the save list
- Status line helpers to integrate with other areas of Neovim
- Show only the filename (only shows full path when ambiguous)
- Pretty colors and icons
- A delete mode to quickly delete items
- Files can be opened easily in vertical or horizontal splits
- You can still edit the save list file directly

## Advanced Setup

```lua
{
  show_icons = true,
  always_show_path = false,
  separate_by_branch = false, -- Bookmarks will be separated by git branch
  hide_handbook = false, -- set to true to hide the shortcuts on menu.
  save_path = function()
    return vim.fn.stdpath("cache") .. "/arrow"
  end,
  mappings = {
    edit = "e",
    delete_mode = "d",
    clear_all_items = "C",
    toggle = "s", -- used as save if separate_save_and_remove is true
    quit = "q",
    remove = "x", -- only used if separate_save_and_remove is true
    next_item = "]",
    prev_item = "["

    -- custom actions mappings; names must match actions defined below
    ["Open Vertical"] = "v",
    ["Open Horizontal"] = "h",
  },
  actions = {
    -- the default file open action can be overridden
    open = function(filename)
      vim.cmd("edit " .. filename)
    end,

    -- custom actions are defined like this
    ["Open Vertical"] = function(filename)
      vim.cmd("vsplit " .. filename)
    end,

    ["Open Horizontal"] = function(filename)
      vim.cmd("vsplit " .. filename)
    end,
  },
  window = { -- controls the appearance and position of an arrow window (see nvim_open_win() for all options)
    width = "auto",
    height = "auto",
    row = "auto",
    col = "auto",
    border = "double",
  },
  per_buffer_config = {
    lines = 4, -- Number of lines showed on preview.
    sort_automatically = true, -- Auto sort buffer marks.
    satellite = { -- default to nil, display arrow index in scrollbar at every update
      enable = false,
      overlap = true,
      priority = 1000,
    },
    zindex = 10, --default 50
    treesitter_context = nil, -- it can be { line_shift_down = 2 }, currently not usable, for detail see https://github.com/otavioschwanck/arrow.nvim/pull/43#issue-2236320268
  },
  separate_save_and_remove = false, -- if true, will remove the toggle and create the save/remove keymaps.
  leader_key = ";",
  save_key = "cwd", -- what will be used as root to save the bookmarks. Can be also `git_root` or `global`.
  index_keys = "123456789zxcbnmZXVBNM,afghjklAFGHJKLwrtyuiopWRTYUIOP", -- keys mapped to bookmark index, i.e. 1st bookmark will be accessible by 1, and 12th - by c
}
```

You can also map previous and next key:

```lua
vim.keymap.set("n", "H", function() require("arrow").prev_buffer() end)
vim.keymap.set("n", "L", function() require("arrow").next_buffer() end)
vim.keymap.set("n", "<C-s>", function() require("arrow").save_current_buffer() end)
```


## Statusline

You can use `require('arrow.statusline')` to access the status line helpers:

```lua
local statusline = require('arrow.statusline')
statusline.is_on_arrow_file() -- return nil if current file is not on arrow.  Return the index if it is.
statusline.text_for_statusline() -- return the text to be shown in the statusline (the index if is on arrow or "" if not)
statusline.text_for_statusline_with_icons() -- Same, but with an bow and arrow icon ;D
```

![statusline](https://i.imgur.com/v7Rvagj.png)

## Highlights

- ArrowFileIndex
- ArrowCurrentFile
- ArrowAction
- ArrowDeleteMode
- ArrowLocation

## Working with sessions plugins

If you have any error using arrow with a session plugin,
like on mini.sessions, add this to the post load session hook:

```lua
require("arrow.git").refresh_git_branch() -- only if separated_by_branch is true
require("arrow.persist").load_cache_file()
```

Obs: persistence.nvim works fine with arrow.

## Like the original arrow.nvim? Buy the maintainer a coffee

https://www.buymeacoffee.com/otavioschwanck

### Special Contributors

- ![xzbdmw](https://github.com/xzbdmw) - Had the idea of per buffer bookmarks and helped to implement it.
