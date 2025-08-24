## What is this

A [onedark.nvim](https://github.com/navarasu/onedark.nvim) based theme that automatically adapts its palette to a color or an image that you give to it. Examples:

<img width="1918" height="1018" alt="image" src="https://github.com/user-attachments/assets/4ded9611-0b52-44ff-b705-ae856c66b6f5" />
<img width="1920" height="1018" alt="image" src="https://github.com/user-attachments/assets/d33ee935-7567-4aea-ae24-daa5e2b7a6d0" />
<img width="1885" height="994" alt="image" src="https://github.com/user-attachments/assets/342f458d-ba14-4c4d-bb2f-f784372109ca" />



## Prerequisites

- Neovim (tested on version 0.11.3, it should probably work from 0.9 at least)
- curl, to install the binary

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
## Enable theme

```lua
-- Lua
-- Follow vim.o.background
vim.cmd.colorscheme("auto-theme")
-- Don't follow
vim.cmd.colorscheme("auto-theme-light")
vim.cmd.colorscheme("auto-theme-dark")
```

```vim
" Vim
colorscheme auto-theme
colorscheme auto-theme-light
colorscheme auto-theme-dark
```

## Configuration

Most options and functions are derived from [onedark.nvim](https://github.com/navarasu/onedark.nvim), with a few exceptions: 
- There is no toggle keybind or toggle list
- There are only `light` and `dark` schemes. They are not set with the `style` option, but by choosing the colorscheme `auto-theme-(light|dark)` or by using `auto-theme` and following the value of `vim.o.background`.
- There is a new rather complex `material_you` entry explained below.

### Material You

The scheme works by taking a **key color**, by tinting the colors of [onedark.nvim](https://github.com/navarasu/onedark.nvim) and by generating, from the same key color, a material 3 palette as per [material design](https://m3.material.io/styles/color/roles).

The `material_you` option contains `all`, `dark` and `light`, which set settings for the two variants of the theme, with `all` having a lower priority. They take the same inputs.

This entry is quite complex, you can look at the default configuration and at the examples below.

#### Example configs

Use the wallpaper to set the color

```lua
material_you = { all = { img = "wallpaper" } }
```

Use a custom image for the light theme and wallpaper for the dark theme

```lua
material_you = {
  dark = { img = "wallpaper" },
  light = { img = "absolute/path/to/image" }
}
```

Use pure red as a base for dark theme (ain't gonna look good)
```lua
material_you = { dark = { color = "#ff0000" } }
```

Use the `fruit-salad` material scheme on light variant, force the red color to `#ff0000` on dark variant and set `bg2` entry to the material color `surface` on both:

```lua
material_you = {
  all = { material_dispatch = { bg2 = "surface" } },
  dark = { static_palette = { red = "#ff0000" } },
  light = { scheme = "fruit-salad" }
}
```

#### Dispatching colors

The theme works by setting a number of colors (see "Colors to set") from which highlights are derived. Each have to be put in one of three objects in `all/dark/light`:

- `material_dispatch`, where the entries are either `color_name = material_color` or `color_name = { mcolor1, mcolor2, alpha }`, where the latter allows to blend the two material colors with `alpha` between 0 and 1. See "Available material color keys" below.
- `dynamic_palette`, where the entries are like `color_name = hex_color`. The colors set here will be tinted by the key color.
- `static_palette`, same as `dynamic_palette` but the colors are not tinted and are forced as is into the theme.

#### Generating the palette

- `color`: a hexadecimal string, sets the key color. Ignored if `img is set`.
- `img`: (optional) can take several value.
  - An absolute path to an image to get the key color from. 
  - `"wallpaper"` to try to find your wallpaper. Supported systems Linux KDE Plasma, Linux GNOME (not tested), Linux Cinnamon (not tested). If you would like your system (Windows, MacOS, other DEs on Linux...) to be supported, please open an issue or a pull request.
  - `"end-4"` to try to find your wallpaper if you are on Hyprland with the [end-4 dotfiles](https://github.com/end-4/dots-hyprland) (not tested yet).
- `size`: the image is resized to `size x size` before being quantized to get the key color (lower is faster but less accurate).
- `scheme`: sets the material scheme. See "Available material color schemes" below. Can be set to `"end-4"` to get the scheme currently used in end-4's dotfiles (not tested yet).
- `harmony`: (0-1) how much to tint the `dynamic_palette` towards the key color.
- `harmonize_threshold`: (0-180) max threshold angle to limit color hue shift.
- `fg_boost`: (0-1) make foreground more different from the background.
- `dark_mode`: boolean. Just keep the default (`false` for `light`, `true` for `dark`).

#### Colors to set
```
bg0, bg1, bg2, bg3, bg_d, bg_blue, bg_yellow, 
black, fg, grey, light_grey,
purple, green, orange, blue, yellow, cyan, red, 
dark_cyan, dark_red, dark_yellow, dark_purple, 
diff_add, diff_delete, diff_change, diff_text
```

#### Available material color keys

Please refer to [material design](https://m3.material.io/styles/color/roles) for a thorough description of most of these. Sorry for the rough typeset, but there really are a lot of them.

```
primary, on_primary, primary_container, on_primary_container, inverse_primary, primary_fixed, primary_fixed_dim, on_primary_fixed, on_primary_fixed_variant, 
secondary, on_secondary, secondary_container, on_secondary_container, secondary_fixed, secondary_fixed_dim, on_secondary_fixed, on_secondary_fixed_variant, 
tertiary, on_tertiary, tertiary_container, on_tertiary_container, tertiary_fixed, tertiary_fixed_dim, on_tertiary_fixed, on_tertiary_fixed_variant, 
error, on_error, error_container, on_error_container, 
surface_dim, surface, surface_tint, surface_bright, surface_variant, background, inverse_surface,
surface_container_lowest, surface_container_low, surface_container, surface_container_high, surface_container_highest, 
on_surface, on_surface_variant, on_background, inverse_on_surface
outline, outline_variant, shadow, scrim
```

#### Available material color schemes

```
monochrome, neutral, tonal-spot, vibrant, expressive, 
fidelity, content, rainbow, fruit-salad
```

### Default Configuration

```lua
-- Lua
require('auto-theme').setup  {
	-- Main options --
	transparent = false, -- don't set background
	term_colors = true, -- if true enable the terminal
	ending_tildes = false, -- show the end-of-buffer tildes
	cmp_itemkind_reverse = false, -- reverse item kind highlights in cmp menu

	-- Changing Formats --
	code_style = {
		comments = "italic",
		keywords = "none",
		functions = "none",
		strings = "none",
		variables = "none",
	},

	-- Lualine options --
	lualine = {
		transparent = false, -- center bar (c) transparency
	},

	-- Custom Highlights --
	colors = {}, -- Override default colors
	highlights = {}, -- Override highlight groups

	-- Plugins Related --
	diagnostics = {
		darker = false, -- darker colors for diagnostic
		undercurl = true, -- use undercurl for diagnostics
		background = true, -- use background color for virtual text
	},

	-- Material-You options --
	material_you = {
		all = {
			material_dispatch = {
				bg0 = "surface_container_lowest",
				bg1 = "surface_container_low",
				bg2 = "surface_container",
				bg3 = "surface_container_high",
				bg_d = "surface_container_highest",

				fg = "on_surface",
			},
			size = 128,
			scheme = "vibrant",
			harmony = 0.5,
			harmonize_threshold = 100.0,
			fg_boost = 0.0,
		},
		light = {
			dark_mode = false,
			color = "#252932",
			dynamic_palette = {
				bg_blue = "#68aee8",
				bg_yellow = "#e2c792",
				purple = "#a626a4",
				green = "#50a14f",
				orange = "#c18401",
				blue = "#4078f2",
				yellow = "#986801",
				cyan = "#0184bc",
				red = "#e45649",
				dark_cyan = "#2b5d63",
				dark_red = "#833b3b",
				dark_yellow = "#7c5c20",
				dark_purple = "#79428a",
				diff_add = "#e2fbe4",
				diff_delete = "#fce2e5",
				diff_change = "#e2ecfb",
				diff_text = "#cad3e0",
			},
			static_palette = {
				black = "#101012",
				grey = "#a0a1a7",
				light_grey = "#818387",
			},
		},
		dark = {
			dark_mode = true,
			color = "#A9C4EB",
			dynamic_palette = {
				bg_blue = "#73b8f1",
				bg_yellow = "#ebd09c",
				purple = "#c678dd",
				green = "#98c379",
				orange = "#d19a66",
				blue = "#61afef",
				yellow = "#e5c07b",
				cyan = "#56b6c2",
				red = "#e06c75",
				dark_cyan = "#2b6f77",
				dark_red = "#993939",
				dark_yellow = "#93691d",
				dark_purple = "#8a3fa0",
				diff_add = "#31392b",
				diff_delete = "#382b2c",
				diff_change = "#1c3448",
				diff_text = "#2c5372",
			},
			static_palette = {
				black = "#181a1f",
				grey = "#5c6370",
				light_grey = "#848b98",
			},
		},
	},
}
```

### Onedark-like customization

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
For all keywords see [this](https://github.com/navarasu/onedark.nvim/blob/master/lua/auto-theme/highlights.lua#L133-L257) file from line 133 to 257

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
