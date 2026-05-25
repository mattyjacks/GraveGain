-- DwarfDrop: handlers/mining_handler.lua
-- Authoritative server validation for pickaxe swings, wall mining, nugget drops

local Players    = game:GetService("Players")

local Networking  = require(game.ReplicatedStorage.Shared.networking)
local GameData    = require(game.ReplicatedStorage.Shared.game_data)
local PlayerData  = require(script.Parent.Parent.player_data)

local MiningHandler = {}

local ANTI_MACRO_COOLDOWN = 0.3  -- seconds between valid mine events per player
local MAX_HIT_RANGE       = 16   -- studs, server-side range validation

local lastMineTime = {}  -- [userId] = tick()

local function onMineWall(player, oreRef, hitPos)
    -- Anti-macro: enforce cooldown
    local uid  = player.UserId
    local now  = tick()
    local last = lastMineTime[uid] or 0
    if (now - last) < ANTI_MACRO_COOLDOWN then return end
    lastMineTime[uid] = now

    -- Validate ore reference
    if not oreRef or not oreRef.Parent then return end
    local oreTag = oreRef:FindFirstChild("IsOre")
    if not oreTag then return end

    -- Range validation
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dist = (hrp.Position - oreRef.Position).Magnitude
    if dist > MAX_HIT_RANGE then return end

    -- Get or create HP tag
    local hpTag = oreRef:FindFirstChild("OreHP")
    if not hpTag then return end

    -- Deal one hit (each swing = 1 damage)
    hpTag.Value = hpTag.Value - 1

    if hpTag.Value <= 0 then
        -- Ore depleted - award gold
        local goldTag  = oreRef:FindFirstChild("OreGoldValue")
        local goldAmt  = goldTag and goldTag.Value or 10

        PlayerData.AddGold(player, goldAmt)
        local data = PlayerData.Get(player)

        Networking.FireClient(Networking.Events.GoldUpdate, player, data and data.gold or 0)

        -- Spawn visual nugget on client
        Networking.FireClient(Networking.Events.SpawnMiningNugget, player, {
            itemId   = "OreNugget",
            pos      = oreRef.Position,
            goldVal  = goldAmt,
        })

        -- Notify WallMined (wall part turns back to plain rock color)
        Networking.FireClient(Networking.Events.WallMined, player, oreRef, oreRef.Position)

        -- Remove ore tags so it can't be mined again
        oreTag:Destroy()
        if hpTag then hpTag:Destroy() end
        if goldTag then goldTag:Destroy() end

        -- Change wall color to depleted stone
        oreRef.Color = Color3.fromRGB(60, 58, 55)
    else
        -- Ore damaged but not depleted - update visual
        local dmgFrac = 1 - (hpTag.Value / 3)
        oreRef.Color = oreRef.Color:Lerp(Color3.fromRGB(30, 25, 20), dmgFrac * 0.5)
    end
end

function MiningHandler.Init()
    Networking.OnServer(Networking.Events.MineWall, onMineWall)
end

return MiningHandler
