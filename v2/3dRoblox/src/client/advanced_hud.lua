-- Advanced HUD - Minimap, radar, objectives, and detailed stats
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AdvancedHUD = {}
AdvancedHUD.__index = AdvancedHUD

local player = Players.LocalPlayer

function AdvancedHUD:initialize()
	print("[AdvancedHUD] Initializing...")
	
	local player_gui = player:FindFirstChild("PlayerGui")
	if not player_gui then
		print("[AdvancedHUD] PlayerGui not found, waiting...")
		player_gui = player:WaitForChild("PlayerGui")
	end
	
	self:create_advanced_hud(player_gui)
	self:setup_update_loop()
	
	print("[AdvancedHUD] Initialized")
end

function AdvancedHUD:create_advanced_hud(player_gui)
	local screen_gui = Instance.new("ScreenGui")
	screen_gui.Name = "AdvancedHUD"
	screen_gui.ResetOnSpawn = false
	screen_gui.Parent = player_gui
	
	-- Top left - Detailed player stats
	local player_stats = Instance.new("TextLabel")
	player_stats.Name = "PlayerStats"
	player_stats.Size = UDim2.new(0.25, 0, 0.25, 0)
	player_stats.Position = UDim2.new(0, 10, 0, 10)
	player_stats.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	player_stats.BackgroundTransparency = 0.2
	player_stats.BorderSizePixel = 1
	player_stats.BorderColor3 = Color3.fromRGB(100, 100, 150)
	player_stats.TextColor3 = Color3.fromRGB(200, 200, 200)
	player_stats.TextSize = 12
	player_stats.Font = Enum.Font.Gotham
	player_stats.TextXAlignment = Enum.TextXAlignment.Left
	player_stats.TextYAlignment = Enum.TextYAlignment.Top
	player_stats.Text = "HP: 100/100\nStamina: 100/100\nGold: 0\nLevel: 1"
	player_stats.Parent = screen_gui
	
	-- Top right - Mission objectives
	local objectives = Instance.new("TextLabel")
	objectives.Name = "Objectives"
	objectives.Size = UDim2.new(0.25, 0, 0.25, 0)
	objectives.Position = UDim2.new(0.75, -10, 0, 10)
	objectives.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	objectives.BackgroundTransparency = 0.2
	objectives.BorderSizePixel = 1
	objectives.BorderColor3 = Color3.fromRGB(100, 100, 150)
	objectives.TextColor3 = Color3.fromRGB(200, 200, 200)
	objectives.TextSize = 12
	objectives.Font = Enum.Font.Gotham
	objectives.TextXAlignment = Enum.TextXAlignment.Right
	objectives.TextYAlignment = Enum.TextYAlignment.Top
	objectives.Text = "WAVE: 1\nENEMIES: 0\nINTENSITY: 0.3\nTIME: 0:00"
	objectives.Parent = screen_gui
	
	-- Center - Crosshair with distance
	local crosshair_frame = Instance.new("Frame")
	crosshair_frame.Name = "CrosshairFrame"
	crosshair_frame.Size = UDim2.new(0.08, 0, 0.15, 0)
	crosshair_frame.Position = UDim2.new(0.46, 0, 0.425, 0)
	crosshair_frame.BackgroundTransparency = 1
	crosshair_frame.Parent = screen_gui
	
	local crosshair = Instance.new("TextLabel")
	crosshair.Name = "Crosshair"
	crosshair.Size = UDim2.new(1, 0, 0.5, 0)
	crosshair.Position = UDim2.new(0, 0, 0.25, 0)
	crosshair.BackgroundTransparency = 1
	crosshair.TextColor3 = Color3.fromRGB(100, 255, 100)
	crosshair.TextSize = 28
	crosshair.Font = Enum.Font.GothamBold
	crosshair.Text = "+"
	crosshair.Parent = crosshair_frame
	
	local distance = Instance.new("TextLabel")
	distance.Name = "Distance"
	distance.Size = UDim2.new(1, 0, 0.5, 0)
	distance.Position = UDim2.new(0, 0, 0.5, 0)
	distance.BackgroundTransparency = 1
	distance.TextColor3 = Color3.fromRGB(150, 200, 100)
	distance.TextSize = 10
	distance.Font = Enum.Font.Gotham
	distance.Text = "0m"
	distance.Parent = crosshair_frame
	
	-- Bottom left - Weapon and inventory
	local weapon_info = Instance.new("TextLabel")
	weapon_info.Name = "WeaponInfo"
	weapon_info.Size = UDim2.new(0.2, 0, 0.2, 0)
	weapon_info.Position = UDim2.new(0, 10, 0.8, 0)
	weapon_info.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	weapon_info.BackgroundTransparency = 0.2
	weapon_info.BorderSizePixel = 1
	weapon_info.BorderColor3 = Color3.fromRGB(100, 100, 150)
	weapon_info.TextColor3 = Color3.fromRGB(200, 200, 200)
	weapon_info.TextSize = 12
	weapon_info.Font = Enum.Font.Gotham
	weapon_info.TextXAlignment = Enum.TextXAlignment.Left
	weapon_info.TextYAlignment = Enum.TextYAlignment.Bottom
	weapon_info.Text = "SWORD\nMelee | 25 DMG\n[1] [2] [3] [4]"
	weapon_info.Parent = screen_gui
	
	-- Bottom right - Minimap
	local minimap_frame = Instance.new("Frame")
	minimap_frame.Name = "MinimapFrame"
	minimap_frame.Size = UDim2.new(0.2, 0, 0.2, 0)
	minimap_frame.Position = UDim2.new(0.8, 0, 0.8, 0)
	minimap_frame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
	minimap_frame.BackgroundTransparency = 0.2
	minimap_frame.BorderSizePixel = 1
	minimap_frame.BorderColor3 = Color3.fromRGB(100, 100, 150)
	minimap_frame.Parent = screen_gui
	
	-- Minimap canvas
	local minimap_canvas = Instance.new("TextLabel")
	minimap_canvas.Name = "MinimapCanvas"
	minimap_canvas.Size = UDim2.new(1, 0, 1, 0)
	minimap_canvas.BackgroundTransparency = 1
	minimap_canvas.TextColor3 = Color3.fromRGB(100, 200, 100)
	minimap_canvas.TextSize = 10
	minimap_canvas.Font = Enum.Font.Gotham
	minimap_canvas.Text = "MINIMAP"
	minimap_canvas.Parent = minimap_frame
	
	-- Radar - Shows nearby enemies
	local radar_frame = Instance.new("Frame")
	radar_frame.Name = "RadarFrame"
	radar_frame.Size = UDim2.new(0.15, 0, 0.15, 0)
	radar_frame.Position = UDim2.new(0.425, 0, 0.1, 0)
	radar_frame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
	radar_frame.BackgroundTransparency = 0.3
	radar_frame.BorderSizePixel = 1
	radar_frame.BorderColor3 = Color3.fromRGB(150, 100, 100)
	radar_frame.Parent = screen_gui
	
	local radar_label = Instance.new("TextLabel")
	radar_label.Name = "RadarLabel"
	radar_label.Size = UDim2.new(1, 0, 1, 0)
	radar_label.BackgroundTransparency = 1
	radar_label.TextColor3 = Color3.fromRGB(255, 100, 100)
	radar_label.TextSize = 8
	radar_label.Font = Enum.Font.Gotham
	radar_label.Text = "RADAR\n• • •"
	radar_label.Parent = radar_frame
	
	-- Health bar
	local health_bar_bg = Instance.new("Frame")
	health_bar_bg.Name = "HealthBarBG"
	health_bar_bg.Size = UDim2.new(0.3, 0, 0.03, 0)
	health_bar_bg.Position = UDim2.new(0.35, 0, 0.95, 0)
	health_bar_bg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	health_bar_bg.BorderSizePixel = 1
	health_bar_bg.BorderColor3 = Color3.fromRGB(100, 100, 100)
	health_bar_bg.Parent = screen_gui
	
	local health_bar_fg = Instance.new("Frame")
	health_bar_fg.Name = "HealthBarFG"
	health_bar_fg.Size = UDim2.new(1, 0, 1, 0)
	health_bar_fg.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	health_bar_fg.BorderSizePixel = 0
	health_bar_fg.Parent = health_bar_bg
	
	self.player_stats_label = player_stats
	self.objectives_label = objectives
	self.distance_label = distance
	self.health_bar_fg = health_bar_fg
	self.radar_label = radar_label
