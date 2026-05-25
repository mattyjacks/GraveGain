-- DwarfDrop: main.client.lua
-- Client entry point: wires all client systems together

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Networking      = require(game.ReplicatedStorage.Shared.networking)
local GameData        = require(game.ReplicatedStorage.Shared.game_data)
local BiomeData       = require(game.ReplicatedStorage.Shared.biome_data)

local FPSCamera       = require(script.Parent.fps_camera)
local Movement        = require(script.Parent.movement)
local HUD             = require(script.Parent.hud)
local HubUI           = require(script.Parent.hub_ui)
local BackpackUI      = require(script.Parent.backpack_ui)
local PickaxeModel    = require(script.Parent.pickaxe_model)
local ActiveItem      = require(script.Parent.active_item)
local SlimeEnemy      = require(script.Parent.slime_enemy)
local MovingPlatforms = require(script.Parent.moving_platforms)
local Visuals         = require(script.Parent.visuals)

local player = Players.LocalPlayer

-- ==================== OBJECT CONSTRUCTION ====================
-- FIX Bug#9: Build HUD first, then pass its screenGui to BackpackUI

local camera    = FPSCamera.new()
local hud       = HUD.new()
local hubUI     = HubUI.new()
local backpackUI = BackpackUI.new()
local movement  = Movement.new(camera)
local pickaxe   = PickaxeModel.new(camera)
local visuals   = Visuals.new()
local platforms = MovingPlatforms.new()

-- Build UIs
-- FIX Bug#9: HUD:Build() returns self; screenGui is available immediately after
hud:Build()
backpackUI:Build(hud.screenGui)  -- pass screenGui directly; no race condition

hubUI:Build()
hubUI:SetCameraRef(camera)

-- Wire movement references
movement:SetHUD(hud)
movement:SetVisuals(visuals)
movement:SetPickaxe(pickaxe)

local slimeSystem = SlimeEnemy.GetSlimeSystem()
movement:SetSlimeSystem(slimeSystem)

-- Wire pickaxe -> movement for grab mechanic
pickaxe:SetMovement(movement)

local activeItemCtrl = ActiveItem.new(backpackUI, hud)

-- ==================== STATE ====================

local inHub              = true
local inLevel            = false
local awaitingDeathChoice = false  -- true while death screen is showing; blocks enterHub on CharacterAdded
local currentModeId   = "Singleplayer"
local currentBiomeSeq = nil
local lastBiome       = nil
local speedTracker    = { lastPos = nil, timer = 0 }
local timerRunning    = false
local timerSeconds    = 0

-- ==================== HUB SETUP ====================

local function enterHub()
    inHub               = true
    inLevel             = false
    awaitingDeathChoice = false
    timerRunning        = false

    hud:Hide()
    hud:HideDeath()
    hud:HideWin()
    backpackUI:Hide()
    hubUI:Show()

    -- Hub uses Roblox default camera - stop FPS camera so mouse moves freely
    camera:Stop()
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    local char = player.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        workspace.CurrentCamera.CameraSubject = hum
        hum.AutoRotate = true
    end
    UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true

    -- Fetch player data for UI
    local rf = Networking.GetFunction(Networking.Functions.GetPlayerData)
    if rf then
        local ok, result = pcall(function() return rf:InvokeServer() end)
        if ok and result then
            hubUI:SetPlayerData(result)
        end
    end

    movement:Stop()
    pickaxe:Unequip()
    activeItemCtrl:Stop()
    SlimeEnemy.StopManager()
    platforms:Stop()
end

local function enterLevel(seed, modeId, biomeSequence)
    inHub   = false
    inLevel = true
    currentModeId   = modeId or "Singleplayer"
    currentBiomeSeq = biomeSequence

    hubUI:Hide()
    hud:Show()
    backpackUI:Show()

    camera:Start("fps")
    movement:Start()
    pickaxe:Equip()
    activeItemCtrl:Start()
    task.defer(function()
        activeItemCtrl:AutoEnableLantern()  -- build flashlight anchor + turn lantern on
    end)
    SlimeEnemy.StartManager()
    platforms:Start()

    timerRunning = true
    timerSeconds = 0

    -- Initial biome lighting - reset cache so it always applies fresh
    visuals:ResetLighting()
    local Lighting = game:GetService("Lighting")
    Lighting.Brightness = 7.0  -- immediate baseline so level isn't black
    if biomeSequence and biomeSequence[1] then
        visuals:UpdateBiomeLighting(biomeSequence[1], 1.0)
        hud:ShowBiomeChange(biomeSequence[1].name)
        lastBiome = biomeSequence[1].name
    end

    hud:UpdateAirJumps(0, 0)
    hud:UpdateCombo(0, 1)

    -- Request leaderboard preload
    Networking.FireServer(Networking.Events.RequestLeaderboard)
