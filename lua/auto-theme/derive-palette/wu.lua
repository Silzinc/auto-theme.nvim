-- Please forgive me for vibe coding most of this

local M = {}
local utils = require("auto-theme.derive-palette.color")

---Pixels are expected to be Argb colors represented as integers
---@param pixels number[]
---@return table<number, number> counts
function M.quantizeMap(pixels)
	local counts = {}
	for _, p in ipairs(pixels) do
		counts[p] = (counts[p] or 0) + 1
	end
	return counts
end

-- Constants
local INDEX_BITS = 5
local SIDE_LENGTH = 33 -- ((1 << INDEX_INDEX_BITS) + 1)
local TOTAL_SIZE = 35937 -- SIDE_LENGTH * SIDE_LENGTH * SIDE_LENGTH

-- Directions
local directions = {
	RED = "red",
	GREEN = "green",
	BLUE = "blue",
}

---Keeps track of the state of each box created as the Wu quantization
---algorithm progresses through dividing the image's pixels as plotted in RGB.
---@class Box
---@field r0 number
---@field r1 number
---@field g0 number
---@field g1 number
---@field b0 number
---@field b1 number
---@field vol number
local Box = {}
Box.__index = Box

function Box:new()
	local o = {
		r0 = 0,
		r1 = 0,
		g0 = 0,
		g1 = 0,
		b0 = 0,
		b1 = 0,
		vol = 0,
	}
	setmetatable(o, Box)
	return o
end

---Represents final result of Wu algorithm.
---@class CreateBoxesResult
local CreateBoxesResult = {}
CreateBoxesResult.__index = CreateBoxesResult

function CreateBoxesResult:new(requestedCount, resultCount)
	return setmetatable({
		requestedCount = requestedCount,
		resultCount = resultCount,
	}, CreateBoxesResult)
end

---Represents the result of calculating where to cut an existing box in such
---a way to maximize variance between the two new boxes created by a cut.
---@class MaximizeResult
local MaximizeResult = {}
MaximizeResult.__index = MaximizeResult

function MaximizeResult:new(cutLocation, maximum)
	return setmetatable({
		cutLocation = cutLocation,
		maximum = maximum,
	}, MaximizeResult)
end

---An image quantizer that divides the image's pixels into clusters by
---recursively cutting an RGB cube, based on the weight of pixels in each area
---of the cube.
---
---The algorithm was described by Xiaolin Wu in Graphic Gems II, published in
---1991.
---@class QuantizerWu
---@field weights number[]
---@field momentsR number[]
---@field momentsG number[]
---@field momentsB number[]
---@field moments number[]
---@field cubes Box[]
local QuantizerWu = {}
QuantizerWu.__index = QuantizerWu

function QuantizerWu:new()
	return setmetatable({
		weights = {},
		momentsR = {},
		momentsG = {},
		momentsB = {},
		moments = {},
		cubes = {},
	}, QuantizerWu)
end

function QuantizerWu:quantize(pixels, maxColors)
	self:constructHistogram(pixels)
	self:computeMoments()
	local createBoxesResult = self:createBoxes(maxColors)
	local results = self:createResult(createBoxesResult.resultCount)
	return results
end

function QuantizerWu:constructHistogram(pixels)
	for _, key in ipairs({ "weights", "momentsR", "momentsG", "momentsB", "moments" }) do
		self[key] = {}
		for i = 1, TOTAL_SIZE do
			self[key][i] = 0
		end
	end

	local countByColor = M.quantizeMap(pixels)

	for pixel, count in pairs(countByColor) do
		local red = utils.redFromArgb(pixel)
		local green = utils.greenFromArgb(pixel)
		local blue = utils.blueFromArgb(pixel)

		local bitsToRemove = 8 - INDEX_BITS
		local iR = bit.rshift(red, bitsToRemove) + 1
		local iG = bit.rshift(green, bitsToRemove) + 1
		local iB = bit.rshift(blue, bitsToRemove) + 1
		local index = self:getIndex(iR, iG, iB)

		self.weights[index] = (self.weights[index] or 0) + count
		self.momentsR[index] = self.momentsR[index] + count * red
		self.momentsG[index] = self.momentsG[index] + count * green
		self.momentsB[index] = self.momentsB[index] + count * blue
		self.moments[index] = self.moments[index] + count * (red * red + green * green + blue * blue)
	end
