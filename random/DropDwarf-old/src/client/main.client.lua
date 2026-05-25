-- DropDwarf: main.client.lua
-- Client entry point: wires all systems together

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Networking  = require(game.ReplicatedStorage.Shared.networking)
local GameData    = require(game.ReplicatedStorage.Shared.game_data)
local UpgradeData = require(game.ReplicatedStorage.Shared.upgrade_data)

local FPSCamera        = require(script.Parent.fps_camera)
local PickaxeModel     = require(script.Parent.pickaxe_model)
local Movement         = require(script.Parent.movement)
local HUD              = require(script.Parent.hud)
local HubUI            = require(script.Parent.hub_ui)
local Visuals          = require(script.Parent.visuals)
local SlimeEnemy       = require(script.Parent.slime_enemy)
local MovingPlatforms  = require(script.Parent.moving_platforms)
local ActiveItem       = require(script.Parent.active_item)
local BackpackUI       = require(script.Parent.backpack_ui)
local GameMode         = require(game.ReplicatedStorage.Shared.game_mode)

local player = Players.LocalPlayer

-- ==================== SYSTEM INSTANCES ====================
local camera          = FPSCamera.new()
local pickaxe         = PickaxeModel.new(workspace.CurrentCamera)
local hud             = HUD.new()
local hubUI           = HubUI.new()
local movement        = Movement.new(camera)
local visuals         = Visuals.new()
local slimes          = SlimeEnemy.new()
local movingPlatforms = MovingPlatforms.new()
local activeItem      = ActiveItem.new(camera, movement)
local backpackUI      = BackpackUI.new()

movement.visualsRef = visuals

-- ==================== STATE ====================
local State = {
    inHub        = true,
    inLevel      = false,
    currentDepth = 0,
    timerActive  = false,
    timer        = 0,
    timerConnection = nil,
    gold         = 0,
    health       = 100,
    maxHealth    = 100,
    modifier     = "Normal",  -- active run modifier id
    stats        = nil,       -- last received ComputeStats table
    dropType     = "fps",     -- "fps" or "tps"
    gameModeId   = "Singleplayer",
    downdedPlayers = {},  -- [userId] = { name, bleedTimer }
    rescuing       = nil, -- userId being rescued
    lastLoadedSlot = 2,
}

-- Build static UIs
hud:Build()
hubUI:Build()
hubUI.onChangeCamera = function(camType)
    State.dropType = camType
    -- Only start camera if character is loaded (onCharacterAdded handles initial start)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        camera:Start(camType)
        if pickaxe then
            pickaxe:SetThirdPerson(camType == "tps")
        end
    end
end
visuals:Setup()
-- Build backpack onto same ScreenGui as HUD
if hud.screenGui then
    backpackUI:Build(hud.screenGui)
end

-- Start pickaxe viewmodel in the hub once PlayerGui is ready.
-- Runs in a separate thread so WaitForChild never blocks this script.
task.spawn(function()
    player:WaitForChild("PlayerGui")
    pickaxe:Start(
        function() return false end,   -- not moving in hub
        function() return false end    -- not falling in hub
    )
end)

-- ==================== HUB PROXIMITY ====================
local PROXIMITY_RANGE = 18

