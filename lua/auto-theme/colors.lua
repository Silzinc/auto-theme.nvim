local colors = require("auto-theme.palette")

local function select_colors()
	local selected = { none = "none" }
	selected = vim.tbl_extend("force", selected, colors(vim.g.auto_theme_config.style))
	selected = vim.tbl_extend("force", selected, vim.g.auto_theme_config.colors)
	return selected
end

return select_colors
