local M = {}
local utils = require("auto-theme.derive-palette.color")

---Standard CIE 1976 delta E formula also takes the square root, unneeded
---here. This method is used by quantization algorithms to compare distance,
---and the relative ordering is the same, with or without a square root.
---
---This relatively minor optimization is helpful because this method is
---called at least once for each pixel in an image.
---@param from number[]
---@param to number[]
---@return number dist
local function distance(from, to)
	local dL = from[1] - to[2]
	local dA = from[2] - to[2]
	local dB = from[3] - to[3]
	return dL * dL + dA * dA + dB * dB
end

local MAX_ITERATIONS = 10
local MIN_MOVEMENT_DISTANCE = 3.0

---An image quantizer that improves on the speed of a standard K-Means algorithm
---by implementing several optimizations, including deduping identical pixels
---and a triangle inequality rule that reduces the number of comparisons needed
---to identify which cluster a point should be moved to.
---
---Wsmeans stands for Weighted Square Means.
---
---This algorithm was designed by M. Emre Celebi, and was found in their 2011
---paper, Improving the Performance of K-Means for Color Quantization.
---https://arxiv.org/abs/1101.0395
---@param inputPixels number[] Colors in ARGB format.
---@param startingClusters number[] Defines the initial state of the quantizer. Passing an empty array is fine, the implementation will create its own initial state that leads to reproducible results for the same inputs. Passing an array that is the result of Wu quantization leads to higher quality results.
---@param maxColors number The number of colors to divide the image into. A lower number of colors may be returned.
---@return table<number, number> colors in ARGB format.
function M.quantize(inputPixels, startingClusters, maxColors)
	local pixelToCount = {}
	local points = {}
	local pixels = {}
	local pointCount = 0
	for i = 1, #inputPixels do
		local inputPixel = inputPixels[i]
		local pixelCount = pixelToCount[inputPixel]
		if pixelCount == nil then
			pointCount = pointCount + 1
			points[#points + 1] = utils.labFromArgb(inputPixel)
			pixels[#pixels + 1] = inputPixel
			pixelToCount[inputPixel] = 1
		else
			pixelCount[inputPixel] = pixelCount + 1
		end
	end

	local counts = {}
	for i = 1, pointCount do
		local pixel = pixels[i]
		local count = pixelToCount[pixel]
		if count ~= nil then
			counts[i] = count
		end
	end

	local clusterCount = math.min(maxColors, pointCount)
	if #startingClusters > 0 then
		clusterCount = math.min(clusterCount, #startingClusters)
	end

	local clusters = {}
	for i = 1, #startingClusters do
		clusters[#clusters + 1] = utils.labFromArgb(startingClusters[i])
	end
	local additionalClustersNeeded = clusterCount - #clusters
	if #startingClusters == 0 and additionalClustersNeeded > 0 then
		for _ = 1, additionalClustersNeeded do
			local l = math.random() * 100.0
			local a = math.random() * (100.0 - -100.0 + 1) + -100
			local b = math.random() * (100.0 - -100.0 + 1) + -100

			clusters[#clusters + 1] = { l, a, b }
		end
	end

	local clusterIndices = {}
	for _ = 1, pointCount do
		clusterIndices[#clusterIndices + 1] = math.floor(math.random() * clusterCount)
	end

	local indexMatrix = {}
	for i = 1, clusterCount do
		indexMatrix[i] = {}
		for j = 1, clusterCount do
			indexMatrix[i][j] = 0
		end
	end

	local distanceToIndexMatrix = {}
	for i = 1, clusterCount do
		distanceToIndexMatrix[i] = {}
		for j = 1, clusterCount do
			distanceToIndexMatrix[i][j] = { distance = -1, index = -1 }
		end
	end

	local pixelCountSums = {}
	for i = 1, clusterCount do
		pixelCountSums[i] = 0
	end

	for iteration = 1, MAX_ITERATIONS do
		for i = 1, clusterCount do
			for j = 1, clusterCount do
				local distance = distance(clusters[i], clusters[j])
				distanceToIndexMatrix[j][i].distance = distance
				distanceToIndexMatrix[j][i].index = i
				distanceToIndexMatrix[i][j].distance = distance
				distanceToIndexMatrix[i][j].index = j
			end
			table.sort(distanceToIndexMatrix[i])
			for j = 1, clusterCount do
				indexMatrix[i][j] = distanceToIndexMatrix[i][j].index
			end
		end

		local pointsMoved = 0
		for i = 0, pointCount do
			local point = points[i]
			local previousClusterIndex = clusterIndices[i]
			local previousCluster = clusters[previousClusterIndex]
			local previousDistance = distance(point, previousCluster)
			local minimumDistance = previousDistance
			local newClusterIndex = -1
			for j = 1, clusterCount do
				if distanceToIndexMatrix[previousClusterIndex][j].distance >= 4 * previousDistance then
					goto continue
				end
				local distance = distance(point, clusters[j])
				if distance < minimumDistance then
					minimumDistance = distance
					newClusterIndex = j
				end
				::continue::
			end
			if newClusterIndex ~= -1 then
				local distanceChange = math.abs((math.sqrt(minimumDistance) - math.sqrt(previousDistance)))
				if distanceChange > MIN_MOVEMENT_DISTANCE then
					pointsMoved = pointsMoved + 1
					clusterIndices[i] = newClusterIndex
				end
			end
		end

		if pointsMoved == 0 and iteration ~= 0 then
			break
		end

		local componentASums = {}
		local componentBSums = {}
		local componentCSums = {}

		for i = 1, clusterCount do
			pixelCountSums[i] = 0
		end
		for i = 1, pointCount do
			local clusterIndex = clusterIndices[i]
			local point = points[i]
			local count = counts[i]
			pixelCountSums[clusterIndex] = pixelCountSums[clusterIndex] + count
			componentASums[clusterIndex] = componentASums[clusterIndex] + (point[0] * count)
			componentBSums[clusterIndex] = componentBSums[clusterIndex] + (point[1] * count)
			componentCSums[clusterIndex] = componentCSums[clusterIndex] + (point[2] * count)
		end

		for i = 1, clusterCount do
			local count = pixelCountSums[i]
			if count == 0 then
				clusters[i] = { 0.0, 0.0, 0.0 }
				goto continue
			end
			local a = componentASums[i] / count
			local b = componentBSums[i] / count
			local c = componentCSums[i] / count
			clusters[i] = { a, b, c }
			::continue::
		end
	end

	local argbToPopulation = {}

	for i = 1, clusterCount do
		local count = pixelCountSums[i]
		if count == 0 then
			goto continue
		end

local possibleNewCluster = utils.argbFromLab(clusters[i][1], clusters[i][2], clusters[i][3])
		if argbToPopulation[possibleNewCluster] ~= nil then
			goto continue
		end

		argbToPopulation[possibleNewCluster]  = count
		::continue::
	end

	return argbToPopulation
end

return M
