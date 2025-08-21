local M = {}

-- Inspired from mason.nvim

---check if the host arch is x64 or arm64
local machine = vim.uv.os_uname().machine
local arch
if machine == "x86_64" or machine == "x64" then
	arch = "x64"
elseif
	machine == "aarch64"
	or machine == "aarch64_be"
	or machine == "armv8b"
	or machine == "armv8l"
	or machine == "arm64"
then
	arch = "arm64"
else
	error("unknown architecture '" .. machine .. "'")
end

local os
if jit.os == "Windows" then
	os = "windows"
	M.ext = ".dll"
elseif jit.os == "Linux" then
	os = "linux"
	M.ext = ".so"
elseif jit.os == "OSX" then
	os = "macos"
	M.ext = ".dylib"
	if arch == "x64" then
		arch = "intel"
	else
		arch = "m1"
	end
else
	error("unsupported os '" .. jit.os .. "'")
end

local os_id = os .. "-" .. arch
local bin_name = os_id .. M.ext
local bin_url = "https://github.com/Silzinc/auto-theme.nvim/releases/download/master/" .. bin_name
local this_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
M.plugin_root = vim.fs.dirname(vim.fs.dirname(this_dir))
M.bin_location = vim.fs.joinpath(M.plugin_root, "libmaterial_you_generate_palette" .. M.ext)

function M.download_bin()
	local function read_progress(err, data)
		if err then
			error(err)
		elseif data then
			local progress = data:sub(-6, data:len())
			while progress:len() < 6 do
				progress = " " .. progress
			end
			vim.defer_fn(function()
				vim.notify("Downloading " .. bin_name .. progress, vim.log.levels.INFO)
			end, 0)
		end
	end

	local success, result = pcall(vim.system, {
		"curl",
		"-L",
		bin_url,
		"--create-dirs",
		"--output",
		M.bin_location,
		"--progress-bar",
	}, {
		stdout = read_progress,
		stderr = read_progress,
		text = true,
	})

	if not success then
		vim.defer_fn(function()
			vim.notify(
				"Launching curl failed:\n" .. result .. "\nMake sure curl is installed on the system.",
				vim.log.levels.ERROR
			)
		end, 0)
	end

	local out = result:wait()
	if out.code ~= 0 then
		vim.defer_fn(function()
			vim.notify("Downloading " .. bin_name .. " binary failed, exit code: " .. out.code, vim.log.levels.ERROR)
		end, 0)
	end
end

return M
