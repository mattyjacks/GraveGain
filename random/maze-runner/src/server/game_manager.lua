-- Maze Runner - Server Game Manager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage.Shared.config)
local MazeGenerator = require(ReplicatedStorage.Shared.maze_generator)

local GameManager = {}

-- Services
GameManager.LeaderboardStore = DataStoreService:GetOrderedDataStore("MazeRunnerLeaderboard")

-- State
GameManager.ActiveGames = {} -- PlayerId -> GameData
GameManager.CurrentMaze = nil
GameManager.MazeFolder = nil

-- Game Data Structure
function GameManager:CreateGameData(player, difficulty)
    return {
        player = player,
        difficulty = difficulty,
        startTime = tick(),
        timeLimit = Config.DIFFICULTIES[difficulty].timeLimit,
        completed = false,
        powerupsCollected = {},
        timeBonus = 0,
    }
end

-- Initialize
function GameManager:Initialize()
    -- Create remotes
    local remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
    
    local startGame = Instance.new("RemoteFunction")
    startGame.Name = "StartGame"
    startGame.Parent = remotes
    
    local finishMaze = Instance.new("RemoteEvent")
    finishMaze.Name = "FinishMaze"
    finishMaze.Parent = remotes
    
    local collectPowerup = Instance.new("RemoteEvent")
    collectPowerup.Name = "CollectPowerup"
    collectPowerup.Parent = remotes
    
    -- Handle remote calls
    startGame.OnServerInvoke = function(player, difficulty)
        return self:StartGame(player, difficulty)
    end
    
    finishMaze.OnServerEvent:Connect(function(player, success, timeTaken)
        self:OnFinishMaze(player, success, timeTaken)
    end)
    
    collectPowerup.OnServerEvent:Connect(function(player, powerupType)
        self:OnCollectPowerup(player, powerupType)
    end)
    
    -- Player events
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerJoined(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerLeft(player)
    end)
    
    print("Maze Runner server initialized!")
end

-- Start new game for player
function GameManager:StartGame(player, difficulty)
    if not Config.DIFFICULTIES[difficulty] then
        difficulty = "Easy"
    end
    
    -- Clean up old maze if exists
    self:ClearPlayerMaze(player)
    
    -- Generate new maze
    local mazeSize = Config.DIFFICULTIES[difficulty].size
    local grid, startPos, endPos = MazeGenerator:Generate(mazeSize)
    
    -- Build maze in workspace
    local mazeFolder = self:BuildMaze(grid, startPos, endPos, MazeGenerator.PowerupPositions, difficulty)
    mazeFolder.Name = "Maze_" .. player.UserId
    mazeFolder.Parent = workspace
    
    -- Store game data
    self.ActiveGames[player.UserId] = self:CreateGameData(player, difficulty)
    
    -- Spawn player at start
    local startWorldPos = MazeGenerator:GridToWorld(startPos.x, startPos.y)
    
    if player.Character then
        local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(startWorldPos + Vector3.new(0, 5, 0))
        end
    end
    
    -- Set up fog
    self:SetFogForPlayer(player, difficulty)
    
    print(player.Name .. " started " .. difficulty .. " maze")
    
    return {
        startPos = startWorldPos,
        endPos = MazeGenerator:GridToWorld(endPos.x, endPos.y),
        timeLimit = Config.DIFFICULTIES[difficulty].timeLimit,
        powerups = MazeGenerator.PowerupPositions,
    }
end

