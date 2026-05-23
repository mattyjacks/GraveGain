-- Color Rush - Server Game Manager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage.config)
local LevelGenerator = require(ReplicatedStorage.level_generator)

local GameManager = {}

-- State
GameManager.ActiveGames = {}
GameManager.LevelFolder = nil
GameManager.LeaderboardStore = nil

-- Create game data
function GameManager:CreateGameData(player, gameMode)
    local modeConfig = Config.GAME_MODES[gameMode]
    return {
        player = player,
        gameMode = gameMode,
        lives = modeConfig.lives,
        score = 0,
        combo = 0,
        maxCombo = 0,
        distance = 0,
        startTime = tick(),
        activePowerups = {},
        currentColor = Config.PLAYER_COLORS[math.random(#Config.PLAYER_COLORS)],
        isPlaying = true,
    }
end

-- Initialize
function GameManager:Initialize()
    -- Init DataStore (requires API Services enabled in Studio)
    pcall(function()
        GameManager.LeaderboardStore = DataStoreService:GetOrderedDataStore("ColorRushLeaderboard")
    end)

    -- Create remotes
    local remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
    
    local startGame = Instance.new("RemoteFunction")
    startGame.Name = "StartGame"
    startGame.Parent = remotes
    
    local playerAction = Instance.new("RemoteEvent")
    playerAction.Name = "PlayerAction"
    playerAction.Parent = remotes
    
    local gameEvent = Instance.new("RemoteEvent")
    gameEvent.Name = "GameEvent"
    gameEvent.Parent = remotes
    
    -- Handle remotes
    startGame.OnServerInvoke = function(player, gameMode)
        return self:StartGame(player, gameMode)
    end
    
    playerAction.OnServerEvent:Connect(function(player, action, data)
        self:HandlePlayerAction(player, action, data)
    end)
    
    -- Player events
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerJoined(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerLeft(player)
    end)
    
    print("Color Rush server initialized!")
end

-- Start game
function GameManager:StartGame(player, gameMode)
    if not Config.GAME_MODES[gameMode] then
        gameMode = "Classic"
    end
    
    -- Clean up old game
    self:ClearPlayerGame(player)
    
    -- Generate level
    local modeConfig = Config.GAME_MODES[gameMode]
    local length = modeConfig.fixedLength or Config.LEVEL_LENGTH
    local sections = LevelGenerator:GenerateLevel(gameMode, length)
    
    -- Build level
    self.LevelFolder = self:BuildLevel(sections, player)
    
    -- Create game data
    local gameData = self:CreateGameData(player, gameMode)
    self.ActiveGames[player.UserId] = gameData
    
    -- Spawn player
    if player.Character then
        local rootPart = player.Character:WaitForChild("HumanoidRootPart")
        rootPart.CFrame = CFrame.new(0, 0, 5)
        
        -- Set player color
        self:SetPlayerColor(player, gameData.currentColor)
    end
    
    print(player.Name .. " started " .. gameMode .. " mode")
    
    return {
        gameMode = gameMode,
        lives = gameData.lives,
        currentColor = gameData.currentColor,
        sections = sections,
    }
end

-- Build physical level
function GameManager:BuildLevel(sections, player)
    local folder = Instance.new("Folder")
    folder.Name = "Level_" .. player.UserId
    
    for _, section in ipairs(sections) do
        for _, platform in ipairs(section.platforms) do
            local part = Instance.new("Part")
            part.Name = "Platform_" .. section.sectionNum
            part.Size = platform.size
            part.Position = platform.position
            part.Anchored = true
            part.Color = platform.color
            part.Material = Enum.Material.SmoothPlastic
            part.TopSurface = Enum.SurfaceType.Smooth
            part.BottomSurface = Enum.SurfaceType.Smooth
            part:SetAttribute("Section", section.sectionNum)
            part:SetAttribute("Row", platform.row)
            part.Parent = folder
        end
        
        -- Create powerup if any
        if section.powerup then
            local config = Config.POWERUPS[section.powerup.type]
            local powerup = Instance.new("Part")
            powerup.Name = "Powerup_" .. section.powerup.type
            powerup.Shape = Enum.PartType.Ball
            powerup.Size = Vector3.new(3, 3, 3)
            powerup.Position = section.powerup.position
            powerup.Anchored = true
            powerup.CanCollide = false
            powerup.Color = config.color
            powerup.Material = Enum.Material.Neon
            powerup.Transparency = 0.3
            powerup:SetAttribute("Type", section.powerup.type)
            powerup.Parent = folder
            
            -- Spin animation
            task.spawn(function()
                while powerup and powerup.Parent do
                    powerup.CFrame = powerup.CFrame * CFrame.Angles(0, 0.1, 0)
                    task.wait(0.03)
                end
            end)
        end
    end
    
    -- Kill zone (below level)
    local killZone = Instance.new("Part")
    killZone.Name = "KillZone"
    killZone.Size = Vector3.new(1000, 1, 10000)
    killZone.Position = Vector3.new(0, -50, 2500)
    killZone.Anchored = true
    killZone.Transparency = 1
    killZone.CanCollide = false
    killZone.Parent = folder
    
    killZone.Touched:Connect(function(hit)
        local char = hit.Parent
        local touchPlayer = Players:GetPlayerFromCharacter(char)
        if touchPlayer and touchPlayer.UserId == player.UserId then
            self:OnPlayerFall(touchPlayer)
        end
    end)
    
    folder.Parent = workspace
    return folder
end

-- Set player color
function GameManager:SetPlayerColor(player, color)
    if not player.Character then return end
    
    -- Color the character
    for _, part in ipairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Color = color
        end
    end
end

-- Handle player action
function GameManager:HandlePlayerAction(player, action, data)
    local gameData = self.ActiveGames[player.UserId]
    if not gameData or not gameData.isPlaying then return end
    
    if action == "ChangeColor" then
        local newColor = data.color
        gameData.currentColor = newColor
        self:SetPlayerColor(player, newColor)
        
    elseif action == "Score" then
        gameData.score = gameData.score + (data.points or Config.SCORE_PER_PLATFORM)
        gameData.combo = gameData.combo + 1
        gameData.maxCombo = math.max(gameData.maxCombo, gameData.combo)
        
        -- Notify client
        local remotes = ReplicatedStorage:WaitForChild("Remotes")
        local gameEvent = remotes:WaitForChild("GameEvent")
        gameEvent:FireClient(player, "Score", {
            score = gameData.score,
            combo = gameData.combo,
        })
        
    elseif action == "Miss" then
        gameData.combo = 0
        
    elseif action == "CollectPowerup" then
        local powerupType = data.type
        self:ApplyPowerup(player, powerupType)
        
    elseif action == "Complete" then
        self:OnGameComplete(player, data.time)
    end
end

-- Apply powerup
function GameManager:ApplyPowerup(player, powerupType)
    local gameData = self.ActiveGames[player.UserId]
    if not gameData then return end
    
    local config = Config.POWERUPS[powerupType]
    if not config then return end
    
    if powerupType == "ExtraLife" then
        gameData.lives = gameData.lives + config.lives
    else
        gameData.activePowerups[powerupType] = {
            startTime = tick(),
            duration = config.duration,
        }
    end
    
    -- Notify client
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local gameEvent = remotes:WaitForChild("GameEvent")
    gameEvent:FireClient(player, "Powerup", {type = powerupType})
end

-- Player fell
function GameManager:OnPlayerFall(player)
    local gameData = self.ActiveGames[player.UserId]
    if not gameData or not gameData.isPlaying then return end
    
    gameData.lives = gameData.lives - 1
    
    if gameData.lives <= 0 then
        self:EndGame(player, false)
    else
        -- Respawn
        local remotes = ReplicatedStorage:WaitForChild("Remotes")
        local gameEvent = remotes:WaitForChild("GameEvent")
        gameEvent:FireClient(player, "Respawn", {lives = gameData.lives})
        
        -- Reset position
        if player.Character then
            local rootPart = player.Character:WaitForChild("HumanoidRootPart")
            rootPart.CFrame = CFrame.new(0, 0, 5)
        end
    end
end

-- Game complete
function GameManager:OnGameComplete(player, timeTaken)
    local gameData = self.ActiveGames[player.UserId]
    if not gameData then return end
    
    self:EndGame(player, true)
end

-- End game
function GameManager:EndGame(player, won)
    local gameData = self.ActiveGames[player.UserId]
    if not gameData then return end
    
    gameData.isPlaying = false
    
    local timeTaken = tick() - gameData.startTime
    
    if won then
        -- Update leaderboard
        pcall(function()
            self.LeaderboardStore:SetAsync(player.UserId, gameData.score)
        end)
    end
    
    -- Notify client
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local gameEvent = remotes:WaitForChild("GameEvent")
    gameEvent:FireClient(player, "GameOver", {
        won = won,
        score = gameData.score,
        maxCombo = gameData.maxCombo,
        time = timeTaken,
    })
end

-- Clear player's game
function GameManager:ClearPlayerGame(player)
    local existing = workspace:FindFirstChild("Level_" .. player.UserId)
    if existing then
        existing:Destroy()
    end
    
    self.ActiveGames[player.UserId] = nil
end

-- Player events
function GameManager:OnPlayerJoined(player)
    -- Nothing special
end

function GameManager:OnPlayerLeft(player)
    self:ClearPlayerGame(player)
end

return GameManager