end

-- ==================== PROXIMITY PROMPTS (hub) ====================

local proximityCheckConn = nil
local PROXIMITY_RANGE    = 10

local function startProximityLoop()
    if proximityCheckConn then proximityCheckConn:Disconnect() end
    proximityCheckConn = RunService.Heartbeat:Connect(function()
        if not inHub then return end
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local pos  = hrp.Position
        local nearest, nearDist, nearType = nil, PROXIMITY_RANGE + 1, nil

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local isPortal   = obj:FindFirstChild("IsPortal")
                local isShop     = obj:FindFirstChild("IsUpgradeShop")
                local isKiosk    = obj:FindFirstChild("IsSeedKiosk")
                local isLB       = obj:FindFirstChild("IsLeaderboardWall")
                if isPortal or isShop or isKiosk or isLB then
                    local d = (pos - obj.Position).Magnitude
                    if d < nearDist then
                        nearDist = d
                        nearest  = obj
                        if isPortal then nearType = "portal"
                        elseif isShop then nearType = "shop"
                        elseif isKiosk then nearType = "kiosk"
                        elseif isLB then nearType = "leaderboard"
                        end
                    end
                end
            end
        end

        if nearest and nearDist <= PROXIMITY_RANGE then
            local labels = {
                portal      = "[ E ] Enter the Drop",
                shop        = "[ E ] Upgrade Shop",
                kiosk       = "[ E ] Seed Kiosk",
                leaderboard = "[ E ] Leaderboard",
            }
            hubUI.promptLabel.Text    = labels[nearType] or "[ E ]"
            hubUI.promptLabel.Visible = true
        else
            hubUI.promptLabel.Visible = false
        end
    end)
end

local eWasDown = false
RunService.Heartbeat:Connect(function()
    if not inHub then eWasDown = UserInputService:IsKeyDown(Enum.KeyCode.E); return end
    local eDown = UserInputService:IsKeyDown(Enum.KeyCode.E)
    if eDown and not eWasDown then
        -- Determine what we're near
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then eWasDown = eDown; return end
        local pos = hrp.Position

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local d = (pos - obj.Position).Magnitude
                if d > PROXIMITY_RANGE then continue end
                if obj:FindFirstChild("IsPortal") then
                    local seed   = hubUI:GetPendingSeed()
                    local modeId = "Singleplayer"
                    Networking.FireServer(Networking.Events.RequestStartLevel, seed, modeId)
                    break
                elseif obj:FindFirstChild("IsUpgradeShop") then
                    hubUI:OpenPanel("upgrade")
                    break
                elseif obj:FindFirstChild("IsSeedKiosk") then
                    hubUI:OpenPanel("seed")
                    break
                elseif obj:FindFirstChild("IsLeaderboardWall") then
                    hubUI:OpenPanel("leaderboard")
                    break
                end
            end
        end
    end
    eWasDown = eDown
end)

-- ==================== SWING INPUT ====================

local mouseWasDown = false
RunService.Heartbeat:Connect(function(dt)
    if not inLevel then
        mouseWasDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        return
    end
    local mouseDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    if mouseDown and not mouseWasDown then
        pickaxe:TrySwing(currentModeId, nil)
    end
    mouseWasDown = mouseDown
    pickaxe:Update(dt)
end)

-- ==================== SPEED TRACKER ====================

RunService.Heartbeat:Connect(function(dt)
    if not inLevel then return end
    speedTracker.timer = speedTracker.timer + dt
    if speedTracker.timer < 0.1 then return end

    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then speedTracker.timer = 0; return end

    local pos = hrp.Position
    if speedTracker.lastPos then
        local dist  = (pos - speedTracker.lastPos).Magnitude
        local speed = dist / speedTracker.timer
        hud:UpdateSpeed(speed)
    end
    speedTracker.lastPos  = pos
    speedTracker.timer    = 0
end)

-- ==================== TIMER ====================

RunService.Heartbeat:Connect(function(dt)
    if not timerRunning then return end
    timerSeconds = timerSeconds + dt
    hud:UpdateTimer(timerSeconds)
end)

-- ==================== BIOME DEPTH CHANGE CHECK ====================