local function checkHubProximity()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local pos = hrp.Position

    -- Portal
    local portalGlow = workspace:FindFirstChild("Hub") and
        workspace.Hub:FindFirstChild("PortalGlow")
    if portalGlow then
        local dist = (portalGlow.Position - pos).Magnitude
        if dist < PROXIMITY_RANGE then
            hubUI:ShowPrompt("[E] Enter the Drop - Seed: " .. hubUI:GetCurrentSeed())
            if UserInputService:IsKeyDown(Enum.KeyCode.E) or dist < 6 then
                hubUI:HidePrompt()
                enterLevel()
            end
            return
        end
    end

    -- Seed kiosk
    local kioskBase = workspace:FindFirstChild("Hub") and
        workspace.Hub:FindFirstChild("SeedKiosk")
    if kioskBase then
        local dist = (kioskBase.Position - pos).Magnitude
        if dist < PROXIMITY_RANGE then
            hubUI:ShowPrompt("[E] Set Level Seed")
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                if not hubUI.seedOpen then hubUI:OpenSeed() end
            end
            return
        end
    end

    -- Upgrade shops
    local hub = workspace:FindFirstChild("Hub")
    if hub then
        for _, child in ipairs(hub:GetChildren()) do
            if child.Name:match("^ShopDetector_") then
                local upgradeTag = child:FindFirstChild("UpgradeId")
                if upgradeTag then
                    local dist = (child.Position - pos).Magnitude
                    if dist < PROXIMITY_RANGE + 4 then
                        local upg = UpgradeData.Upgrades[upgradeTag.Value]
                        local label = upg and upg.displayName or upgradeTag.Value
                        hubUI:ShowPrompt("[E] Upgrade: " .. label)
                        if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                            if not hubUI.shopOpen then
                                hubUI:OpenShop(upgradeTag.Value)
                            end
                        end
                        return
                    end
                end
            end
        end
    end

    -- Leaderboard
    local lbWall = hub and hub:FindFirstChild("LeaderboardWall")
    if lbWall then
        local dist = (lbWall.Position - pos).Magnitude
        if dist < PROXIMITY_RANGE + 8 then
            hubUI:ShowPrompt("[E] View Leaderboard")
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                if not hubUI.leaderboardOpen then hubUI:OpenLeaderboard() end
            end
            return
        end
    end

    hubUI:HidePrompt()
end

-- ==================== ENTER / EXIT LEVEL ====================
function enterLevel()
    if State.inLevel then return end
    local seed = hubUI:GetCurrentSeed()
    State.dropType  = hubUI:GetDropType()
    State.gameModeId = hubUI:GetGameMode()
    Networking.FireServer(Networking.Events.RequestStartLevel, seed)
end
-- Wire lobby start button now that enterLevel is defined
hubUI.onStartRun = function() enterLevel() end

local function onLevelGenerated(data)
    State.inLevel = true
    State.inHub = false
    State.currentDepth = 0
    State.timer = 0
    State.lastLoadedSlot = 2

    -- Switch UI
    hubUI:SetVisible(false)
    hud:Show()
    hud:HideDeath()
    hud:HideWin()
    hud:UpdateDepth(0)
    hud:UpdateTimer(0)
    hud:UpdateHealth(State.health, State.maxHealth)
    hud:UpdateGold(State.gold)

    -- Wire cross-system references
    movement:SetSlimeSystem(slimes)
    movement:SetHUD(hud)
    pickaxe:SetMovement(movement)

    -- Apply modifier if one is pending
    local activeMod = State.modifier and GameData.RunModifiers[State.modifier] or GameData.RunModifiers.Normal
    movement:SetModifier(activeMod)
    hud:SetModifier(activeMod)

    -- Apply stats if we have them
    if State.stats then
        movement:ApplyStats(State.stats)
        hud:UpdateAirJumps(State.stats.airJumps or 0, State.stats.airJumps or 0)
    end

    -- Re-apply jump disable: server applyStats replication can race and set
    -- JumpHeight > 0 just after this event fires, re-arming Roblox's jump system.
    local char = player.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        hum.AutoJumpEnabled = false
        hum.JumpHeight      = 0
        hum.JumpPower       = 0
    end

    local dropMode = State.dropType or "fps"
    camera:Start(dropMode)
    movement:Start()
    activeItem:SetHUD(hud)
    activeItem:Start()
    backpackUI:Show()
    backpackUI:ConnectInput()
    pickaxe:Start(
        function() return movement:IsMoving() end,
        function() return movement:IsFalling() end
    )
    -- Attach pickaxe to right hand in TPS mode
    if dropMode == "tps" then
        task.delay(0.3, function() pickaxe:SetThirdPerson(true) end)
    end

    -- Find the session level folder in workspace
    local levelsFolder = workspace:FindFirstChild("Levels")
    local levelFolder = nil
    if levelsFolder then
        -- Find the most recently added session folder
        for _, child in ipairs(levelsFolder:GetChildren()) do
            if child:IsA("Folder") and child.Name:find("Session_") then
                levelFolder = child
            end
        end
    end

    -- Start moving platforms
    movingPlatforms:Load(levelFolder)
    movingPlatforms:Start()

    -- Start slime enemies (SlimeRain modifier: slime all terrain on start)
    slimes:Start(levelFolder, pickaxe)
    if activeMod.slimeRain then
        slimes:SlimeAllTerrain(levelFolder)
    end

    -- High-Fidelity Audio Setup
    visuals:StartWindSound()
    visuals:AttachSpatialSounds(levelFolder)

    -- Start client timer + speedometer + depth tracker + dynamic chunk loader
    State.timerActive = true
    State.timerConnection = RunService.Heartbeat:Connect(function(dt)
        if not State.timerActive then return end
        State.timer = State.timer + dt
        hud:UpdateTimer(State.timer)
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Speedometer: total velocity magnitude (falling counts)
                local vel = hrp.AssemblyLinearVelocity
                local speed = vel.Magnitude
                hud:UpdateSpeed(speed)
                
                -- Wind audio velocity updates
                visuals:UpdateWind(vel.Y)

                -- Depth: world Y goes negative as player falls
                local depthStuds = GameData.LEVEL_Y_OFFSET - hrp.Position.Y
                local depthMeters = math.max(0, depthStuds / GameData.STUDS_PER_METER)
                if math.abs(depthMeters - State.currentDepth) > 0.5 then
                    State.currentDepth = depthMeters
                    hud:UpdateDepth(depthMeters)

                    -- Dynamic Seeded Chunk Loader trigger
                    local triggerDepth = (State.lastLoadedSlot - 1) * GameData.SLOT_DEPTH_METERS + 50
                    if depthMeters >= triggerDepth then
                        local nextSlot = State.lastLoadedSlot + 1
                        State.lastLoadedSlot = nextSlot
                        print("[DropDwarf Client] Approaching slot boundary. Requesting Slot", nextSlot)
                        Networking.FireServer(Networking.Events.RequestChunkLoad, nextSlot)
                    end
                end
            end
        end
    end)
