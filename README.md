## Installation
Install via your favourite package manager. It is recommended to use Lazy with the following spec:

```lua
{
  "Silzinc/auto-theme.nvim",
  lazy = true,
  build = function()
    require("auto-theme.fetch").download_bin()
  end
  opts = {}, -- options go here
}
```

## Configuration

### Enable theme

```lua
-- Lua
require('auto-theme').load()
```

```vim
" Vim
colorscheme auto-theme
```

## TODO Default Configuration

```lua
-- Lua
require('auto-theme').setup  {
    -- Main options --
    style = 'dark', -- Default theme style. Choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer' and 'light'
    transparent = false,  -- Show/hide background
    term_colors = true, -- Change terminal color as per the selected theme style
    ending_tildes = false, -- Show the end-of-buffer tildes. By default they are hidden
    cmp_itemkind_reverse = false, -- reverse item kind highlights in cmp menu

    -- toggle theme style ---
    toggle_style_key = nil, -- keybind to toggle theme style. Leave it nil to disable it, or set it to a string, for example "<leader>ts"
    toggle_style_list = {'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light'}, -- List of styles to toggle between

    -- Change code style ---
    -- Options are italic, bold, underline, none
    -- You can configure multiple style with comma separated, For e.g., keywords = 'italic,bold'
    code_style = {
        comments = 'italic',
        keywords = 'none',
        functions = 'none',
        strings = 'none',
        variables = 'none'
    },

    -- Lualine options --
    lualine = {
        transparent = false, -- lualine center bar transparency
    },

    -- Custom Highlights --
    colors = {}, -- Override default colors
    highlights = {}, -- Override highlight groups

    -- Plugins Config --
    diagnostics = {
        darker = true, -- darker colors for diagnostic
        undercurl = true,   -- use undercurl instead of underline for diagnostics
        background = true,    -- use background color for virtual text
    },
}
```

## TODO Customization

Example custom colors and Highlights config

```lua
require('auto-theme').setup {
  colors = {
    bright_orange = "#ff8800",    -- define a new color
    green = '#00ffaa',            -- redefine an existing color
  },
  highlights = {
    ["@lsp.type.keyword"] = { fg = "$green" },
    ["@lsp.type.property"] = {fg = '$bright_orange', bg = '#00ff00', fmt = 'bold'},
    ["@lsp.type.function"] =  {fg = '#0000ff', sp = '$cyan', fmt = 'underline,italic'},
    ["@lsp.type.method"] = { link = "@function" },
  -- To add language specific config
    ["@lsp.type.variable.go"] = { fg = "none" },
  }
}
```
Note that TreeSitter keywords have been changed after neovim version 0.8 and onwards.
TS prefix is trimmed and lowercase words should be used separated with '.'

The old way before neovim 0.8 looks like this.
For all keywords see [this](https://github.com/navarasu/auto-theme.nvim/blob/master/lua/auto-theme/highlights.lua#L133-L257) file from line 133 to 257

```lua
require('auto-theme').setup {
  colors = {
    bright_orange = "#ff8800",    -- define a new color
    green = '#00ffaa',            -- redefine an existing color
  },
  highlights = {
    TSKeyword = {fg = '$green'},
    TSString = {fg = '$bright_orange', bg = '#00ff00', fmt = 'bold'},
    TSFunction = {fg = '#0000ff', sp = '$cyan', fmt = 'underline,italic'},
    TSFuncBuiltin = {fg = '#0059ff'}
  }
}
```

## Plugins Supported

Same as for [onedark.nvim](https://github.com/navarasu/onedark.nvim).

## Contributing

Pull requests are welcome 🎉👍.

## License

[MIT](https://choosealicense.com/licenses/mit/)
