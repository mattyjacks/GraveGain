-- DropDwarf: handlers/mining_handler.lua
-- Authoritative server validation for pickaxe swings, wall mining, and nugget drops.

local Players    = game:GetService("Players")
local Networking = require(game.ReplicatedStorage.Shared.networking)
local GameData   = require(game.ReplicatedStorage.Shared.game_data)
local PlayerData = require(script.Parent.Parent.player_data)
local PartBuilders = require(script.Parent.Parent.level_generator.part_builders)

local MiningHandler = {}

local mineHitTimes = {}

function MiningHandler.Init(getStateFn)
    -- MineWall: client hit a WallOre node with the pickaxe authoritatively
    Networking.OnServer(Networking.Events.MineWall, function(player, orePart)
        local state = getStateFn(player)
        if not state or not state.inLevel then return end

        if not orePart or not orePart:IsA("BasePart") then return end
        if orePart.Name ~= "WallOre" then return end
        local mineTag = orePart:FindFirstChild("IsMineable")
        if not mineTag then return end

        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if (hrp.Position - orePart.Position).Magnitude > 12 then return end

        -- Anti-macro swing speed caps
        local now = tick()
        local lastHit = mineHitTimes[player] or 0
        if now - lastHit < 0.3 then return end
        mineHitTimes[player] = now

        local hpTag = orePart:FindFirstChild("OreHp")
        local goldTag = orePart:FindFirstChild("GoldValue")
        if not hpTag or not goldTag then return end

        hpTag.Value = hpTag.Value - 1

        if hpTag.Value <= 0 then
            -- Depleted: award gold
            local rawGold = goldTag.Value
            local modifier = state.modifier or GameData.RunModifiers.Normal
            local earned = math.floor(rawGold * (modifier.goldMult or 1))
            state.goldThisRun = (state.goldThisRun or 0) + earned

            -- High-fidelity: spawn physical gold nugget that flies out of the wall
            Networking.FireAllClients(Networking.Events.SpawnMiningNugget, orePart.Position, mineTag.Value)

            -- Procedurally spawn 3 to 6 physical collectible gold coins around the wall ore position
            if state.levelFolder then
                local coinCount = math.random(3, 6)
                for i = 1, coinCount do
                    local offset = Vector3.new(math.random(-2, 2), math.random(1, 3), math.random(-2, 2))
                    PartBuilders.SpawnCoin(state.levelFolder, orePart.Position + offset)
                end
            end

            local data = PlayerData.Get(player)
            if data then
                data.gold = data.gold + earned
                Networking.FireClient(Networking.Events.GoldUpdate, player, data.gold)
            end

            Networking.FireClient(Networking.Events.WallMined, player, orePart.Position, mineTag.Value, earned)

            local streakRef = orePart:FindFirstChild("OreStreak")
            if streakRef and streakRef.Value and streakRef.Value.Parent then
                streakRef.Value:Destroy()
            end
            orePart:Destroy()
        else
            -- Cracked: decrement HP and broadcast visual cracks
            local maxHp = (orePart:FindFirstChild("OreMaxHp") and orePart:FindFirstChild("OreMaxHp").Value) or hpTag.Value + 1
            Networking.FireClient(Networking.Events.WallMined, player, orePart.Position, mineTag.Value, 0, hpTag.Value, maxHp)
        end
    end)
end

function MiningHandler.CleanupPlayer(player)
    mineHitTimes[player] = nil
end

return MiningHandler
