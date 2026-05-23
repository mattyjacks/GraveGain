-- Maze Runner - Procedural Maze Generator
-- Uses recursive backtracking algorithm

local Config = require(script.Parent.config)

local MazeGenerator = {}

-- Maze grid: 0 = wall, 1 = path
MazeGenerator.Grid = {}
MazeGenerator.Size = 0
MazeGenerator.StartPos = {x = 1, y = 1}
MazeGenerator.EndPos = {x = 1, y = 1}

-- Generate maze using recursive backtracking
function MazeGenerator:Generate(size)
    -- Ensure odd size
    if size % 2 == 0 then
        size = size + 1
    end
    
    self.Size = size
    self.Grid = {}
    
    -- Initialize with walls
    for y = 1, size do
        self.Grid[y] = {}
        for x = 1, size do
            self.Grid[y][x] = 0
        end
    end
    
    -- Start from (2, 2) - must be even for path
    local startX, startY = 2, 2
    self.StartPos = {x = startX, y = startY}
    self.Grid[startY][startX] = 1
    
    -- Directions: up, right, down, left (jump 2 cells)
    local directions = {
        {dx = 0, dy = -2},
        {dx = 2, dy = 0},
        {dx = 0, dy = 2},
        {dx = -2, dy = 0},
    }
    
    -- Recursive backtracking
    local function carve(x, y)
        -- Shuffle directions
        for i = #directions, 2, -1 do
            local j = math.random(i)
            directions[i], directions[j] = directions[j], directions[i]
        end
        
        for _, dir in ipairs(directions) do
            local nx = x + dir.dx
            local ny = y + dir.dy
            
            -- Check bounds and if unvisited
            if nx > 1 and nx < size and ny > 1 and ny < size then
                if self.Grid[ny][nx] == 0 then
                    -- Carve path
                    self.Grid[ny][nx] = 1
                    self.Grid[y + dir.dy/2][x + dir.dx/2] = 1 -- Wall between
                    carve(nx, ny)
                end
            end
        end
    end
    
    carve(startX, startY)
    
    -- Set end position (furthest point from start)
    self.EndPos = self:FindFurthestPoint(startX, startY)
    
    -- Add some random loops (remove random walls)
    self:AddLoops(math.floor(size * 0.1))
    
    -- Place powerups
    self.PowerupPositions = self:PlacePowerups(3)
    
    return self.Grid, self.StartPos, self.EndPos
end

-- BFS to find furthest point
function MazeGenerator:FindFurthestPoint(startX, startY)
    local visited = {}
    local queue = {{x = startX, y = startY, dist = 0}}
    local furthest = {x = startX, y = startY, dist = 0}
    
    for y = 1, self.Size do
        visited[y] = {}
        for x = 1, self.Size do
            visited[y][x] = false
        end
    end
    
    visited[startY][startX] = true
    
    local head = 1
    while head <= #queue do
        local current = queue[head]
        head = head + 1
        
        if current.dist > furthest.dist then
            furthest = current
        end
        
        local neighbors = {
            {x = current.x, y = current.y - 1},
            {x = current.x + 1, y = current.y},
            {x = current.x, y = current.y + 1},
            {x = current.x - 1, y = current.y},
        }
        
        for _, n in ipairs(neighbors) do
            if n.x >= 1 and n.x <= self.Size and n.y >= 1 and n.y <= self.Size then
                if not visited[n.y][n.x] and self.Grid[n.y][n.x] == 1 then
                    visited[n.y][n.x] = true
                    table.insert(queue, {x = n.x, y = n.y, dist = current.dist + 1})
                end
            end
        end
    end
    
    return furthest
end

-- Add random loops by removing walls
function MazeGenerator:AddLoops(count)
    for i = 1, count do
        local x = math.random(2, self.Size - 1)
        local y = math.random(2, self.Size - 1)
        
        -- Only remove if it's a wall with paths on both sides
        if self.Grid[y][x] == 0 then
            local pathCount = 0
            if self.Grid[y-1] and self.Grid[y-1][x] == 1 then pathCount = pathCount + 1 end
            if self.Grid[y+1] and self.Grid[y+1][x] == 1 then pathCount = pathCount + 1 end
            if self.Grid[y][x-1] == 1 then pathCount = pathCount + 1 end
            if self.Grid[y][x+1] == 1 then pathCount = pathCount + 1 end
            
            if pathCount >= 2 then
                self.Grid[y][x] = 1
            end
        end
    end
end

-- Place powerups at random path locations
function MazeGenerator:PlacePowerups(count)
    local positions = {}
    local attempts = 0
    
    while #positions < count and attempts < 100 do
        attempts = attempts + 1
        local x = math.random(2, self.Size - 1)
        local y = math.random(2, self.Size - 1)
        
        -- Must be on path, not start or end
        if self.Grid[y][x] == 1 then
            local isStart = (x == self.StartPos.x and y == self.StartPos.y)
            local isEnd = (x == self.EndPos.x and y == self.EndPos.y)
            local isDuplicate = false
            
            for _, pos in ipairs(positions) do
                if pos.x == x and pos.y == y then
                    isDuplicate = true
                    break
                end
            end
            
            if not isStart and not isEnd and not isDuplicate then
                local types = {"SpeedBoost", "TimeBonus", "VisionBoost"}
                table.insert(positions, {
                    x = x,
                    y = y,
                    type = types[math.random(#types)]
                })
            end
        end
    end
    
    return positions
end

-- Get world position from grid coordinates
function MazeGenerator:GridToWorld(x, y)
    return Vector3.new(
        (x - 1) * Config.CELL_SIZE,
        0,
        (y - 1) * Config.CELL_SIZE
    )
end

-- Check if position is valid path
function MazeGenerator:IsPath(x, y)
    if x < 1 or x > self.Size or y < 1 or y > self.Size then
        return false
    end
    return self.Grid[y][x] == 1
end

return MazeGenerator
