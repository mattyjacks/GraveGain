-- Color Rush - Procedural Level Generator

local Config = require(script.Parent.config)

local LevelGenerator = {}

LevelGenerator.Sections = {}
LevelGenerator.CurrentSeed = 0

-- Generate a level section
function LevelGenerator:GenerateSection(sectionNum, gameMode)
    local section = {
        sectionNum = sectionNum,
        platforms = {},
        powerup = nil,
        speed = Config.SCROLL_SPEED_BASE + math.floor(sectionNum / Config.SPEED_UP_INTERVAL) * Config.SPEED_INCREMENT,
    }
    
    -- Cap speed
    section.speed = math.min(section.speed, Config.SCROLL_SPEED_MAX)
    
    -- Generate platforms (4 rows, each with platforms of different colors)
    for row = 1, 4 do
        local rowColor = Config.COLORS[row]
        local platformCount = math.random(2, 4) -- 2-4 platforms per row
        
        for p = 1, platformCount do
            -- Calculate position
            local x = math.random(1, Config.LEVEL_WIDTH) * (Config.PLATFORM_SIZE + Config.PLATFORM_GAP)
            local y = 0
            local z = sectionNum * Config.ROW_SPACING
            
            -- Randomize row assignment for variety
            local actualRow = row
            if math.random() < 0.3 then
                actualRow = math.random(1, 4)
            end
            
            y = (actualRow - 2.5) * Config.ROW_SPACING
            
            table.insert(section.platforms, {
                position = Vector3.new(x, y, z),
                color = Config.COLORS[actualRow],
                row = actualRow,
                size = Vector3.new(
                    Config.PLATFORM_SIZE,
                    1,
                    math.random(8, 16) -- Variable length
                ),
            })
        end
    end
    
    -- Chance for powerup (10%)
    if math.random() < 0.1 then
        local powerupTypes = {"Rainbow", "SlowMo", "ExtraLife"}
        section.powerup = {
            type = powerupTypes[math.random(#powerupTypes)],
            position = Vector3.new(
                math.random(20, Config.LEVEL_WIDTH * (Config.PLATFORM_SIZE + Config.PLATFORM_GAP) - 20),
                math.random(-10, 10),
                sectionNum * Config.ROW_SPACING
            ),
        }
    end
    
    return section
end

-- Generate initial level
function LevelGenerator:GenerateLevel(gameMode, length)
    self.Sections = {}
    length = length or Config.LEVEL_LENGTH
    
    for i = 1, length do
        self.Sections[i] = self:GenerateSection(i, gameMode)
    end
    
    return self.Sections
end

-- Extend level (for endless mode)
function LevelGenerator:ExtendLevel(currentLength, amount)
    local newSections = {}
    
    for i = 1, amount do
        local sectionNum = currentLength + i
        newSections[i] = self:GenerateSection(sectionNum, "Endless")
        table.insert(self.Sections, newSections[i])
    end
    
    return newSections
end

-- Get section at index
function LevelGenerator:GetSection(index)
    return self.Sections[index]
end

-- Get color at row
function LevelGenerator:GetColorForRow(row)
    return Config.COLORS[row]
end

-- Find safe row for player color
function LevelGenerator:FindSafeRow(sectionIndex, playerColor)
    local section = self.Sections[sectionIndex]
    if not section then return 1 end
    
    for row = 1, 4 do
        if Config.COLORS[row] == playerColor then
            -- Check if this row has platforms
            for _, platform in ipairs(section.platforms) do
                if platform.row == row then
                    return row
                end
            end
        end
    end
    
    return 1 -- Default to row 1
end

return LevelGenerator
