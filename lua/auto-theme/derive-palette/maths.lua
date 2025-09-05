---Utility methods for mathematical operations.
local M = {}

---The signum function.
---
---@return number sign 1 if num > 0, -1 if num < 0, and 0 if num = 0
function M.signum(num)
	if num < 0 then
		return -1
	elseif num == 0 then
		return 0
	else
		return 1
	end
end

---The linear interpolation function.
---
---@return number lerped start if amount = 0 and stop if amount = 1
function M.lerp(start, stop, amount)
	return (1.0 - amount) * start + amount * stop
end

---Clamps an integer between two integers.
---
---@return number clamped input when min <= input <= max, and either min or max otherwise.
function M.clampInt(min, max, input)
	if input < min then
		return min
	elseif input > max then
		return max
	end

	return input
end

---Clamps an integer between two floating-point numbers.
---
---@return number clamped input when min <= input <= max, and either min or max
---otherwise.
function M.clampDouble(min, max, input)
	if input < min then
		return min
	elseif input > max then
		return max
	end

	return input
end

---Sanitizes a degree measure as an integer.
---
---@return number deg a degree measure between 0 (inclusive) and 360 (exclusive).
function M.sanitizeDegreesInt(degrees)
	degrees = degrees % 360
	if degrees < 0 then
		degrees = degrees + 360
	end
	return degrees
end

---Sanitizes a degree measure as a floating-point number.
---
---@return number deg a degree measure between 0.0 (inclusive) and 360.0
---(exclusive).
function M.sanitizeDegreesDouble(degrees)
	degrees = degrees % 360.0
	if degrees < 0 then
		degrees = degrees + 360.0
	end
	return degrees
end

---Sign of direction change needed to travel from one angle to
---another.
---
---For angles that are 180 degrees apart from each other, both
---directions have the same travel distance, so either direction is
---shortest. The value 1.0 is returned in this case.
---
---@param from number The angle travel starts from, in degrees.
---@param to number The angle travel ends at, in degrees.
---@return number dir -1 if decreasing from leads to the shortest travel distance, 1 if increasing from leads to the shortest travel distance.
function M.rotationDirection(from, to)
	local increasingDifference = M.sanitizeDegreesDouble(to - from)
	return increasingDifference <= 180.0 and 1.0 or -1.0
end

---Distance of two points on a circle, represented using degrees.
function M.differenceDegrees(a, b)
	return 180.0 - math.abs(math.abs(a - b) - 180.0)
end

---Multiplies a 1x3 row vector with a 3x3 matrix.
function M.matrixMultiply(row, matrix)
	local a = row[1] * matrix[1][1] + row[2] * matrix[1][2] + row[3] * matrix[1][3]
	local b = row[1] * matrix[2][1] + row[2] * matrix[2][2] + row[3] * matrix[2][3]
	local c = row[1] * matrix[3][1] + row[2] * matrix[3][2] + row[3] * matrix[3][3]
	return { a, b, c }
end

return M
