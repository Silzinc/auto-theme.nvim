local M = {}

local join = vim.fs.joinpath
local fetch = require("auto-theme.fetch")

function M.load_rust()
	if M._lib ~= nil then
		return
	end

	if vim.fn.filereadable(fetch.bin_location) == 0 then
		vim.notify("auto-theme binary was not found", vim.log.levels.INFO, { title = "auto-theme.nvim" })
		fetch.download_bin()
	end

	package.cpath = package.cpath .. ";" .. join(fetch.plugin_root, "lib?" .. fetch.ext)
	M._lib = require("material_you_derive_palette")
end

---Takes arguments for generating a catppuccin palette as input, outputs the generated palette
---@param args MaterialYouArgs
---@return table<OnedarkColor, string>
function M.generate_palette(args)
	M.load_rust()

	-- Replace wallpaper path and material scheme if end-4 is selected
	if args.img == "end-4" then
		args.img = require("auto-theme.end_4").wallpaper()
		if args.img == nil then
			vim.notify("end-4 wallpaper could not be found", vim.log.levels.ERROR, { title = "auto-theme.nvim" })
			return {}
		end
	end
	if args.scheme == "end-4" then
		local scheme = require("auto-theme.end_4").scheme(args.img)
		if scheme == nil then
			vim.notify(
				"end-4 material scheme could not be determiend",
				vim.log.levels.ERROR,
				{ title = "auto-theme.nvim" }
			)
			return {}
		end
		args.scheme = scheme
	end

	-- Isolate the mixed colors from the table as the rust code should not process them.
	-- Also validate the colors.
	local mixed_colors = {}
	for k, v in pairs(args.material_dispatch) do
		if type(v) == "table" then
			if #v ~= 3 then
				vim.notify(
					"invalid mixed color '" .. k .. "': length different than 3",
					vim.log.levels.ERROR,
					{ title = "auto-theme.nvim" }
				)
				return {}
			end
			if type(v[1]) ~= "string" then
				vim.notify(
					string.format("invalid %s[1] of type '%s': it should be a string", k, type(v[1])),
					vim.log.levels.ERROR,
					{ title = "auto-theme.nvim" }
				)
				return {}
			end
			if type(v[2]) ~= "string" then
				vim.notify(
					string.format("invalid %s[2] of type '%s': it should be a string", k, type(v[2])),
					vim.log.levels.ERROR,
					{ title = "auto-theme.nvim" }
				)
				return {}
			end
			if type(v[3]) ~= "number" then
				vim.notify(
					string.format("invalid %s[4] of type '%s': it should be a number", k, type(v[2])),
					vim.log.levels.ERROR,
					{ title = "auto-theme.nvim" }
				)
				return {}
			end
			v[3] = math.min(v[3], 1.0)
			v[3] = math.max(v[3], 0.0)
			mixed_colors[k] = v
			-- temporarily remove entry so that nust does not complain
			args.material_dispatch[k] = nil
		elseif type(v) ~= "string" then
			vim.notify(
				string.format("invalid %s of type '%s': it should be a string or a table", k, type(v)),
				vim.log.levels.ERROR,
				{ title = "auto-theme.nvim" }
			)
			return {}
		end
	end

	local success, result = pcall(M._lib.generate_palette, args)
	if not success then
		vim.notify(result, vim.log.levels.ERROR, { title = "auto-theme.nvim" })
		return {}
	end
	local palette = result

	-- Apply material dispatch
	for k, mk in pairs(args.material_dispatch) do
		if not palette[mk] then
			vim.notify(
				string.format("invalid material color key '%s'", mk),
				vim.log.levels.ERROR,
				{ title = "auto-theme.nvim" }
			)
			return {}
		end
		palette[k] = palette[mk]
	end

	-- Apply gradients
	local blend = require("auto-theme.util").blend
	for k, v in pairs(mixed_colors) do
		-- restore the entry
		args.material_dispatch[k] = v

		if not palette[v[1]] then
			vim.notify(
				string.format("invalid material color key '%s'", v[1]),
				vim.log.levels.ERROR,
				{ title = "auto-theme.nvim" }
			)
			return {}
		end
		if not palette[v[2]] then
			vim.notify(
				string.format("invalid material color key '%s'", v[2]),
				vim.log.levels.ERROR,
				{ title = "auto-theme.nvim" }
			)
			return {}
		end
		palette[k] = blend(palette[v[2]], palette[v[1]], v[3])
	end

	-- Force static platette into the generated palette
	for k, v in pairs(args.static_palette) do
		palette[k] = v
	end

	return palette
end

return M
