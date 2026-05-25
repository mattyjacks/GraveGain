-- DropDwarf: handlers/pvp_handler.lua
-- Authoritative server validations for player PvP combat hits and item trades.

local Players    = game:GetService("Players")
local Networking = require(game.ReplicatedStorage.Shared.networking)
local GameMode   = require(game.ReplicatedStorage.Shared.game_mode)
local Session    = require(script.Parent.Parent.session)
local ItemHandler = require(script.Parent.Parent.item_handler)

local PvpHandler = {}

function PvpHandler.Init(getStateFn)
    -- Competitive: pickaxe swing hit another player
    Networking.OnServer(Networking.Events.AttackPlayer, function(player, targetUserId, hitPos)
        local state = getStateFn(player)
        if not state or not state.inLevel then return end
        local modeId = Session.GetMode(player)
        local mode = GameMode.Get(modeId)
        if not mode.pvpEnabled then return end

        local targetPlayer = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p.UserId == targetUserId then targetPlayer = p; break end
        end
        if not targetPlayer then return end
        if targetPlayer == player then return end
        
        local tState = getStateFn(targetPlayer)
        if not tState or not tState.inLevel then return end

        local attackerSid = Session.GetSessionId(player)
        local targetSid   = Session.GetSessionId(targetPlayer)
        if not attackerSid or attackerSid ~= targetSid then return end

        local myChar = player.Character
        local tChar  = targetPlayer.Character
        if not myChar or not tChar then return end
        local myHrp = myChar:FindFirstChild("HumanoidRootPart")
        local tHrp  = tChar:FindFirstChild("HumanoidRootPart")
        if not myHrp or not tHrp then return end
        if (myHrp.Position - tHrp.Position).Magnitude > mode.pickaxeRange then return end

        if not Session.CanHitPlayer(player, targetPlayer) then return end
        Session.RecordHit(player, targetPlayer)

        local hum = tChar:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        hum.Health = math.max(0, hum.Health - mode.pickaxeDamage)

        local knockDir = (tHrp.Position - myHrp.Position)
        if knockDir.Magnitude < 0.01 then knockDir = Vector3.new(1,0,0) end
        knockDir = knockDir.Unit
        
        Networking.FireClient(Networking.Events.PlayerHit, targetPlayer, {
            damage      = mode.pickaxeDamage,
            knockbackDir = { knockDir.X, knockDir.Y + 0.4, knockDir.Z },
            knockbackForce = mode.knockbackForce,
            attackerName = player.Name,
        })
    end)

    -- Coop: give active item to nearest teammate (G key)
    Networking.OnServer(Networking.Events.GiveItemRequest, function(player)
        local state = getStateFn(player)
        if not state or not state.inLevel then return end
        local modeId = Session.GetMode(player)
        local mode = GameMode.Get(modeId)
        if not mode.coopEnabled then return end

        local itemState = ItemHandler.GetState(player)
        if not itemState or not itemState.activeItem then return end

        local myChar = player.Character
        local myHrp  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then return end

        local nearest, nearDist = nil, mode.giveItemRange
        for _, teammate in ipairs(Session.GetTeammates(player)) do
            local tChar = teammate.Character
            local tHrp  = tChar and tChar:FindFirstChild("HumanoidRootPart")
            if tHrp then
                local d = (myHrp.Position - tHrp.Position).Magnitude
                if d < nearDist then
                    nearest  = teammate
                    nearDist = d
                end
            end
        end
        if not nearest then return end

        local itemId  = itemState.activeItem
        local slot    = itemState.activeSlot
        local slotData = itemState.backpack[slot]
        if not slotData or slotData.count <= 0 then return end

        slotData.count = slotData.count - 1
        if slotData.count <= 0 then
            itemState.backpack[slot] = nil
            itemState.activeItem = nil
        end
        ItemHandler.GiveItem(nearest, itemId, 1)

        local team = Session.GetAllMembers(player)
        for _, p in ipairs(team) do
            Networking.FireClient(Networking.Events.ItemGiven, p, {
                fromId  = player.UserId,
                toId    = nearest.UserId,
                itemId  = itemId,
                count   = 1,
            })
        end
    end)
end

return PvpHandler
