local M = {}

M.styles_list = { "dark", "light" }

---Change auto-theme option (vim.g.auto_theme_config.option)
---It can't be changed directly by modifying that field due to a Neovim lua bug with global variables (auto_theme_config is a global variable)
---@param opt string: option name
---@param value any: new value
function M.set_options(opt, value)
	local cfg = vim.g.auto_theme_config
	cfg[opt] = value
	vim.g.auto_theme_config = cfg
end

---Apply the colorscheme (same as ':colorscheme auto-theme')
function M.colorscheme()
	vim.cmd("hi clear")
	if vim.fn.exists("syntax_on") then
		vim.cmd("syntax reset")
	end
	vim.o.termguicolors = true
	vim.g.colors_name = "auto-theme"
	if vim.o.background == "light" then
		M.set_options("style", "light")
	elseif vim.g.auto_theme_config.style == "light" then
		M.set_options("style", "light")
	end
	require("auto-theme.highlights").setup()
	require("auto-theme.terminal").setup()
end

---Toggle between auto-theme styles
function M.toggle()
	local index = vim.g.auto_theme_config.toggle_style_index + 1
	if index > #vim.g.auto_theme_config.toggle_style_list then
		index = 1
	end
	M.set_options("style", vim.g.auto_theme_config.toggle_style_list[index])
	M.set_options("toggle_style_index", index)
	if vim.g.auto_theme_config.style == "light" then
		vim.o.background = "light"
	else
		vim.o.background = "dark"
	end
	vim.api.nvim_command("colorscheme auto-theme")
end

local default_config = {
	-- Main options --
	style = "dark", -- choose between 'dark' and 'light'
	toggle_style_key = nil,
	toggle_style_list = M.styles_list,
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
		darker = true, -- darker colors for diagnostic
		undercurl = true, -- use undercurl for diagnostics
		background = true, -- use background color for virtual text
	},

	-- Material-You options --
	material_you = {
		all = {
			material_dispatch = {
				text = "on_background",
				subtext0 = "on_surface_variant",
				subtext1 = "on_surface",
				-- equivalent to `overlay2 = "outline`
				overlay2 = { "outline_variant", "outline", 6.0 / 6.0 },
				overlay1 = { "outline_variant", "outline", 5.0 / 6.0 },
				overlay0 = { "outline_variant", "outline", 4.0 / 6.0 },
				surface2 = { "outline_variant", "outline", 3.0 / 6.0 },
				surface1 = { "outline_variant", "outline", 2.0 / 6.0 },
				surface0 = "surface_container_high",
				mantle = "surface_container",
				-- you can base replace with "surface_bright" to have something less dark in dark mode
				base = "background",
				crust = "surface",
			},
			size = 128,
			scheme = "vibrant",
			harmony = 0.8,
			harmonize_threshold = 100.0,
			fg_boost = 0.35,
		},
		light = {
			dark_mode = false,
			color = "#252932",
			base_palette = {
				black = "#101012",
				bg0 = "#fafafa",
				bg1 = "#f0f0f0",
				bg2 = "#e6e6e6",
				bg3 = "#dcdcdc",
				bg_d = "#c9c9c9",
				bg_blue = "#68aee8",
				bg_yellow = "#e2c792",
				fg = "#383a42",
				purple = "#a626a4",
				green = "#50a14f",
				orange = "#c18401",
				blue = "#4078f2",
				yellow = "#986801",
				cyan = "#0184bc",
				red = "#e45649",
				grey = "#a0a1a7",
				light_grey = "#818387",
				dark_cyan = "#2b5d63",
				dark_red = "#833b3b",
				dark_yellow = "#7c5c20",
				dark_purple = "#79428a",
				diff_add = "#e2fbe4",
				diff_delete = "#fce2e5",
				diff_change = "#e2ecfb",
				diff_text = "#cad3e0",
			},
		},
		dark = {
			dark_mode = true,
			color = "#A9C4EB",
			base_palette = {
				black = "#181a1f",
				bg0 = "#282c34",
				bg1 = "#31353f",
				bg2 = "#393f4a",
				bg3 = "#3b3f4c",
				bg_d = "#21252b",
				bg_blue = "#73b8f1",
				bg_yellow = "#ebd09c",
				fg = "#abb2bf",
				purple = "#c678dd",
				green = "#98c379",
				orange = "#d19a66",
				blue = "#61afef",
				yellow = "#e5c07b",
				cyan = "#56b6c2",
				red = "#e86671",
				grey = "#5c6370",
				light_grey = "#848b98",
				dark_cyan = "#2b6f77",
				dark_red = "#993939",
				dark_yellow = "#93691d",
				dark_purple = "#8a3fa0",
				diff_add = "#31392b",
				diff_delete = "#382b2c",
				diff_change = "#1c3448",
				diff_text = "#2c5372",
			},
		},
	},
}

---Setup auto-theme.nvim options, without applying colorscheme
---@param opts table: a table containing options
function M.setup(opts)
	if not vim.g.auto_theme_config or not vim.g.auto_theme_config.loaded then -- if it's the first time setup() is called
		vim.g.auto_theme_config = vim.tbl_deep_extend("keep", vim.g.auto_theme_config or {}, default_config)
		M.set_options("loaded", true)
		M.set_options("toggle_style_index", 0)
	end
	if opts then
		vim.g.auto_theme_config = vim.tbl_deep_extend("force", vim.g.auto_theme_config, opts)
		if opts.toggle_style_list then -- this table cannot be extended, it has to be replaced
			M.set_options("toggle_style_list", opts.toggle_style_list)
		end
	end
	if vim.g.auto_theme_config.toggle_style_key then
		vim.api.nvim_set_keymap(
			"n",
			vim.g.auto_theme_config.toggle_style_key,
			'<cmd>lua require("auto-theme").toggle()<cr>',
			{ noremap = true, silent = true }
		)
	end
end

function M.load()
	vim.api.nvim_command("colorscheme auto-theme")
end

return M
