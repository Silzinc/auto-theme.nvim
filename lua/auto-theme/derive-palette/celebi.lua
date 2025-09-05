local wu = require("auto-theme.derive-palette.wu")
local wsmeans = require("auto-theme.derive-palette.wsmeans")

return {
	---An image quantizer that improves on the quality of a standard K-Means
	---algorithm by setting the K-Means initial state to the output of a Wu
	---quantizer, instead of random centroids. Improves on speed by several
	---optimizations, as implemented in Wsmeans, or Weighted Square Means, K-Means
	---with those optimizations.
	---
	---This algorithm was designed by M. Emre Celebi, and was found in their 2011
	---paper, Improving the Performance of K-Means for Color Quantization.
	---https://arxiv.org/abs/1101.0395
	---@param pixels number[] Colors in ARGB format.
	---@param maxColors number The number of colors to divide the image into. A lower number of colors may be returned.
	---@return table<number, number> result Map with keys of colors in ARGB format, and values of number of pixels in the original image that correspond to the color in the quantized image.
	quantize = function(pixels, maxColors)
		local qwu = wu.QuantizerWu:new()
		local wuResult = qwu:quantize(pixels, maxColors)
		return wsmeans.quantize(pixels, wuResult, maxColors)
	end,
}
