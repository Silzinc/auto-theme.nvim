local M = {}

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

local default_config = {
	-- Main options --
	style = "dark", -- choose between 'dark' and 'light'
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

---Setup auto-theme.nvim options, without applying colorscheme
---@param opts table: a table containing options
function M.setup(opts)
	if not vim.g.auto_theme_config or not vim.g.auto_theme_config.loaded then -- if it's the first time setup() is called
		vim.g.auto_theme_config = vim.tbl_deep_extend("keep", vim.g.auto_theme_config or {}, default_config)
		M.set_options("loaded", true)
	end
	if opts then
		vim.g.auto_theme_config = vim.tbl_deep_extend("force", vim.g.auto_theme_config, opts)
	end
end

function M.load()
	vim.api.nvim_command("colorscheme auto-theme")
end

return M
