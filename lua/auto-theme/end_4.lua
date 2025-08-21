local M = {}

if jit.os ~= "Linux" then
	vim.notify("end-4 mode is only for linux nerds runnning hyprland", vim.log.levels.ERROR)
	return {}
end

local decode = require("auto-theme.json").decode
local join = vim.fs.joinpath

local home = vim.env.HOME or os.getenv("HOME")
local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or join(home, ".config")
local config_path = join(xdg_config_home, "illogical-impulse", "config.json")
local scheme_for_image = join(xdg_config_home, "quickshell", "ii", "scripts", "colors", "scheme_for_image.py")

local function get_config(...)
	local keys_list = { ... }

	local config_file = io.open(config_path)
	if not config_file then
		vim.notify(
			"end-4 theme cannot load:\n"
				.. string.format("illogical-impulse config file '%s' does not exist.", config_path),
			vim.diagnostic.ERROR
		)
		return
	end

	local config = decode(config_file:read("*a"))
	config_file:close()

	local entry = config
	for _, v in ipairs(keys_list) do
		if entry[v] == nil then
			return
		end
		entry = entry[v]
	end
	return entry
end

function M.scheme(img)
	if vim.fn.filereadable(img) == 0 then
		vim.notify(
			"if using end-4 mode with auto material scheme, please set img to 'end-4' or to an absolute path",
			vim.log.levels.ERROR
		)
		return
	end

	local end4_sch = get_config("appearance", "palette", "type")

	if end4_sch == nil then
		vim.notify("failed to get material scheme from end-4 config file", vim.log.levels.ERROR)
		return
	end

	if end4_sch == "auto" then
		local proc = vim.system({ scheme_for_image, img }, { text = true }):wait()
		if proc.code ~= 0 then
			vim.notify("failed to get material scheme in end-4 mode:\n" .. proc.stderr, vim.log.levels.ERROR)
			return
		end
		-- remove trailing \n
		end4_sch = proc.stdout:sub(1, #proc.stdout - 1)
	end

	-- end4_sch is of the form "scheme-{name-of-scheme}"
	return end4_sch:sub(8)
end

function M.wallpaper()
	return get_config("background", "wallpaperPath")
end

return M