end

local function returnToHub()
    State.inLevel = false
    State.inHub = true  -- set BEFORE camera:Stop so onCharacterAdded sees hub state
    State.timerActive = false
    if State.timerConnection then
        State.timerConnection:Disconnect()
        State.timerConnection = nil
    end

    -- Reset weight (backpack cleared server-side on hub return)
    movement:SetWeightEffects(1.0)
    hud:ShowWeightInfo(0, 1, 1)

    -- Stop in-level systems
    camera:Stop()
    movement:Stop()
    activeItem:Stop()
    backpackUI:Hide()
    backpackUI:DisconnectInput()
    pickaxe:Destroy()
    slimes:Stop()
    movingPlatforms:Stop()
    
    -- Cleanup Audio Loops
    visuals:CleanupAudio()

    -- Rebuild pickaxe and active item for next run
    pickaxe = PickaxeModel.new(workspace.CurrentCamera)
    activeItem = ActiveItem.new(camera, movement)
    -- Show pickaxe idle in hub immediately after rebuild
    pickaxe:Start(
        function() return false end,
        function() return false end
    )

    -- Switch back to hub
    hud:Hide()
    hubUI:SetVisible(true)
    visuals:ApplyHubLighting()

    -- Request fresh data
    task.delay(0.5, function()
        local getDataFn = Networking.GetFunction(Networking.Functions.GetPlayerData)
        if getDataFn then
            local data = getDataFn:InvokeServer()
            if data then
                hubUI:UpdatePlayerData(data)
            end
        end
    end)
end

-- ==================== REMOTE EVENT HANDLERS ====================

Networking.OnClient(Networking.Events.LevelGenerated, function(data)
    onLevelGenerated(data)
end)