end

function QuantizerWu:computeMoments()
	local area, areaR, areaG, areaB, area2 = {}, {}, {}, {}, {}
	for r = 1, SIDE_LENGTH - 1 do
		for _, t in ipairs({ area, areaR, areaG, areaB, area2 }) do
			for i = 1, SIDE_LENGTH do
				t[i] = 0
			end
		end

		for g = 1, SIDE_LENGTH - 1 do
			local line, lineR, lineG, lineB, line2 = 0, 0, 0, 0, 0

			for b = 1, SIDE_LENGTH - 1 do
				local index = self:getIndex(r, g, b)
				line = line + self.weights[index]
				lineR = lineR + self.momentsR[index]
				lineG = lineG + self.momentsG[index]
				lineB = lineB + self.momentsB[index]
				line2 = line2 + self.moments[index]

				area[b + 1] = area[b + 1] + line
				areaR[b + 1] = areaR[b + 1] + lineR
				areaG[b + 1] = areaG[b + 1] + lineG
				areaB[b + 1] = areaB[b + 1] + lineB
				area2[b + 1] = area2[b + 1] + line2

				local previousIndex = self:getIndex(r - 1, g, b)
				self.weights[index] = self.weights[previousIndex] + area[b + 1]
				self.momentsR[index] = self.momentsR[previousIndex] + areaR[b + 1]
				self.momentsG[index] = self.momentsG[previousIndex] + areaG[b + 1]
				self.momentsB[index] = self.momentsB[previousIndex] + areaB[b + 1]
				self.moments[index] = self.moments[previousIndex] + area2[b + 1]
			end
		end
	end
end

function QuantizerWu:createBoxes(maxColors)
	self.cubes = {}
	for i = 1, maxColors do
		self.cubes[i] = Box:new()
	end

	local volumeVariance = {}
	for i = 1, maxColors do
		volumeVariance[i] = 0
	end

	self.cubes[1].r0 = 0
	self.cubes[1].g0 = 0
	self.cubes[1].b0 = 0
	self.cubes[1].r1 = SIDE_LENGTH - 1
	self.cubes[1].g1 = SIDE_LENGTH - 1
	self.cubes[1].b1 = SIDE_LENGTH - 1

	local generatedColorCount = maxColors
	local next = 1
	for i = 2, maxColors do
		if self:cut(self.cubes[next], self.cubes[i]) then
			volumeVariance[next] = self.cubes[next].vol > 1 and self:variance(self.cubes[next]) or 0.0
			volumeVariance[i] = self.cubes[i].vol > 1 and self:variance(self.cubes[i]) or 0.0
		else
			volumeVariance[next] = 0.0
			i = i - 1
		end

		next = 1
		local temp = volumeVariance[1]
		for j = 2, i do
			if volumeVariance[j] > temp then
				temp = volumeVariance[j]
				next = j
			end
		end
		if temp <= 0 then
			generatedColorCount = i
			break
		end
	end
	return CreateBoxesResult:new(maxColors, generatedColorCount)
end

function QuantizerWu:createResult(colorCount)
	local colors = {}
	for i = 1, colorCount do
		local cube = self.cubes[i]
		local weight = self:volume(cube, self.weights)
		if weight > 0 then
			local r = math.floor(self:volume(cube, self.momentsR) / weight + 0.5)
			local g = math.floor(self:volume(cube, self.momentsG) / weight + 0.5)
			local b = math.floor(self:volume(cube, self.momentsB) / weight + 0.5)
			local color = bit.lshift(255, 24) | bit.lshift(r & 0x0ff, 16) | bit.lshift(g & 0x0ff, 8) | (b & 0x0ff)
			table.insert(colors, color)
		end
	end
	return colors
end