RunService.Heartbeat:Connect(function()
    if not inLevel or not currentBiomeSeq then return end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local depth = GameData.WorldYToDepth(hrp.Position.Y)
    local biome = BiomeData.GetBiomeAtDepthInSequence(currentBiomeSeq, depth)
    if biome and biome.name ~= lastBiome then
        lastBiome = biome.name
        visuals:UpdateBiomeLighting(biome)
        hud:ShowBiomeChange(biome.name)
    end
end)

-- ==================== CHUNK REQUEST ====================
-- FIX Bug#8: client sends RequestChunkLoad when depth crosses slot boundary

local lastRequestedSlot = 2  -- first 2 are pre-generated

RunService.Heartbeat:Connect(function()
    if not inLevel then return end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local depth     = GameData.WorldYToDepth(hrp.Position.Y)
    local slotIndex = math.floor(depth / GameData.SLOT_DEPTH_METERS) + 1
    -- Request next slot when player enters current slot
    local nextSlot  = slotIndex + 1
    if nextSlot <= 10 and nextSlot > lastRequestedSlot then
        lastRequestedSlot = nextSlot
        Networking.FireServer(Networking.Events.RequestChunkLoad, nextSlot)
    end
end)

-- ==================== NETWORKING EVENTS ====================

-- Level generated: server is ready, client transitions to level
Networking.OnClient(Networking.Events.LevelGenerated, function(info)
    local seed     = info and info.seed    or "MattyJacks"
    local modeId   = info and info.modeId  or "Singleplayer"
    local biomSeq  = info and info.biomeSequence or nil
    lastRequestedSlot = 2
    enterLevel(seed, modeId, biomSeq)
end)

-- Basket launch: trigger visual effect
Networking.OnClient(Networking.Events.TriggerBasketLaunch, function()
    local basket = workspace:FindFirstChild("DwarvenEntryBasket", true)
    if basket then
        visuals:ShowBasketLaunchEffect(basket)
    end
    camera:ApplyShake(3, 1.2, 18)
end)

-- Depth update from server
Networking.OnClient(Networking.Events.DepthUpdate, function(depth)
    hud:UpdateDepth(depth)
end)

-- Health update
Networking.OnClient(Networking.Events.HealthUpdate, function(current, max)
    hud:UpdateHealth(current, max)
    if current <= 0 then camera:EnterDeathView() end
end)

-- Stats update (upgrades purchased)
Networking.OnClient(Networking.Events.StatsUpdate, function(stats)
    if stats then
        movement:ApplyStats(stats)
        hud:UpdateAirJumps(stats.airJumps, stats.airJumps)
    end
end)

-- Weight update
Networking.OnClient(Networking.Events.WeightUpdate, function(data)
    if data and movement then
        movement:SetWeightEffects(data.speedMult)
    end
end)

-- Gold update
Networking.OnClient(Networking.Events.GoldUpdate, function(amount)
    hud:UpdateGold(amount)
    hubUI:SetPlayerData({ gold = amount })
end)

-- Modifier set
Networking.OnClient(Networking.Events.ModifierSet, function(modifier)
    movement:SetModifier(modifier)
    hud:SetModifier(modifier)
end)

-- Camera shake
Networking.OnClient(Networking.Events.CameraShakeSignal, function(magnitude, duration)
    camera:ApplyShake(magnitude, duration)
end)

-- Mining nugget spawn (cosmetic)
Networking.OnClient(Networking.Events.SpawnMiningNugget, function(data)
    if not data then return end
    local p = Instance.new("Part")
    p.Size   = Vector3.new(0.6, 0.6, 0.6)
    p.Color  = Color3.fromRGB(255, 210, 40)
    p.Material = Enum.Material.SmoothPlastic
    p.CFrame = CFrame.new(data.pos or Vector3.new(0,0,0))
    p.Parent = workspace
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e4,1e4,1e4)
    bv.Velocity = Vector3.new((math.random()-0.5)*10, math.random()*15+8, (math.random()-0.5)*10)
    bv.Parent = p
    game:GetService("Debris"):AddItem(p, 3)
end)

