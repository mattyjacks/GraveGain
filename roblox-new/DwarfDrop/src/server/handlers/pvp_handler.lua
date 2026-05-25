-- DwarfDrop: handlers/pvp_handler.lua
-- Authoritative server validation for PvP combat and coop item trading

local Players    = game:GetService("Players")

local Networking  = require(game.ReplicatedStorage.Shared.networking)
local GameData    = require(game.ReplicatedStorage.Shared.game_data)
local GameMode    = require(game.ReplicatedStorage.Shared.game_mode)
local Session     = require(script.Parent.Parent.session)
local ItemHandler = require(script.Parent.Parent.item_handler)

local PvPHandler = {}

local PVP_RANGE   = 12  -- studs, max pickaxe range for pvp
local PVP_DAMAGE  = 25

local function onAttackPlayer(attacker, targetId, hitPos)
    targetId = tonumber(targetId)
    if not targetId then return end

    local target = Players:GetPlayerByUserId(targetId)
    if not target then return end

    -- Same session check
    local sess = Session.GetSessionForPlayer(attacker)
    if not sess or not GameMode.IsPvP(sess.modeId) then return end
    if not Session.IsMember(target, sess.host.UserId) then return end

    -- Cooldown check
    if not Session.CheckPvPCooldown(attacker, target) then return end

    -- Range check
    local aChar = attacker.Character
    local tChar = target.Character
    if not aChar or not tChar then return end
    local aHRP = aChar:FindFirstChild("HumanoidRootPart")
    local tHRP = tChar:FindFirstChild("HumanoidRootPart")
    if not aHRP or not tHRP then return end
    local dist = (aHRP.Position - tHRP.Position).Magnitude
    if dist > PVP_RANGE then return end

    -- Deal damage
    local tHum = tChar:FindFirstChildOfClass("Humanoid")
    if not tHum or tHum.Health <= 0 then return end

    local modeData = GameMode.Get(sess.modeId)
    local damage   = modeData.pvpDamage or PVP_DAMAGE

    tHum.Health = math.max(0, tHum.Health - damage)

    -- Knockback direction
    local knockDir  = (tHRP.Position - aHRP.Position).Unit
    local knockForce = modeData.pvpKnockbackForce or 80

    Networking.FireClient(Networking.Events.PlayerHit, target, {
        damage       = damage,
        knockbackDir = { x = knockDir.X, y = 0.4, z = knockDir.Z },
        knockbackForce = knockForce,
    })

    -- Check elimination
    if tHum.Health <= 0 then
        Networking.FireAllClients(Networking.Events.PlayerEliminated, { userId = targetId })
    end
end

local function onGiveItemRequest(player)
    local sess = Session.GetSessionForPlayer(player)
    if not sess or not GameMode.IsCoop(sess.modeId) then return end

    local pChar = player.Character
    local pHRP  = pChar and pChar:FindFirstChild("HumanoidRootPart")
    if not pHRP then return end

    -- Find nearest teammate within trade range
    local TRADE_RANGE = 10
    local bestDist = TRADE_RANGE
    local bestTarget = nil

    for _, member in ipairs(Session.GetMembers(sess.host.UserId)) do
        if member ~= player and member.Character then
            local mHRP = member.Character:FindFirstChild("HumanoidRootPart")
            if mHRP then
                local dist = (pHRP.Position - mHRP.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestTarget = member
                end
            end
        end
    end

    if not bestTarget then return end

    -- Give equipped item (slot 1) to target
    local bp = ItemHandler.GetBackpack(player)
    local slot = bp[1]
    if not slot then return end

    local added = ItemHandler.GiveItem(bestTarget, slot.itemId, 1)
    if added then
        ItemHandler.ConsumeItem(player, 1)
        Networking.FireAllClients(Networking.Events.ItemGiven, {
            fromId = player.UserId,
            toId   = bestTarget.UserId,
            itemId = slot.itemId,
            count  = 1,
        })
    end
end

function PvPHandler.Init()
    Networking.OnServer(Networking.Events.AttackPlayer, onAttackPlayer)
    Networking.OnServer(Networking.Events.GiveItemRequest, onGiveItemRequest)
end

return PvPHandler
