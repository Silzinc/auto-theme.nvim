local M = {}

local join = vim.fs.joinpath

local this_dir = debug.getinfo(1).source:match("@?(.*/)")
local plugin_root = vim.fs.normalize(this_dir) .. "/../.."

local ext
if jit.os == "Windows" then
	ext = ".dll"
elseif jit.os == "OSX" then
	ext = ".dylib"
else
	ext = ".so"
end

function M.build()
	if M._lib ~= nil then
		return
	end

	local rust_lib = join(plugin_root, "libmaterial_you_derive_palette" .. ext)

	if vim.fn.filereadable(rust_lib) == 0 then
		vim.notify("Building auto-theme shared library...", vim.log.levels.INFO)

		local build_proc = vim.system(
			{ "cargo", "build", "--release", "--manifest-path", join(plugin_root, "Cargo.toml") },
			{ text = true }
		):wait()
		if build_proc.code ~= 0 then
			vim.notify(
				string.format(
					"auto-theme build failed with code %d. Make sure you have cargo installed.",
					build_proc.code
				),
				vim.log.levels.ERROR
			)
			return
		end

		local rust_lib_origin = join(plugin_root, "target", "release", "libmaterial_you_derive_palette" .. ext)
		if not vim.fn.filereadable(rust_lib_origin) then
			vim.notify(
				"auto-theme build failed: dynamic library could not be found after compilation",
				vim.log.levels.ERROR
			)
			return
		end
		if not os.rename(rust_lib_origin, rust_lib) then
			vim.notify("auto-theme build failed", vim.log.levels.ERROR)
			return
		end

		-- local clean_proc = vim.system(
		-- 	{ "cargo", "clean", "--manifest-path", join(plugin_root, "Cargo.toml") },
		-- 	{ text = true }
		-- )
		-- 	:wait()
		-- if clean_proc.code ~= 0 then
		-- 	vim.notify(
		-- 		string.format("auto-theme build cleaning step failed with code %d.", clean_proc.code),
		-- 		vim.log.levels.ERROR
		-- 	)
		-- 	return
		-- end
	end

	package.cpath = package.cpath .. ";" .. join(plugin_root, "lib?" .. ext)
	M._lib = require("material_you_derive_palette")
end

---Takes arguments for generating a catppuccin palette as input, outputs the generated palette
---@param args MaterialYouArgs
---@return table<OnedarkColor, string>
function M.generate_palette(args)
	M.build()

	-- Isolate the mixed colors from the table as the rust code should not process them.
	-- Also validate the colors.
	local mixed_colors = {}
	for k, v in pairs(args.material_dispatch) do
		if type(v) == "table" then
			if #v ~= 3 then
				vim.notify("invalid mixed color '" .. k .. "': length different than 3", vim.log.levels.ERROR)
				return {}
			end
			if type(v[1]) ~= "string" then
				vim.notify(
					string.format("invalid %s[1] of type '%s': it should be a string", k, type(v[1])),
					vim.log.levels.ERROR
				)
				return {}
			end
			if type(v[2]) ~= "string" then
				vim.notify(
					string.format("invalid %s[2] of type '%s': it should be a string", k, type(v[2])),
					vim.log.levels.ERROR
				)
				return {}
			end
			if type(v[3]) ~= "number" then
				vim.notify(
					string.format("invalid %s[4] of type '%s': it should be a number", k, type(v[2])),
					vim.log.levels.ERROR
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
				vim.log.levels.ERROR
			)
			return {}
		end
	end

	local palette = M._lib.generate_palette(args)

	-- Apply material dispatch
	for k, mk in pairs(args.material_dispatch) do
		if not palette[mk] then
			vim.notify(string.format("invalid material color key '%s'", mk), vim.log.levels.ERROR)
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
			vim.notify(string.format("invalid material color key '%s'", v[1]), vim.log.levels.ERROR)
			return {}
		end
		if not palette[v[2]] then
			vim.notify(string.format("invalid material color key '%s'", v[2]), vim.log.levels.ERROR)
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
