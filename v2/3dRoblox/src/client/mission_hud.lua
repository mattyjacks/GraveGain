-- Mission HUD - Displays mission stats and player info
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MissionHUD = {}
MissionHUD.__index = MissionHUD

local player = Players.LocalPlayer

function MissionHUD:initialize()
	print("[MissionHUD] Initializing...")
	
	local player_gui = player:FindFirstChild("PlayerGui")
	if not player_gui then
		print("[MissionHUD] PlayerGui not found, waiting...")
		player_gui = player:WaitForChild("PlayerGui")
	end
	
	self:create_hud_screen(player_gui)
	self:setup_update_loop()
	
	print("[MissionHUD] Initialized")
end

function MissionHUD:create_hud_screen(player_gui)
	local screen_gui = Instance.new("ScreenGui")
	screen_gui.Name = "MissionHUD"
	screen_gui.ResetOnSpawn = false
	screen_gui.Parent = player_gui
	
	-- Top left - Player stats
	local player_stats = Instance.new("TextLabel")
	player_stats.Name = "PlayerStats"
	player_stats.Size = UDim2.new(0.25, 0, 0.2, 0)
	player_stats.Position = UDim2.new(0, 10, 0, 10)
	player_stats.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	player_stats.BackgroundTransparency = 0.3
	player_stats.BorderSizePixel = 0
	player_stats.TextColor3 = Color3.fromRGB(200, 200, 200)
	player_stats.TextSize = 14
	player_stats.Font = Enum.Font.Gotham
	player_stats.TextXAlignment = Enum.TextXAlignment.Left
	player_stats.TextYAlignment = Enum.TextYAlignment.Top
	player_stats.Text = "HP: 100/100\nStamina: 100/100\nAmmo: 30/30"
	player_stats.Parent = screen_gui
	
	-- Top right - Mission stats
	local mission_stats = Instance.new("TextLabel")
	mission_stats.Name = "MissionStats"
	mission_stats.Size = UDim2.new(0.25, 0, 0.2, 0)
	mission_stats.Position = UDim2.new(0.75, -10, 0, 10)
	mission_stats.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	mission_stats.BackgroundTransparency = 0.3
	mission_stats.BorderSizePixel = 0
	mission_stats.TextColor3 = Color3.fromRGB(200, 200, 200)
	mission_stats.TextSize = 14
	mission_stats.Font = Enum.Font.Gotham
	mission_stats.TextXAlignment = Enum.TextXAlignment.Right
	mission_stats.TextYAlignment = Enum.TextYAlignment.Top
	mission_stats.Text = "Wave: 1\nEnemies: 0\nIntensity: 0.3"
	mission_stats.Parent = screen_gui
	
	-- Bottom center - Crosshair
	local crosshair = Instance.new("TextLabel")
	crosshair.Name = "Crosshair"
	crosshair.Size = UDim2.new(0.05, 0, 0.1, 0)
	crosshair.Position = UDim2.new(0.475, 0, 0.475, 0)
	crosshair.BackgroundTransparency = 1
	crosshair.TextColor3 = Color3.fromRGB(100, 255, 100)
	crosshair.TextSize = 24
	crosshair.Font = Enum.Font.GothamBold
	crosshair.Text = "+"
	crosshair.Parent = screen_gui
	
	-- Bottom left - Weapon info
	local weapon_info = Instance.new("TextLabel")
	weapon_info.Name = "WeaponInfo"
	weapon_info.Size = UDim2.new(0.2, 0, 0.15, 0)
	weapon_info.Position = UDim2.new(0, 10, 0.85, 0)
	weapon_info.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	weapon_info.BackgroundTransparency = 0.3
	weapon_info.BorderSizePixel = 0
	weapon_info.TextColor3 = Color3.fromRGB(200, 200, 200)
	weapon_info.TextSize = 14
	weapon_info.Font = Enum.Font.Gotham
	weapon_info.TextXAlignment = Enum.TextXAlignment.Left
	weapon_info.TextYAlignment = Enum.TextYAlignment.Bottom
	weapon_info.Text = "Sword\nMelee"
	weapon_info.Parent = screen_gui
	
	-- Bottom right - Minimap placeholder
	local minimap = Instance.new("Frame")
	minimap.Name = "Minimap"
	minimap.Size = UDim2.new(0.15, 0, 0.15, 0)
	minimap.Position = UDim2.new(0.85, 0, 0.85, 0)
	minimap.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	minimap.BackgroundTransparency = 0.3
	minimap.BorderSizePixel = 0
	minimap.Parent = screen_gui
	
	local minimap_text = Instance.new("TextLabel")
	minimap_text.Size = UDim2.new(1, 0, 1, 0)
	minimap_text.BackgroundTransparency = 1
	minimap_text.TextColor3 = Color3.fromRGB(200, 200, 200)
	minimap_text.TextSize = 12
	minimap_text.Font = Enum.Font.Gotham
	minimap_text.Text = "MINIMAP"
	minimap_text.Parent = minimap
	
	self.player_stats_label = player_stats
	self.mission_stats_label = mission_stats
	self.weapon_info_label = weapon_info
end

function MissionHUD:setup_update_loop()
	RunService.RenderStepped:Connect(function()
		self:update_hud()
	end)
end

function MissionHUD:update_hud()
	if not self.player_stats_label or not self.mission_stats_label then return end
	
	-- Update player stats
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		local humanoid = player.Character.Humanoid
		local player_data_folder = player.Character:FindFirstChild("PlayerData")
		
		local hp = math.floor(humanoid.Health)
		local max_hp = math.floor(humanoid.MaxHealth)
		
		self.player_stats_label.Text = string.format(
			"HP: %d/%d\nStamina: 100/100\nAmmo: 30/30",
			hp,
			max_hp
		)
	end
	
	-- Update mission stats (placeholder)
	self.mission_stats_label.Text = "Wave: 1\nEnemies: 5\nIntensity: 0.5"
end

return MissionHUD
