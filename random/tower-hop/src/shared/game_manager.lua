-- Tower Hop - Server Game Manager
-- Handles tower generation, checkpoints, and leaderboards

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage.Shared.config)
local TowerGenerator = require(ReplicatedStorage.Shared.tower_generator)

local GameManager = {}

-- Services
GameManager.LeaderboardStore = DataStoreService:GetOrderedDataStore("TowerHopLeaderboard")
GameManager.PlayerDataStore = DataStoreService:GetDataStore("TowerHopPlayerData")

-- State
GameManager.ActiveTowers = {}
GameManager.PlayerProgress = {}
GameManager.CheckpointFolder = nil

-- Initialize game
function GameManager:Initialize()
    -- Create tower folder
    self.CheckpointFolder = Instance.new("Folder")
    self.CheckpointFolder.Name = "Tower"
    self.CheckpointFolder.Parent = workspace
    
    -- Generate first 20 floors
    for i = 1, 20 do
        TowerGenerator:GenerateFloor(i, self.CheckpointFolder)
        task.wait(0.05)
    end
    
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
    
    print("Tower Hop server initialized!")
end

-- Player joined
function GameManager:OnPlayerJoined(player)
    -- Load player data
    local success, data = pcall(function()
        return self.PlayerDataStore:GetAsync(player.UserId)
    end)
    
    if success and data then
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
    
    if player.Character then
        self:SpawnPlayerAtCheckpoint(player, player.Character)
    end
end

-- Player left
function GameManager:OnPlayerLeft(player)
    local progress = self.PlayerProgress[player.UserId]
    if progress then
        pcall(function()
            self.PlayerDataStore:SetAsync(player.UserId, progress)
        end)
        
        if progress.bestFloor > 1 then
            pcall(function()
                self.LeaderboardStore:SetAsync(player.UserId, progress.bestFloor)
            end)
        end
    end
    
    self.PlayerProgress[player.UserId] = nil
end

-- Spawn player at checkpoint
function GameManager:SpawnPlayerAtCheckpoint(player, character)
    local progress = self.PlayerProgress[player.UserId]
    if not progress then return end
    
    local spawnFloor = progress.currentFloor
    local spawnPos = TowerGenerator:GetSpawnLocation(spawnFloor)
    
    local rootPart = character:WaitForChild("HumanoidRootPart")
    task.wait(0.1)
    rootPart.CFrame = CFrame.new(spawnPos)
    
    local event = ReplicatedStorage:FindFirstChild("FloorUpdate")
    if event then
        event:FireClient(player, spawnFloor, progress.bestFloor)
    end
end

-- Checkpoint detection
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
        
        local event = ReplicatedStorage:FindFirstChild("FloorUpdate")
        if event then
            event:FireClient(player, floorNum, progress.bestFloor)
        end
    end
end

-- Moving platforms
function GameManager:StartMovingPlatforms()
    task.spawn(function()
        while true do
            task.wait(0.03)
            
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

return GameManager
