for k in pairs(package.loaded) do
	if k:match(".*auto%-theme.*") then
		package.loaded[k] = nil
	end
end

require("auto-theme.init").setup()
require("auto-theme.init").colorscheme()
