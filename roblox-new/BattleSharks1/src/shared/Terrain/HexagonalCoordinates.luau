-- BattleSharks Hexagonal Coordinate System
-- Implements axial coordinate system for hexagonal voxels

local HexagonalCoordinates = {}

-- Hexagonal coordinate system using axial coordinates (q, r)
-- Axial coordinates are more efficient than cube coordinates for hex grids
-- Reference: https://www.redblobgames.com/grids/hexagons/

-- Direction vectors for hexagonal grid (6 directions)
HexagonalCoordinates.DIRECTIONS = {
	{1, 0},   -- East
	{1, -1},  -- Northeast
	{0, -1},  -- Northwest
	{-1, 0},  -- West
	{-1, 1},  -- Southwest
	{0, 1}    -- Southeast
}

-- Diagonal directions (12 directions total)
HexagonalCoordinates.DIAGONALS = {
	{2, -1},  -- East-Northeast
	{1, -2},  -- Northeast-Northwest
	{-1, -1}, -- Northwest-West
	{-2, 1},  -- West-Southwest
	{-1, 2},  -- Southwest-Southeast
	{1, 1}    -- Southeast-East
}

-- Convert axial coordinates to world position
function HexagonalCoordinates.AxialToWorld(q, r, hexSize)
	hexSize = hexSize or 10
	local x = hexSize * (3/2 * q)
	local z = hexSize * (math.sqrt(3)/2 * q + math.sqrt(3) * r)
	return Vector3.new(x, 0, z)
end

-- Convert world position to axial coordinates
function HexagonalCoordinates.WorldToAxial(position, hexSize)
	hexSize = hexSize or 10
	local x = position.X
	local z = position.Z
	
	local q = (2/3 * x) / hexSize
	local r = (-1/3 * x + math.sqrt(3)/3 * z) / hexSize
	
	return HexagonalCoordinates.RoundAxial(q, r)
end

-- Round fractional axial coordinates to nearest hex
function HexagonalCoordinates.RoundAxial(q, r)
	local s = -q - r
	local rq = math.round(q)
	local rr = math.round(r)
	local rs = math.round(s)
	
	local q_diff = math.abs(rq - q)
	local r_diff = math.abs(rr - r)
	local s_diff = math.abs(rs - s)
	
	if q_diff > r_diff and q_diff > s_diff then
		rq = -rr - rs
	elseif r_diff > s_diff then
		rr = -rq - rs
	end
	
	return rq, rr
end

-- Get neighboring hex coordinates
function HexagonalCoordinates.GetNeighbors(q, r)
	local neighbors = {}
	for _, direction in ipairs(HexagonalCoordinates.DIRECTIONS) do
		table.insert(neighbors, {
			q = q + direction[1],
			r = r + direction[2]
		})
	end
	return neighbors
end

-- Get diagonal hex coordinates
function HexagonalCoordinates.GetDiagonals(q, r)
	local diagonals = {}
	for _, diagonal in ipairs(HexagonalCoordinates.DIAGONALS) do
		table.insert(diagonals, {
			q = q + diagonal[1],
			r = r + diagonal[2]
		})
	end
	return diagonals
end

-- Calculate distance between two hex coordinates
function HexagonalCoordinates.Distance(q1, r1, q2, r2)
	return (math.abs(q1 - q2) + math.abs(q1 + r1 - q2 - r2) + math.abs(r1 - r2)) / 2
end

-- Get all hexes within a certain radius
function HexagonalCoordinates.GetHexesInRange(centerQ, centerR, radius)
	local hexes = {}
	
	for q = -radius, radius do
		for r = math.max(-radius, -q - radius), math.min(radius, -q + radius) do
			table.insert(hexes, {
				q = centerQ + q,
				r = centerR + r
			})
		end
	end
	
	return hexes
end

-- Convert axial to cube coordinates (for certain calculations)
function HexagonalCoordinates.AxialToCube(q, r)
	return {
		x = q,
		y = -q - r,
		z = r
	}
end

-- Convert cube to axial coordinates
function HexagonalCoordinates.CubeToAxial(x, y, z)
	return x, z
end

-- Check if a hex coordinate is valid (not nil)
function HexagonalCoordinates.IsValidHex(q, r)
	return q ~= nil and r ~= nil
end

-- Get hex corners in world space (for mesh generation)
function HexagonalCoordinates.GetHexCorners(q, r, hexSize)
	hexSize = hexSize or 10
	local center = HexagonalCoordinates.AxialToWorld(q, r, hexSize)
	local corners = {}
	
	for i = 0, 5 do
		local angle = 2 * math.pi / 6 * i
		local corner = Vector3.new(
			center.X + hexSize * math.cos(angle),
			center.Y,
			center.Z + hexSize * math.sin(angle)
		)
		table.insert(corners, corner)
	end
	
	return corners
end

-- Get hex center in world space
function HexagonalCoordinates.GetHexCenter(q, r, hexSize)
	return HexagonalCoordinates.AxialToWorld(q, r, hexSize)
end

-- Check if a world position is inside a hex
function HexagonalCoordinates.IsPointInHex(worldPos, hexQ, hexR, hexSize)
	hexSize = hexSize or 10
	local localQ, localR = HexagonalCoordinates.WorldToAxial(worldPos, hexSize)
	return localQ == hexQ and localR == hexR
end

return HexagonalCoordinates
