local mathUtils = require("auto-theme.derive-palette.maths")
local M = {}

-- Color science utilities.
--
-- Utility methods for color science constants and color space
-- conversions that aren't HCT or CAM16.

local SRGB_TO_XYZ = {
	{ 0.41233895, 0.35762064, 0.18051042 },
	{ 0.2126, 0.7152, 0.0722 },
	{ 0.01932141, 0.11916382, 0.95034478 },
}

local XYZ_TO_SRGB = {
	{
		3.2413774792388685,
		-1.5376652402851851,
		-0.49885366846268053,
	},
	{
		-0.9691452513005321,
		1.8758853451067872,
		0.04156585616912061,
	},
	{
		0.05562093689691305,
		-0.20395524564742123,
		1.0571799111220335,
	},
}

local WHITE_POINT_D65 = { 95.047, 100.0, 108.883 }

---Converts a color from RGB components to ARGB format.
---@param red number
---@param green number
---@param blue number
---@return number
function M.argbFromRgb(red, green, blue)
	return bit.rshift(bit.lshift(255, 24) | bit.lshift((red & 255), 16) | bit.lshift((green & 255), 8) | blue & 255, 0)
end

---Converts a color from linear RGB components to ARGB format.
---@param linrgb number[]
---@return number
function M.argbFromLinrgb(linrgb)
	local r = M.delinearized(linrgb[1])
	local g = M.delinearized(linrgb[2])
	local b = M.delinearized(linrgb[3])
	return M.argbFromRgb(r, g, b)
end

---Returns the alpha component of a color in ARGB format.
---@param argb number
---@return number
function M.alphaFromArgb(argb)
	return bit.rshift(argb, 24) & 255
end

---Returns the red component of a color in ARGB format.
---@param argb number
---@return number
function M.redFromArgb(argb)
	return bit.rshift(argb, 16) & 255
end

---Returns the green component of a color in ARGB format.
---@param argb number
---@return number
function M.greenFromArgb(argb)
	return bit.rshift(argb, 8) & 255
end

---Returns the blue component of a color in ARGB format.
---@param argb number
---@return number
function M.blueFromArgb(argb)
	return argb & 255
end

---Returns whether a color in ARGB format is opaque.
---@param argb number
---@return boolean
function M.isOpaque(argb)
	return M.alphaFromArgb(argb) >= 255
end

---Converts a color from ARGB to XYZ.
---@param x number
---@param y number
---@param z number
---@return number
function M.argbFromXyz(x, y, z)
	local matrix = XYZ_TO_SRGB
	local linearR = matrix[1][1] * x + matrix[1][2] * y + matrix[1][3] * z
	local linearG = matrix[2][1] * x + matrix[2][2] * y + matrix[2][3] * z
	local linearB = matrix[3][1] * x + matrix[3][2] * y + matrix[3][3] * z
	local r = M.delinearized(linearR)
	local g = M.delinearized(linearG)
	local b = M.delinearized(linearB)
	return M.argbFromRgb(r, g, b)
end

---Converts a color from XYZ to ARGB.
---@param argb number
---@return number[]
function M.xyzFromArgb(argb)
	local r = M.linearized(M.redFromArgb(argb))
	local g = M.linearized(M.greenFromArgb(argb))
	local b = M.linearized(M.blueFromArgb(argb))
	return mathUtils.matrixMultiply({ r, g, b }, SRGB_TO_XYZ)
end

---Converts a color represented in Lab color space into an ARGB
---integer.
---@param l number
---@param a number
---@param b number
---@return number
function M.argbFromLab(l, a, b)
	local whitePoint = WHITE_POINT_D65
	local fy = (l + 16.0) / 116.0
	local fx = a / 500.0 + fy
	local fz = fy - b / 200.0
	local xNormalized = M.labInvf(fx)
	local yNormalized = M.labInvf(fy)
	local zNormalized = M.labInvf(fz)
	local x = xNormalized * whitePoint[1]
	local y = yNormalized * whitePoint[2]
	local z = zNormalized * whitePoint[3]
	return M.argbFromXyz(x, y, z)
end

---Converts a color from ARGB representation to L*a*b*
---representation.
---@param argb number
---@return number[]
function M.labFromArgb(argb)
	local linearR = M.linearized(M.redFromArgb(argb))
	local linearG = M.linearized(M.greenFromArgb(argb))
	local linearB = M.linearized(M.blueFromArgb(argb))
	local matrix = SRGB_TO_XYZ
	local x = matrix[1][1] * linearR + matrix[1][2] * linearG + matrix[1][3] * linearB
	local y = matrix[2][1] * linearR + matrix[2][2] * linearG + matrix[2][3] * linearB
	local z = matrix[3][1] * linearR + matrix[3][2] * linearG + matrix[3][3] * linearB
	local whitePoint = WHITE_POINT_D65
	local xNormalized = x / whitePoint[1]
	local yNormalized = y / whitePoint[2]
	local zNormalized = z / whitePoint[3]
	local fx = M.labF(xNormalized)
	local fy = M.labF(yNormalized)
	local fz = M.labF(zNormalized)
	local l = 116.0 * fy - 16
	local a = 500.0 * (fx - fy)
	local b = 200.0 * (fy - fz)
	return { l, a, b }
end

---Converts an L* value to an ARGB representation.
---@param lstar number
---@return number
function M.argbFromLstar(lstar)
	local y = M.yFromLstar(lstar)
	local component = M.delinearized(y)
	return M.argbFromRgb(component, component, component)
end

---Computes the L* value of a color in ARGB representation.
---@param argb number
---@return number
function M.lstarFromArgb(argb)
	local y = M.xyzFromArgb(argb)[2]
	return 116.0 * M.labF(y / 100.0) - 16.0
end

---Converts an L* value to a Y value.
---@param lstar number
---@return number
function M.yFromLstar(lstar)
	return 100.0 * M.labInvf((lstar + 16.0) / 116.0)
end

---Converts a Y value to an L* value.
---@param y number
---@return number
function M.lstarFromY(y)
	return M.labF(y / 100.0) * 116.0 - 16.0
end

---Linearizes an RGB component.
---@param rgbComponent number
---@return number
function M.linearized(rgbComponent)
	local normalized = rgbComponent / 255.0
	if normalized <= 0.040449936 then
		return normalized / 12.92 * 100.0
	else
		return math.pow((normalized + 0.055) / 1.055, 2.4) * 100.0
	end
end

---Delinearizes an RGB component.
---@param rgbComponent number
---@return number
function M.delinearized(rgbComponent)
	local normalized = rgbComponent / 100.0
	local delinearized = 0.0
	if normalized <= 0.0031308 then
		delinearized = normalized * 12.92
	else
		delinearized = 1.055 * math.pow(normalized, 1.0 / 2.4) - 0.055
	end
	return mathUtils.clampInt(0, 255, math.floor(delinearized * 255.0 + 0.5))
end

---Returns the standard white point; white on a sunny day.
---@return number[]
function M.whitePointD65()
	return WHITE_POINT_D65
end

function M.labF(t)
	local e = 216.0 / 24389.0
	local kappa = 24389.0 / 27.0
	if t > e then
		return math.pow(t, 1.0 / 3.0)
	else
		return (kappa * t + 16) / 116
	end
end

function M.labInvf(ft)
	local e = 216.0 / 24389.0
	local kappa = 24389.0 / 27.0
	local ft3 = ft * ft * ft
	if ft3 > e then
		return ft3
	else
		return (116 * ft - 16) / kappa
	end
end

return M