function QuantizerWu:variance(cube)
	local dr = self:volume(cube, self.momentsR)
	local dg = self:volume(cube, self.momentsG)
	local db = self:volume(cube, self.momentsB)
	local xx = self.moments[self:getIndex(cube.r1, cube.g1, cube.b1)]
		- self.moments[self:getIndex(cube.r1, cube.g1, cube.b0)]
		- self.moments[self:getIndex(cube.r1, cube.g0, cube.b1)]
		+ self.moments[self:getIndex(cube.r1, cube.g0, cube.b0)]
		- self.moments[self:getIndex(cube.r0, cube.g1, cube.b1)]
		+ self.moments[self:getIndex(cube.r0, cube.g1, cube.b0)]
		+ self.moments[self:getIndex(cube.r0, cube.g0, cube.b1)]
		- self.moments[self:getIndex(cube.r0, cube.g0, cube.b0)]
	local hypotenuse = dr * dr + dg * dg + db * db
	local volume = self:volume(cube, self.weights)
	return xx - hypotenuse / volume
end

function QuantizerWu:cut(one, two)
	local wholeR = self:volume(one, self.momentsR)
	local wholeG = self:volume(one, self.momentsG)
	local wholeB = self:volume(one, self.momentsB)
	local wholeW = self:volume(one, self.weights)

	local maxRResult = self:maximize(one, directions.RED, one.r0 + 1, one.r1, wholeR, wholeG, wholeB, wholeW)
	local maxGResult = self:maximize(one, directions.GREEN, one.g0 + 1, one.g1, wholeR, wholeG, wholeB, wholeW)
	local maxBResult = self:maximize(one, directions.BLUE, one.b0 + 1, one.b1, wholeR, wholeG, wholeB, wholeW)

	local direction
	local maxR = maxRResult.maximum
	local maxG = maxGResult.maximum
	local maxB = maxBResult.maximum
	if maxR >= maxG and maxR >= maxB then
		if maxRResult.cutLocation < 0 then
			return false
		end
		direction = directions.RED
	elseif maxG >= maxR and maxG >= maxB then
		direction = directions.GREEN
	else
		direction = directions.BLUE
	end

	two.r1 = one.r1
	two.g1 = one.g1
	two.b1 = one.b1

	if direction == directions.RED then
		one.r1 = maxRResult.cutLocation
		two.r0 = one.r1
		two.g0 = one.g0
		two.b0 = one.b0
	elseif direction == directions.GREEN then
		one.g1 = maxGResult.cutLocation
		two.r0 = one.r0
		two.g0 = one.g1
		two.b0 = one.b0
	elseif direction == directions.BLUE then
		one.b1 = maxBResult.cutLocation
		two.r0 = one.r0
		two.g0 = one.g0
		two.b0 = one.b1
	else
		error("unexpected direction " .. direction)
	end

	one.vol = (one.r1 - one.r0) * (one.g1 - one.g0) * (one.b1 - one.b0)
	two.vol = (two.r1 - two.r0) * (two.g1 - two.g0) * (two.b1 - two.b0)
	return true
end

function QuantizerWu:maximize(cube, direction, first, last, wholeR, wholeG, wholeB, wholeW)
	local bottomR = self:bottom(cube, direction, self.momentsR)
	local bottomG = self:bottom(cube, direction, self.momentsG)
	local bottomB = self:bottom(cube, direction, self.momentsB)
	local bottomW = self:bottom(cube, direction, self.weights)

	local max = 0.0
	local cut = -1

	local halfR = 0
	local halfG = 0
	local halfB = 0
	local halfW = 0
	for i = first, last - 1 do
		halfR = bottomR + self:top(cube, direction, i, self.momentsR)
		halfG = bottomG + self:top(cube, direction, i, self.momentsG)
		halfB = bottomB + self:top(cube, direction, i, self.momentsB)
		halfW = bottomW + self:top(cube, direction, i, self.weights)
		if halfW == 0 then
			goto continue
		end

		local tempNumerator = (halfR * halfR + halfG * halfG + halfB * halfB) * 1.0
		local tempDenominator = halfW * 1.0
		local temp = tempNumerator / tempDenominator

		halfR = wholeR - halfR
		halfG = wholeG - halfG
		halfB = wholeB - halfB
		halfW = wholeW - halfW
		if halfW == 0 then
			goto continue
		end

		tempNumerator = (halfR * halfR + halfG * halfG + halfB * halfB) * 1.0
		tempDenominator = halfW * 1.0
		temp = temp + tempNumerator / tempDenominator

		if temp > max then
			max = temp
			cut = i
		end

		::continue::
	end
	return MaximizeResult:new(cut, max)