Networking.OnClient(Networking.Events.TriggerBasketLaunch, function()
    local sessionId = player.UserId
    local levelFolder = workspace:FindFirstChild("DropDwarfLevel_" .. sessionId)
    if not levelFolder then
        -- Search for any level folder in case sessionId format differs
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name:match("^DropDwarfLevel_") then
                levelFolder = child
                break
            end
        end
    end
    if not levelFolder then return end

    local basket = levelFolder:WaitForChild("DwarvenEntryBasket", 5)
    if not basket then return end

    local doorL = basket:FindFirstChild("BasketTrapdoorL")
    local doorR = basket:FindFirstChild("BasketTrapdoorR")
    if not doorL or not doorR then return end

    -- Cache starting closed CFrame so we can restore it on subsequent runs/deaths
    if not doorL:FindFirstChild("ClosedCFrame") then
        local val = Instance.new("CFrameValue")
        val.Name = "ClosedCFrame"
        val.Value = doorL.CFrame
        val.Parent = doorL
    end
    if not doorR:FindFirstChild("ClosedCFrame") then
        local val = Instance.new("CFrameValue")
        val.Name = "ClosedCFrame"
        val.Value = doorR.CFrame
        val.Parent = doorR
    end

    -- Instantly reset doors to closed state
    doorL.CFrame = doorL.ClosedCFrame.Value
    doorR.CFrame = doorR.ClosedCFrame.Value

    -- Find gears and steam nozzles
    local gearL = basket:FindFirstChild("IndustrialGearL")
    local gearR = basket:FindFirstChild("IndustrialGearR")
    local nozzles = {}
    for _, child in ipairs(basket:GetChildren()) do
        if child.Name == "SteamNozzle" then
            table.insert(nozzles, child)
            local emitter = child:FindFirstChild("SteamVent")
            if emitter then
                emitter.Enabled = true
            end
        end
    end

    -- High-fidelity Perlin noise build-up camera shake (duration = 2.0s, magnitude = 1.5, frequency = 28)
    if camera and camera.ApplyShake then
        camera:ApplyShake(1.5, 2.0, 28)
    end

    -- Spin gears smoothly over 2 seconds
    local TweenService = game:GetService("TweenService")
    local spinInfo = TweenInfo.new(2.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    
    if gearL then
        local targetCF = gearL.CFrame * CFrame.Angles(0, 0, math.rad(720))
        TweenService:Create(gearL, spinInfo, { CFrame = targetCF }):Play()
    end
    if gearR then
        local targetCF = gearR.CFrame * CFrame.Angles(0, 0, math.rad(-720))
        TweenService:Create(gearR, spinInfo, { CFrame = targetCF }):Play()
    end

    -- Trigger steam release and slide doors open after 2.0s buildup
    task.delay(2.0, function()
        -- Hard slam camera shake (duration = 0.6s, magnitude = 4.5, frequency = 45)
        if camera and camera.ApplyShake then
            camera:ApplyShake(4.5, 0.6, 45)
        end

        -- Stop steam particles
        for _, nozzle in ipairs(nozzles) do
            local emitter = nozzle:FindFirstChild("SteamVent")
            if emitter then
                emitter.Enabled = false
            end
        end

        -- Slide doors open smoothly (over 0.5s)
        local doorTh = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local targetCFL = doorL.ClosedCFrame.Value * CFrame.new(-6, 0, 0)
        local targetCFR = doorR.ClosedCFrame.Value * CFrame.new(6, 0, 0)

        TweenService:Create(doorL, doorTh, { CFrame = targetCFL }):Play()
        TweenService:Create(doorR, doorTh, { CFrame = targetCFR }):Play()
    end)
end)

Networking.OnClient(Networking.Events.DepthUpdate, function(depthMeters)
    State.currentDepth = depthMeters
    if State.inLevel then
        hud:UpdateDepth(depthMeters)
    end
end)

Networking.OnClient(Networking.Events.BiomeChanged, function(biomeName)
    if State.inLevel then
        hud:ShowBiomeChange(biomeName)
        visuals:OnBiomeChanged(biomeName)
    end
end)

Networking.OnClient(Networking.Events.HealthUpdate, function(current, max)
    local prev = State.health
    State.health = current
    State.maxHealth = max or State.maxHealth
    if State.inLevel then
        hud:UpdateHealth(current, State.maxHealth)
        -- Flash visuals on damage
        if current < prev then
            local severity = math.clamp((prev - current) / State.maxHealth, 0, 1)
            visuals:FlashFallDamage(severity)
            
            -- Trigger physical Perlin noise camera shake
            if camera and camera.ApplyShake then
                camera:ApplyShake(severity * 4.2, 0.45, 28)
            end
        end
    end
end)

-- Stats from server (sent after upgrades or level start)
Networking.OnClient(Networking.Events.StatsUpdate, function(stats)
    State.stats = stats
    if State.inLevel then
        movement:ApplyStats(stats)
        hud:UpdateAirJumps(stats.airJumps or 0, stats.airJumps or 0)
    end
end)

-- Modifier set by server
Networking.OnClient(Networking.Events.ModifierSet, function(modId)
    State.modifier = modId or "Normal"
    local mod = GameData.RunModifiers[modId] or GameData.RunModifiers.Normal
    if State.inLevel then
        movement:SetModifier(mod)
        hud:SetModifier(mod)
    end
end)

-- Receive dynamic slime spawns upon chunk generation
Networking.OnClient(Networking.Events.ChunkLoaded, function(slotIndex, spawns)
    if not State.inLevel then return end
    if spawns and #spawns > 0 then
        slimes:SpawnSlimes(spawns)
    end
end)

-- Combo update (already handled client-side in movement, this is server echo)
Networking.OnClient(Networking.Events.ComboUpdate, function(streak, mult)
    if State.inLevel then
        hud:UpdateCombo(streak, mult)
    end
end)

Networking.OnClient(Networking.Events.GoldUpdate, function(gold)
    local prev = State.gold
    State.gold = gold
    if State.inLevel then
        hud:UpdateGold(gold)
        -- Pulse bloom on coin collect
        if gold > prev then
            visuals:PulseCoinCollect()
        end
    else
        hubUI:UpdateGold(gold)
    end
end)

Networking.OnClient(Networking.Events.TimerSync, function(serverTime)
    -- Sync client timer; 0 means explicit reset, >0 means running sync
    if serverTime == 0 then
        State.timer = 0
        hud:UpdateTimer(0)
    elseif State.inLevel and serverTime > 0 then
        State.timer = serverTime
    end
end)

Networking.OnClient(Networking.Events.PlayerDied, function(info)
    State.timerActive = false
    hud:FlashDamage(0.5)
    -- Unlock mouse so death screen buttons are clickable.
    -- Camera loop keeps running so the player can still look around.
    if camera and camera.EnterDeathView then
        camera:EnterDeathView()
    end
    -- Show the 2x2 choice grid; callback fires DeathChoice to server
    hud:ShowDeath(
        info.depthReached or State.currentDepth,
        info.goldEarned or 0,
        function(choice)
            -- Re-lock mouse immediately on choice (before server round-trip)
            if camera and camera.LeaveDeathView then
                camera:LeaveDeathView()
            end
            -- Disable buttons immediately to prevent double-fire
            hud:HideDeath()
            Networking.FireServer(Networking.Events.DeathChoice, choice)
        end
    )
end)

Networking.OnClient(Networking.Events.RespawnInBasket, function(info)
    -- Server has already moved the character; just restore client state
    hud:HideDeath()
    -- Ensure mouse is re-locked for FPS play (LeaveDeathView already called on choice,
    -- but this is a safety net for edge cases like network delay)
    if camera and camera.LeaveDeathView then
        camera:LeaveDeathView()
    end
    if not State.inLevel then
        -- Was not in level client-side; re-enter level mode without regenerating
        State.inLevel = true
        State.inHub   = false
        hud:Show()
        hud:HideWin()
        camera:Start(State.dropType or "fps")
        movement:Start()
        activeItem:SetHUD(hud)
        activeItem:Start()
        backpackUI:Show()
        backpackUI:ConnectInput()
    end
    -- Sync timer
    if info and info.isReset then
        State.timer = 0
        State.timerActive = true
        hud:UpdateTimer(0)
    else
        State.timerActive = true
    end
end)

Networking.OnClient(Networking.Events.RespawnInHub, function(info)
    hud:HideDeath()
    returnToHub()
end)

Networking.OnClient(Networking.Events.PlayerWon, function(info)
    State.timerActive = false
    if State.inLevel then
        hud:ShowWin(info.timeSeconds, info.absoluteRank, info.goldEarned or 0)
    end
    task.delay(5, function()
        returnToHub()
    end)
end)

Networking.OnClient(Networking.Events.LeaderboardUpdate, function(times, depths)
    hubUI:PopulateLeaderboard(times, depths)
end)

Networking.OnClient(Networking.Events.BackpackUpdate, function(slots, activeSlot)
    if backpackUI then
        backpackUI:Update(slots, activeSlot)
    end
end)

-- ==================== MULTIPLAYER NETWORK HANDLERS ====================

Networking.OnClient(Networking.Events.LobbyUpdate, function(data)
    if data and data.error then
        -- Could show a toast notification; for now just print
        print("[Lobby]", data.error)
        return
    end
    if data and data.modeId then
        State.gameModeId = data.modeId
    end
    hubUI:OnLobbyUpdate(data)
end)

Networking.OnClient(Networking.Events.GameModeChanged, function(modeId)
    State.gameModeId = modeId
    -- Show a brief banner if in-level
    if State.inLevel then
        local mode = GameMode.Get(modeId)
        hud:ShowBiomeChange(mode.displayName .. " MODE")
    end
end)

-- Coop: a teammate went down
Networking.OnClient(Networking.Events.PlayerDowned, function(info)
    if not info then return end
    local myId = player.UserId
    if info.userId == myId then
        -- I went down - show downed overlay on my HUD
        hud:ShowDowned()
    else
        -- A teammate went down - store for proximity detection
        State.downdedPlayers[info.userId] = {
            name  = info.name or "Teammate",
            pos   = info.pos and Vector3.new(info.pos[1], info.pos[2], info.pos[3]) or nil,
        }
    end
end)

-- Coop: a teammate was rescued
Networking.OnClient(Networking.Events.PlayerRescued, function(info)
    if not info then return end
    State.downdedPlayers[info.userId] = nil
    if info.userId == player.UserId then
        hud:HideDowned()
    end
    -- Clear rescue progress bar
    hud:ShowRescueProgress(nil)
    State.rescuing = nil
end)

-- Coop: rescue progress update
Networking.OnClient(Networking.Events.RescueProgress, function(info)
    if not info then return end
    hud:ShowRescueProgress(info.progress or 0)
end)

-- Coop: item was transferred between players
Networking.OnClient(Networking.Events.ItemGiven, function(info)
    if not info then return end
    local myId = player.UserId
    if info.toId == myId then
        hud:ShowToast(string.format("Received %s!", info.itemId))
    elseif info.fromId == myId then
        hud:ShowToast(string.format("Gave %s to teammate.", info.itemId))
    end
end)

-- Coop/Competitive: full team health update
Networking.OnClient(Networking.Events.TeamHealthUpdate, function(healthData)
    hud:UpdateTeamHealth(healthData, player.UserId)
end)

-- Weight system: update movement speed and HUD weight indicator
Networking.OnClient(Networking.Events.WeightUpdate, function(data)
    if not data then return end
    movement:SetWeightEffects(data.speedMult)
    hud:ShowWeightInfo(data.totalKg, data.speedMult, data.fallMult)
end)

-- Competitive: I was hit by another player
Networking.OnClient(Networking.Events.PlayerHit, function(info)
    if not info then return end
    hud:FlashDamage(0.4)
    -- Apply knockback via a BodyVelocity on the character
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and info.knockbackDir then
        local kd = info.knockbackDir
        local force = (info.knockbackForce or 60)
        local vel = Vector3.new(kd[1], kd[2], kd[3]) * force
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = vel
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.P = 1e4
        bv.Parent = hrp
        game:GetService("Debris"):AddItem(bv, 0.18)
    end
end)

-- Competitive: a player was eliminated
Networking.OnClient(Networking.Events.PlayerEliminated, function(info)
    if not info then return end
    hud:ShowToast(string.format("%s was eliminated!", info.name or "A player"))
end)

-- ==================== FLASHLIGHT ====================
local flashlightPart   = nil   -- Part attached to HRP holding SpotLight
local flashlight       = nil   -- SpotLight instance
local flashlightBeam   = nil   -- SpecialMesh cone for volumetric foggy beam
local flashlightOn     = true  -- starts ON
local fHoldTime        = 0     -- how long F has been held
local fWasDown         = false
local FLASHLIGHT_HOLD  = 2.0   -- seconds to hold F to toggle

local function buildFlashlight(char)
    -- Clean up old
    if flashlightPart and flashlightPart.Parent then
        flashlightPart:Destroy()
    end
    flashlightPart = nil
    flashlight     = nil
    flashlightBeam = nil

    local hrp = char and char:FindFirstChild("HumanoidRootPart") or (char and char:WaitForChild("HumanoidRootPart", 5))
    if not hrp then return end

    local fp = Instance.new("Part")
    fp.Name             = "FlashlightAnchor"
    fp.Size             = Vector3.new(0.1, 0.1, 0.1)
    fp.Transparency     = 1
    fp.Anchored         = false
    fp.CanCollide       = false
    fp.CastShadow       = false
    -- Set CFrame BEFORE parenting and welding so WeldConstraint captures zero offset
    fp.CFrame = hrp.CFrame
    fp.Parent           = char

    local w = Instance.new("WeldConstraint")
    w.Part0  = hrp
    w.Part1  = fp
    w.Parent = hrp

    local sl = Instance.new("SpotLight")
    sl.Name        = "Flashlight"
    sl.Brightness  = 3
    sl.Range       = 60
    sl.Angle       = 45
    sl.Color       = Color3.fromRGB(240, 240, 255)   -- slightly cool white
    sl.Enabled     = flashlightOn
    sl.Shadows     = true
    sl.Face        = Enum.NormalId.Front
    sl.Parent      = fp

    -- Premium Volumetric Scattering cone
    local beam = Instance.new("Part")
    beam.Name = "FlashlightBeam"
    beam.Size = Vector3.new(0.2, 0.2, 50)
    beam.Color = Color3.fromRGB(225, 235, 255)
    beam.Material = Enum.Material.Neon
    beam.Transparency = flashlightOn and 0.935 or 1.0
    beam.CanCollide = false
    beam.CanQuery = false
    beam.CanTouch = false
    beam.CastShadow = false
    beam.Massless = true
    beam.Parent = char

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://1033714"
    mesh.Scale = Vector3.new(12, 12, 50)
    mesh.Parent = beam

    local bw = Instance.new("Weld")
    bw.Part0 = fp
    bw.Part1 = beam
    bw.C0 = CFrame.new(0, 0, -25) * CFrame.Angles(math.rad(-90), 0, 0)
    bw.Parent = fp

    flashlightPart = fp
    flashlight     = sl
    flashlightBeam = beam
end

-- F toggle loop + flashlight direction tracking
local fWasDown2 = false
RunService.Heartbeat:Connect(function(dt)
    -- Toggle on single F press (not hold)
    local fDown = UserInputService:IsKeyDown(Enum.KeyCode.F)
    if fDown and not fWasDown2 and State.inLevel then
        fWasDown2 = true
        flashlightOn = not flashlightOn
        if flashlight then
            flashlight.Enabled = flashlightOn
        end
        if flashlightBeam then
            flashlightBeam.Transparency = flashlightOn and 0.935 or 1.0
        end
        if hud and hud.ShowToast then
            hud:ShowToast(flashlightOn and "Flashlight ON" or "Flashlight OFF")
        end
    elseif not fDown then
        fWasDown2 = false
    end

    -- Track flashlight to camera look direction every frame
    if flashlightPart and flashlightPart.Parent and flashlightOn then
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local lookDir = workspace.CurrentCamera.CFrame.LookVector
            flashlightPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 0.5, 0), hrp.Position + lookDir * 10)
        end
    end