-- Build physical maze
function GameManager:BuildMaze(grid, startPos, endPos, powerups, difficulty)
    local folder = Instance.new("Folder")
    
    local wallColor = Config.WALL_COLORS[math.random(#Config.WALL_COLORS)]
    local floorColor = Config.FLOOR_COLORS[math.random(#Config.FLOOR_COLORS)]
    
    local size = #grid
    
    -- Create floor
    local floor = Instance.new("Part")
    floor.Name = "BaseFloor"
    floor.Size = Vector3.new(size * Config.CELL_SIZE, 1, size * Config.CELL_SIZE)
    floor.Position = Vector3.new((size * Config.CELL_SIZE) / 2 - Config.CELL_SIZE/2, -1, (size * Config.CELL_SIZE) / 2 - Config.CELL_SIZE/2)
    floor.Anchored = true
    floor.Color = floorColor
    floor.Material = Enum.Material.Concrete
    floor.TopSurface = Enum.SurfaceType.Smooth
    floor.Parent = folder
    
    -- Create walls
    for y = 1, size do
        for x = 1, size do
            if grid[y][x] == 0 then
                local wall = Instance.new("Part")
                wall.Name = "Wall_" .. x .. "_" .. y
                wall.Size = Vector3.new(Config.CELL_SIZE, Config.WALL_HEIGHT, Config.CELL_SIZE)
                wall.Position = MazeGenerator:GridToWorld(x, y) + Vector3.new(0, Config.WALL_HEIGHT/2, 0)
                wall.Anchored = true
                wall.Color = wallColor
                wall.Material = Enum.Material.Brick
                wall.TopSurface = Enum.SurfaceType.Smooth
                wall.BottomSurface = Enum.SurfaceType.Smooth
                wall.Parent = folder
            end
        end
    end
    
    -- Create start marker
    local startMarker = Instance.new("Part")
    startMarker.Name = "Start"
    startMarker.Size = Vector3.new(4, 0.5, 4)
    startMarker.Position = MazeGenerator:GridToWorld(startPos.x, startPos.y) + Vector3.new(0, 0.5, 0)
    startMarker.Anchored = true
    startMarker.Color = Color3.fromRGB(0, 255, 0)
    startMarker.Material = Enum.Material.Neon
    startMarker.Transparency = 0.5
    startMarker.CanCollide = false
    startMarker.Parent = folder
    
    -- Create end marker
    local endMarker = Instance.new("Part")
    endMarker.Name = "End"
    endMarker.Size = Vector3.new(4, 6, 4)
    endMarker.Position = MazeGenerator:GridToWorld(endPos.x, endPos.y) + Vector3.new(0, 3, 0)
    endMarker.Anchored = true
    endMarker.Color = Color3.fromRGB(255, 215, 0)
    endMarker.Material = Enum.Material.Neon
    endMarker.Parent = folder
    
    -- End touch detection
    endMarker.Touched:Connect(function(hit)
        local char = hit.Parent
        local touchPlayer = Players:GetPlayerFromCharacter(char)
        if touchPlayer then
            local gameData = self.ActiveGames[touchPlayer.UserId]
            if gameData and not gameData.completed then
                local timeTaken = tick() - gameData.startTime
                self:OnFinishMaze(touchPlayer, true, timeTaken)
            end
        end
    end)
    
    -- Create powerups
    for _, powerup in ipairs(powerups) do
        self:CreatePowerup(powerup, folder)
    end
    
    return folder
end

-- Create powerup
function GameManager:CreatePowerup(powerupData, parent)
    local config = Config.POWERUPS[powerupData.type]
    if not config then return end
    
    local powerup = Instance.new("Part")
    powerup.Name = "Powerup_" .. powerupData.type
    powerup.Shape = Enum.PartType.Ball
    powerup.Size = Vector3.new(3, 3, 3)
    powerup.Position = MazeGenerator:GridToWorld(powerupData.x, powerupData.y) + Vector3.new(0, 3, 0)
    powerup.Anchored = true
    powerup.CanCollide = false
    powerup.Color = config.color
    powerup.Material = Enum.Material.Neon
    powerup.Transparency = 0.3
    powerup:SetAttribute("Type", powerupData.type)
    powerup.Parent = parent
    
    -- Glow effect
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Range = 10
    light.Color = config.color
    light.Parent = powerup
    
    -- Spin animation
    task.spawn(function()
        while powerup and powerup.Parent do
            powerup.CFrame = powerup.CFrame * CFrame.Angles(0, 0.05, 0)
            task.wait(0.03)
        end
    end)
    
    -- Touch detection
    powerup.Touched:Connect(function(hit)
        local char = hit.Parent
        local player = Players:GetPlayerFromCharacter(char)
        if player then
            local gameData = self.ActiveGames[player.UserId]
            if gameData and not gameData.powerupsCollected[powerupData.type] then
                gameData.powerupsCollected[powerupData.type] = true
                
                local remotes = ReplicatedStorage:WaitForChild("Remotes")
                local collectEvent = remotes:WaitForChild("CollectPowerup")
                collectEvent:FireClient(player, powerupData.type)
                
                if powerupData.type == "TimeBonus" then
                    gameData.timeBonus = gameData.timeBonus + config.seconds
                end
                
                powerup:Destroy()
            end
        end
    end)
end

-- Set fog for difficulty
function GameManager:SetFogForPlayer(player, difficulty)
    local fogDensity = Config.DIFFICULTIES[difficulty].fogDensity
    
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local fogEvent = remotes:FindFirstChild("SetFog")
    if fogEvent then
        fogEvent:FireClient(player, fogDensity)
    end
end

-- On maze finish
function GameManager:OnFinishMaze(player, success, timeTaken)
    local gameData = self.ActiveGames[player.UserId]
    if not gameData or gameData.completed then return end
    
    gameData.completed = true
    
    local adjustedTime = timeTaken - gameData.timeBonus
    local timeLimit = gameData.timeLimit
    
    local won = success and adjustedTime <= timeLimit
    
    if won then
        -- Update leaderboard
        pcall(function()
            self.LeaderboardStore:SetAsync(player.UserId, math.floor(adjustedTime * 100))
        end)
        
        print(player.Name .. " completed maze in " .. adjustedTime .. " seconds!")
    else
        print(player.Name .. " failed maze (time: " .. adjustedTime .. ")")
    end
    
    -- Notify client
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local finishEvent = remotes:WaitForChild("GameFinished")
    if finishEvent then
        finishEvent:FireClient(player, won, adjustedTime, timeLimit)
    end
end

-- On collect powerup
function GameManager:OnCollectPowerup(player, powerupType)
    local gameData = self.ActiveGames[player.UserId]
    if not gameData then return end
    
    print(player.Name .. " collected " .. powerupType)
end

-- Clear player's maze
function GameManager:ClearPlayerMaze(player)
    local existing = workspace:FindFirstChild("Maze_" .. player.UserId)
    if existing then
        existing:Destroy()
    end
    
    self.ActiveGames[player.UserId] = nil
end

-- Player events
function GameManager:OnPlayerJoined(player)
    -- Nothing special on join, wait for them to start game
end

function GameManager:OnPlayerLeft(player)
    self:ClearPlayerMaze(player)
end

return GameManager