end

function AdvancedHUD:setup_update_loop()
	RunService.RenderStepped:Connect(function()
		self:update_hud()
	end)
end

function AdvancedHUD:update_hud()
	if not self.player_stats_label then return end
	
	-- Update player stats
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		local humanoid = player.Character.Humanoid
		local player_data_folder = player.Character:FindFirstChild("PlayerData")
		
		local hp = math.floor(humanoid.Health)
		local max_hp = math.floor(humanoid.MaxHealth)
		local gold = 0
		
		if player_data_folder then
			local gold_value = player_data_folder:FindFirstChild("Gold")
			if gold_value then
				gold = gold_value.Value
			end
		end
		
		self.player_stats_label.Text = string.format(
			"HP: %d/%d\nStamina: 100/100\nGold: %d\nLevel: 1",
			hp,
			max_hp,
			gold
		)
		
		-- Update health bar
		local health_ratio = hp / max_hp
		self.health_bar_fg.Size = UDim2.new(health_ratio, 0, 1, 0)
		self.health_bar_fg.BackgroundColor3 = Color3.fromRGB(
			255 * (1 - health_ratio),
			255 * health_ratio,
			0
		)
	end
	
	-- Update objectives (placeholder)
	self.objectives_label.Text = "WAVE: 1\nENEMIES: 5\nINTENSITY: 0.5\nTIME: 0:30"
	
	-- Update distance (placeholder)
	self.distance_label.Text = "25m"
	
	-- Update radar (placeholder)
	self.radar_label.Text = "RADAR\n• • •"
end

return AdvancedHUD
