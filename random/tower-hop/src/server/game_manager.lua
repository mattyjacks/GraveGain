-- Tower Hop - Server Game Manager
-- Handles tower generation, checkpoints, and leaderboards

print("[SERVER] game_manager module loading...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Will be loaded in Initialize() after Rojo sync
local Config = nil
local TowerGenerator = nil

local GameManager = {}

-- Services (wrapped in pcall for Studio compatibility)
local success1, LeaderboardStore = pcall(function()
    return DataStoreService:GetOrderedDataStore("TowerHopLeaderboard")
end)
local success2, PlayerDataStore = pcall(function()
    return DataStoreService:GetDataStore("TowerHopPlayerData")
end)

GameManager.LeaderboardStore = success1 and LeaderboardStore or nil
GameManager.PlayerDataStore = success2 and PlayerDataStore or nil

-- State
GameManager.ActiveTowers = {}
GameManager.PlayerProgress = {} -- floor reached, best floor
GameManager.CheckpointFolder = nil
GameManager.IsInitialized = false
GameManager.IsInitializing = false

-- Initialize game
function GameManager:Initialize()
    if self.IsInitialized or self.IsInitializing then
        return
    end
    
    self.IsInitializing = true
    print("[SERVER] GameManager: Initializing...")
    
    -- Wait for shared folder and load modules (shorter timeout for Studio)
    local shared = ReplicatedStorage:WaitForChild("Shared", 5)
    if not shared then
        warn("[SERVER] GameManager: Shared folder not found!")
        self.IsInitializing = false
        return
    end
    
    print("[SERVER] GameManager: Found Shared folder, loading modules...")
    
    -- Poll for modules to be available
    local startTime = tick()
    local modulesLoaded = false
    while tick() - startTime < 5 do
        local success, err = pcall(function()
            Config = require(shared.config)
            TowerGenerator = require(shared.tower_generator)
        end)
        if success and Config and TowerGenerator then
            print("[SERVER] GameManager: Modules loaded successfully!")
            modulesLoaded = true
            break
        else
            print("[SERVER] GameManager: Module load attempt failed, retrying...")
        end
        task.wait(0.5)
    end
    
    if not modulesLoaded then
        warn("[SERVER] GameManager: Failed to load shared modules after retries!")
        self.IsInitializing = false
        return
    end
    
    -- Create tower folder
    self.CheckpointFolder = Instance.new("Folder")
    self.CheckpointFolder.Name = "Tower"
    self.CheckpointFolder.Parent = workspace
    print("[SERVER] GameManager: Created Tower folder in workspace")
    
    -- Generate first 20 floors
    print("[SERVER] GameManager: Generating first 20 floors...")
    for i = 1, 20 do
        local floor = TowerGenerator:GenerateFloor(i, self.CheckpointFolder)
        if floor then
            print("[SERVER] GameManager: Generated floor " .. i .. " with " .. #floor.platforms .. " platforms")
        else
            warn("[SERVER] GameManager: Failed to generate floor " .. i)
        end
        task.wait(0.05) -- Stagger generation
    end
    print("[SERVER] GameManager: Floor generation complete!")
    
    -- Setup player events
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerJoined(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerLeft(player)
    end)
    
    -- Setup checkpoint detection
    self:SetupCheckpointDetection()
    
    -- Setup moving platforms
    self:StartMovingPlatforms()
    
    self.IsInitialized = true
    self.IsInitializing = false
    print("[SERVER] Tower Hop server initialized!")
end

-- Player joined
function GameManager:OnPlayerJoined(player)
    -- Lazy initialization: generate tower if not exists
    if not self.IsInitialized then
        print("[SERVER] GameManager: Lazy initializing tower for first player...")
        self:Initialize()
        -- If still not initialized, something is wrong
        if not self.IsInitialized then
            warn("[SERVER] GameManager: Failed to initialize!")
            return
        end
    end
    
    -- Load player data (only if DataStore available)
    local data = nil
    if self.PlayerDataStore then
        local success, result = pcall(function()
            return self.PlayerDataStore:GetAsync(player.UserId)
        end)
        if success then data = result end
    end
    
    if data then
        self.PlayerProgress[player.UserId] = {
            bestFloor = data.bestFloor or 1,
            currentFloor = data.currentFloor or 1,
            totalJumps = data.totalJumps or 0,
        }
    else
        self.PlayerProgress[player.UserId] = {
            bestFloor = 1,
            currentFloor = 1,
            totalJumps = 0,
        }
    end
    
    -- Spawn player at their checkpoint
    player.CharacterAdded:Connect(function(char)
        self:SpawnPlayerAtCheckpoint(player, char)
    end)
    
    -- Initial spawn
    if player.Character then
        self:SpawnPlayerAtCheckpoint(player, player.Character)
    end
end

-- Player left
function GameManager:OnPlayerLeft(player)
    -- Save progress (only if DataStore available)
    local progress = self.PlayerProgress[player.UserId]
    if progress then
        if self.PlayerDataStore then
            pcall(function()
                self.PlayerDataStore:SetAsync(player.UserId, progress)
            end)
        end
        
        -- Update leaderboard
        if progress.bestFloor > 1 and self.LeaderboardStore then
            pcall(function()
                self.LeaderboardStore:SetAsync(player.UserId, progress.bestFloor)
            end)
        end
    end
    
    self.PlayerProgress[player.UserId] = nil
end

-- Spawn player at their checkpoint
function GameManager:SpawnPlayerAtCheckpoint(player, character)
    local progress = self.PlayerProgress[player.UserId]
    if not progress then return end
    
    local spawnFloor = progress.currentFloor
    local spawnPos = TowerGenerator:GetSpawnLocation(spawnFloor)
    
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    
    task.wait(0.1)
    rootPart.CFrame = CFrame.new(spawnPos)
    
    -- Notify client
    local event = ReplicatedStorage:FindFirstChild("FloorUpdate")
    if event then
        event:FireClient(player, spawnFloor, progress.bestFloor)
    end
end

-- Setup checkpoint detection
function GameManager:SetupCheckpointDetection()
    workspace.Tower.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") and descendant:GetAttribute("IsCheckpoint") then
            descendant.Touched:Connect(function(hit)
                local char = hit.Parent
                local player = Players:GetPlayerFromCharacter(char)
                if not player then return end
                
                local floorNum = descendant:GetAttribute("FloorNum")
                if not floorNum then return end
                
                self:OnCheckpointReached(player, floorNum)
            end)
        end
    end)
end

-- Checkpoint reached
function GameManager:OnCheckpointReached(player, floorNum)
    local progress = self.PlayerProgress[player.UserId]
    if not progress then return end
    
    -- Only count if it's a new floor
    if floorNum > progress.currentFloor then
        progress.currentFloor = floorNum
        
        if floorNum > progress.bestFloor then
            progress.bestFloor = floorNum
        end
        
        -- Generate more floors ahead
        local ahead = floorNum + 20
        for i = floorNum + 1, ahead do
            if not TowerGenerator.GeneratedFloors[i] then
                TowerGenerator:GenerateFloor(i, self.CheckpointFolder)
            end
        end
        
        -- Notify client
        local event = ReplicatedStorage:FindFirstChild("FloorUpdate")
        if event then
            event:FireClient(player, floorNum, progress.bestFloor)
        end
        
        print(player.Name .. " reached floor " .. floorNum)
    end
end

-- Moving platforms system
function GameManager:StartMovingPlatforms()
    task.spawn(function()
        while true do
            task.wait(0.03) -- 30fps update
            
            if not self.CheckpointFolder then continue end
            
            for _, part in ipairs(self.CheckpointFolder:GetDescendants()) do
                if part:IsA("BasePart") and part:GetAttribute("IsMoving") then
                    local speed = part:GetAttribute("MoveSpeed") or 2
                    local startPos = part:GetAttribute("StartPos")
                    local endPos = part:GetAttribute("EndPos")
                    
                    if startPos and endPos then
                        local time = tick() * speed
                        local alpha = (math.sin(time) + 1) / 2
                        part.Position = startPos:Lerp(endPos, alpha)
                    end
                end
            end
        end
    end)
end

print("[SERVER] game_manager module loaded, returning...")
return GameManager