end)

-- ==================== HUB LOOP ====================
-- Proximity checks only in hub
RunService.Heartbeat:Connect(function()
    if State.inHub and not (hubUI.shopOpen or hubUI.seedOpen or hubUI.leaderboardOpen) then
        checkHubProximity()
    end
end)

-- ==================== IN-LEVEL MULTIPLAYER LOOP ====================
RunService.Heartbeat:Connect(function()
    if not State.inLevel then return end
    local mode = GameMode.Get(State.gameModeId)
    if not mode.coopEnabled then return end

    -- Coop: check if near a downed player and E is held to rescue
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local nearestId, nearestDist = nil, mode.rescueRange
    for userId, info in pairs(State.downdedPlayers) do
        -- Find character position via Players service
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p.UserId == userId and p.Character then
                local pHrp = p.Character:FindFirstChild("HumanoidRootPart")
                if pHrp then
                    local d = (hrp.Position - pHrp.Position).Magnitude
                    if d < nearestDist then
                        nearestId   = userId
                        nearestDist = d
                    end
                end
            end
        end
    end

    if nearestId and UserInputService:IsKeyDown(Enum.KeyCode.E) then
        State.rescuing = nearestId
        Networking.FireServer(Networking.Events.RequestRescue, nearestId)
    else
        if State.rescuing then
            State.rescuing = nil
            hud:ShowRescueProgress(nil)
        end
        -- Show rescue hint toast once when near (throttled by toastLabel reuse)
        if nearestId and not State.rescuing then
            local tName = State.downdedPlayers[nearestId] and State.downdedPlayers[nearestId].name or "teammate"
            hud:ShowToast("[E] Rescue " .. tName)
        end
    end
end)