-- Player died
Networking.OnClient(Networking.Events.PlayerDied, function(info)
    timerRunning          = false
    inLevel               = false   -- stop level tick loops
    awaitingDeathChoice   = true    -- block onCharacterAdded from instantly enterHub

    camera:EnterDeathView()         -- unlock mouse so buttons are clickable
    movement:Stop()
    pickaxe:Unequip()
    activeItemCtrl:Stop()
    SlimeEnemy.StopManager()

    hud:ShowDeath(
        info and info.depth or 0,
        info and info.goldEarned or 0,
        function(choice)
            awaitingDeathChoice = false
            hud:HideDeath()
            camera:LeaveDeathView()
            Networking.FireServer(Networking.Events.DeathChoice, choice)
            if choice == "respawnHub" or choice == "resetHub" then
                enterHub()
            else
                -- Will re-enter level on RespawnInBasket event
            end
        end
    )
end)

-- Respawn in basket
Networking.OnClient(Networking.Events.RespawnInBasket, function(data)
    awaitingDeathChoice = false
    hud:HideDeath()
    camera:LeaveDeathView()
    if data and data.reset then
        timerSeconds = 0
    end
    timerRunning = true
    movement:Start()
    pickaxe:Equip()
    activeItemCtrl:Start()
    SlimeEnemy.StartManager()
end)

-- Respawn in hub
Networking.OnClient(Networking.Events.RespawnInHub, function()
    inLevel = false
    enterHub()
end)

-- Player won
Networking.OnClient(Networking.Events.PlayerWon, function(info)
    timerRunning = false
    movement:Stop()
    pickaxe:Unequip()
    activeItemCtrl:Stop()
    SlimeEnemy.StopManager()
    hud:ShowWin(
        info and info.timeSeconds or timerSeconds,
        info and info.rank or 999,
        info and info.goldEarned or 0
    )
    task.delay(6, function()
        hud:HideWin()
        enterHub()
    end)
end)

-- Leaderboard
Networking.OnClient(Networking.Events.LeaderboardUpdate, function(data)
    hubUI:UpdateLeaderboard(data)
end)

-- Treasure chest opened - celebrate!
Networking.OnClient(Networking.Events.TreasureChestOpened, function(info)
    if not info then return end
    camera:ApplyShake(2.5, 0.4, 18)
    if visuals then visuals:PulseCoinCollect() end
    hud:ShowBiomeChange("TREASURE! +" .. (info.gold or 0) .. "G")
end)

-- Chunk loaded
Networking.OnClient(Networking.Events.ChunkLoaded, function(slotIndex)
    -- Client acknowledged; nothing extra needed
end)

-- Unload chunk
Networking.OnClient(Networking.Events.UnloadChunk, function(slotIndex)
    -- Client acknowledged
end)

-- Coop: downed
Networking.OnClient(Networking.Events.PlayerDowned, function(info)
    if info and info.userId == player.UserId then
        hud:ShowDowned()
        movement:Stop()
        camera:EnterDeathView()
    end
end)

-- Coop: rescued
Networking.OnClient(Networking.Events.PlayerRescued, function(info)
    if info and info.userId == player.UserId then
        hud:HideDowned()
        camera:LeaveDeathView()
        movement:Start()
    end
end)

-- Coop: rescue progress
Networking.OnClient(Networking.Events.RescueProgress, function(progress)
    hud:ShowRescueProgress(progress)
end)

-- PvP: hit
Networking.OnClient(Networking.Events.PlayerHit, function(info)
    if not info then return end
    camera:ApplyShake(info.damage and info.damage / 20 or 1.5, 0.3)
    hud:FlashDamage(0.5)
    -- Apply knockback impulse
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and info.knockbackDir then
        local dir   = Vector3.new(info.knockbackDir.x, info.knockbackDir.y, info.knockbackDir.z)
        local force = info.knockbackForce or 80
        hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + dir * force
    end
end)

-- Game mode changed
Networking.OnClient(Networking.Events.GameModeChanged, function(modeId)
    currentModeId = modeId or "Singleplayer"
end)

-- ==================== CHARACTER ADDED ====================

local function onCharacterAdded(char)
    -- Re-attach camera + reset movement on respawn
    task.wait(0.15)
    if awaitingDeathChoice then
        -- Death screen is showing: keep mouse free, don't enter hub yet.
        -- The death choice callback will call enterHub() or wait for RespawnInBasket.
        camera:EnterDeathView()
        return
    end
    if inLevel then
        camera:Start("fps")
        movement:Start()
    else
        enterHub()
    end
end

player.CharacterAdded:Connect(onCharacterAdded)

-- ==================== INIT ====================

-- Start proximity loop for hub interactions
startProximityLoop()

-- Initial state: hub
if player.Character then
    enterHub()
else
    player.CharacterAdded:Wait()
    enterHub()
end