end

function QuantizerWu:volume(cube, moment)
	return (
		moment[self:getIndex(cube.r1, cube.g1, cube.b1)]
		- moment[self:getIndex(cube.r1, cube.g1, cube.b0)]
		- moment[self:getIndex(cube.r1, cube.g0, cube.b1)]
		+ moment[self:getIndex(cube.r1, cube.g0, cube.b0)]
		- moment[self:getIndex(cube.r0, cube.g1, cube.b1)]
		+ moment[self:getIndex(cube.r0, cube.g1, cube.b0)]
		+ moment[self:getIndex(cube.r0, cube.g0, cube.b1)]
		- moment[self:getIndex(cube.r0, cube.g0, cube.b0)]
	)
end

function QuantizerWu:bottom(cube, direction, moment)
	if direction == directions.RED then
		return (
			-moment[self:getIndex(cube.r0, cube.g1, cube.b1)]
			+ moment[self:getIndex(cube.r0, cube.g1, cube.b0)]
			+ moment[self:getIndex(cube.r0, cube.g0, cube.b1)]
			- moment[self:getIndex(cube.r0, cube.g0, cube.b0)]
		)
	elseif direction == directions.GREEN then
		return (
			-moment[self:getIndex(cube.r1, cube.g0, cube.b1)]
			+ moment[self:getIndex(cube.r1, cube.g0, cube.b0)]
			+ moment[self:getIndex(cube.r0, cube.g0, cube.b1)]
			- moment[self:getIndex(cube.r0, cube.g0, cube.b0)]
		)
	elseif direction == directions.BLUE then
		return (
			-moment[self:getIndex(cube.r1, cube.g1, cube.b0)]
			+ moment[self:getIndex(cube.r1, cube.g0, cube.b0)]
			+ moment[self:getIndex(cube.r0, cube.g1, cube.b0)]
			- moment[self:getIndex(cube.r0, cube.g0, cube.b0)]
		)
	else
		error("unexpected direction " .. direction)
	end
end

function QuantizerWu:top(cube, direction, position, moment)
	if direction == directions.RED then
		return (
			moment[self:getIndex(position, cube.g1, cube.b1)]
			- moment[self:getIndex(position, cube.g1, cube.b0)]
			- moment[self:getIndex(position, cube.g0, cube.b1)]
			+ moment[self:getIndex(position, cube.g0, cube.b0)]
		)
	elseif direction == directions.GREEN then
		return (
			moment[self:getIndex(cube.r1, position, cube.b1)]
			- moment[self:getIndex(cube.r1, position, cube.b0)]
			- moment[self:getIndex(cube.r0, position, cube.b1)]
			+ moment[self:getIndex(cube.r0, position, cube.b0)]
		)
	elseif direction == directions.BLUE then
		return (
			moment[self:getIndex(cube.r1, cube.g1, position)]
			- moment[self:getIndex(cube.r1, cube.g0, position)]
			- moment[self:getIndex(cube.r0, cube.g1, position)]
			+ moment[self:getIndex(cube.r0, cube.g0, position)]
		)
	else
		error("unexpected direction " .. direction)
	end
end

function QuantizerWu:getIndex(r, g, b)
	return bit.lshift(r, INDEX_BITS * 2) + bit.lshift(r, INDEX_BITS + 1) + r + bit.lshift(g, INDEX_BITS) + g + b
end

-- Export the QuantizerWu class
M.QuantizerWu = QuantizerWu
M.Box = Box
M.CreateBoxesResult = CreateBoxesResult
M.MaximizeResult = MaximizeResult

return M