-- ==================== KEYBOARD SHORTCUTS ====================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.L then
        -- Toggle leaderboard
        if State.inHub then
            if hubUI.leaderboardOpen then
                hubUI:CloseLeaderboard()
            else
                hubUI:OpenLeaderboard()
            end
        end
    end
    if input.KeyCode == Enum.KeyCode.M then
        -- Open/close multiplayer lobby from hub
        if State.inHub then
            if hubUI.lobbyOpen then
                hubUI:CloseLobby()
            else
                hubUI:OpenLobby(function() enterLevel() end)
            end
        end
    end
    if input.KeyCode == Enum.KeyCode.G then
        -- Coop: give active item to nearest teammate
        if State.inLevel and State.gameModeId == "Cooperative" then
            Networking.FireServer(Networking.Events.GiveItemRequest)
        end
    end
    if input.KeyCode == Enum.KeyCode.Escape then
        -- Close any open panels
        if hubUI.shopOpen then hubUI:CloseShop() end
        if hubUI.seedOpen then hubUI:CloseSeed() end
        if hubUI.leaderboardOpen then hubUI:CloseLeaderboard() end
        if hubUI.lobbyOpen then hubUI:CloseLobby() end
    end
end)

-- ==================== INITIALIZATION ====================
local function onCharacterAdded(character)
    local hrp      = character:WaitForChild("HumanoidRootPart", 5)
    local humanoid = character:WaitForChild("Humanoid", 5)
    character:WaitForChild("Head", 5)

    -- Disable jump states so Roblox's PlayerModule cannot launch the character.
    -- movement.lua uses AssemblyLinearVelocity directly for intentional air jumps.
    if humanoid then
        humanoid.AutoJumpEnabled = false
        humanoid.JumpHeight      = 0
        humanoid.JumpPower       = 0
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    end

    -- Server owns the spawn anchor/unanchor sequence (main.server.lua CharacterAdded).
    -- Client must not race with it by anchoring/unanchoring here.

    task.wait(0.05)
    -- Rebuild flashlight on every spawn
    buildFlashlight(character)

    -- Always force third-person camera when character spawns in hub
    -- This fixes the case where FPS camera persists through death/respawn
    if State.inHub then
        -- Load the chosen camera style in the Hub on spawn!
        local camMode = State.dropType or "fps"
        camera:Start(camMode)
        if pickaxe then
            pickaxe:SetThirdPerson(camMode == "tps")
        end

        -- Ensure character parts are visible if in third-person mode
        if camMode == "tps" then
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            for _, obj in ipairs(character:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.LocalTransparencyModifier = 0
                elseif obj:IsA("Decal") or obj:IsA("SpecialMesh") then
                    obj.Transparency = 0
                end
            end
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end
        -- Start hub mode: default camera, hub UI visible
        hubUI:SetVisible(true)
        hud:Hide()

        -- Request player data from server
        task.delay(1, function()
            local getDataFn = Networking.GetFunction(Networking.Functions.GetPlayerData)
            if getDataFn then
                local data = getDataFn:InvokeServer()
                if data then
                    hubUI:UpdatePlayerData(data)
                    hubUI.currentSeed = data.lastSeed or "MattyJacks"
                    if hubUI.seedBarLabel then
                        hubUI.seedBarLabel.Text = "SEED: " .. hubUI.currentSeed
                    end
                    if hubUI.seedInput then
                        hubUI.seedInput.Text = hubUI.currentSeed
                    end
                end
            end
        end)
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

print("[DropDwarf Client] Initialized for", player.Name)
