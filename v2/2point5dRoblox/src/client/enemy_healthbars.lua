-- enemy_healthbars.lua (CLIENT)
-- Renders BillboardGui health bars above all living enemies in workspace.Enemies.
-- Automatically tracks new enemies and removes bars when enemies die.

local EnemyHealthbars = {}

local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local tracked = {}  -- { [enemy] = { bg, fill, nameLabel } }

local ENEMY_NAMES = {
	Skeleton   = "💀 Skeleton",
	Zombie     = "🧟 Zombie",
	GiantSkull = "☠ BOSS — Giant Skull",
	Goblin     = "👺 Goblin",
	Spider     = "🕷 Spider",
	Cultist    = "🔮 Cultist",
}

local function makeName(enemyModel)
	local raw = enemyModel.Name or "Enemy"
	return ENEMY_NAMES[raw] or raw
end

local function isBoss(enemyModel)
	return enemyModel.Name == "GiantSkullBoss" or string.find(enemyModel.Name, "Boss") ~= nil
end

local function buildBar(enemy)
	local humanoid = enemy:FindFirstChild("Humanoid")
	if not humanoid then return end

	local root = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head")
	if not root then return end

	local bill = Instance.new("BillboardGui")
	bill.Name = "_HealthBar"
	bill.Size = UDim2.new(0, 120, 0, 30)
	bill.StudsOffset = Vector3.new(0, isBoss(enemy) and 12 or 4, 0)
	bill.AlwaysOnTop = false
	bill.ResetOnSpawn = false
	bill.Parent = root

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 14)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = makeName(enemy)
	nameLabel.TextColor3 = isBoss(enemy) and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(230, 230, 255)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = isBoss(enemy) and 13 or 11
	nameLabel.Parent = bill

	-- Bar background
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 0, 10)
	bg.Position = UDim2.new(0, 0, 0, 16)
	bg.BackgroundColor3 = Color3.fromRGB(30, 15, 15)
	bg.BorderSizePixel = 0
	bg.Parent = bill
	Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

	-- Bar fill
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = isBoss(enemy) and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(200, 40, 40)
	fill.BorderSizePixel = 0
	fill.Parent = bg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	if isBoss(enemy) then
		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new(Color3.fromRGB(255, 50, 50), Color3.fromRGB(255, 140, 0))
		grad.Parent = fill
	end

	tracked[enemy] = {bg = bg, fill = fill, nameLabel = nameLabel, bill = bill, humanoid = humanoid}
end

local function updateBar(enemy, data)
	local humanoid = data.humanoid
	if not humanoid or not humanoid.Parent then
		-- Enemy is dead/gone
		if data.bill and data.bill.Parent then data.bill:Destroy() end
		tracked[enemy] = nil
		return
	end

	local pct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
	
	-- Color shifts green → yellow → red
	local col
	if pct > 0.6 then
		col = Color3.fromRGB(50, 200, 50)
	elseif pct > 0.3 then
		col = Color3.fromRGB(220, 180, 30)
	else
		col = Color3.fromRGB(220, 40, 40)
	end

	if not isBoss(enemy) then
		data.fill.BackgroundColor3 = col
	end

	TweenService:Create(data.fill, TweenInfo.new(0.12), {
		Size = UDim2.new(pct, 0, 1, 0)
	}):Play()

	-- Hide bar when full health (for ambiance)
	data.bill.Enabled = pct < 0.99
end

function EnemyHealthbars.start()
	RunService.Heartbeat:Connect(function()
		local enemyFolder = workspace:FindFirstChild("Enemies")
		if not enemyFolder then return end

		-- Track new enemies
		for _, enemy in ipairs(enemyFolder:GetChildren()) do
			if not tracked[enemy] then
				buildBar(enemy)
			end
		end

		-- Update all tracked
		for enemy, data in pairs(tracked) do
			updateBar(enemy, data)
		end
	end)
end

return EnemyHealthbars
