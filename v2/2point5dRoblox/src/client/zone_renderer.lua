-- zone_renderer.lua (CLIENT)
-- Handles visibility of zones (Lobby, Exterior, Dungeon) on the client.

local ZoneRenderer = {}

function ZoneRenderer.setLobbyVisible(visible)
	local lobby = workspace:FindFirstChild("Lobby")
	if lobby then
		for _, desc in ipairs(lobby:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.LocalTransparencyModifier = visible and 0 or 1
				desc.CanCollide = visible
			end
		end
	end
end

function ZoneRenderer.setDungeonVisible(visible)
	local dungeon = workspace:FindFirstChild("Dungeon")
	if dungeon then
		for _, desc in ipairs(dungeon:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.LocalTransparencyModifier = visible and 0 or 1
				desc.CanCollide = visible
			end
		end
	end
end

function ZoneRenderer.setExteriorVisible(visible)
	local ext = workspace:FindFirstChild("Exterior")
	if ext then
		for _, desc in ipairs(ext:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.LocalTransparencyModifier = visible and 0 or 1
				desc.CanCollide = visible
			end
		end
	end
end

return ZoneRenderer
