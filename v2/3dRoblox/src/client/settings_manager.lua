-- Settings Manager - Handles game settings and preferences
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local SettingsManager = {}
SettingsManager.__index = SettingsManager

function SettingsManager.new()
	local self = setmetatable({}, SettingsManager)
	
	self.settings = {
		-- Graphics
		graphics_quality = 2, -- 1=Low, 2=Medium, 3=High, 4=Ultra
		resolution_scale = 1.0,
		motion_blur = true,
		bloom = true,
		shadows = true,
		
		-- Audio
		master_volume = 1.0,
		music_volume = 0.5,
		sfx_volume = 0.7,
		voice_volume = 0.8,
		
		-- Gameplay
		mouse_sensitivity = 0.003,
		invert_mouse = false,
		field_of_view = 70,
		motion_sickness_mode = false,
		
		-- UI
		hud_scale = 1.0,
		show_fps = false,
		colorblind_mode = false,
		
		-- Controls
		sprint_toggle = false,
		crouch_toggle = false,
	}
	
	self.settings_file = "user://gravegain_settings.json"
	
	return self
end

function SettingsManager:initialize()
	print("[SettingsManager] Initializing...")
	
	self:load_settings()
	self:create_settings_ui()
	
	print("[SettingsManager] Initialized")
end

function SettingsManager:load_settings()
	-- In a real implementation, would load from file
	-- For now, using defaults
	print("[SettingsManager] Settings loaded")
end

function SettingsManager:save_settings()
	-- In a real implementation, would save to file
	print("[SettingsManager] Settings saved")
end

function SettingsManager:create_settings_ui()
	local player = Players.LocalPlayer
	local player_gui = player:WaitForChild("PlayerGui")
	
	local screen_gui = Instance.new("ScreenGui")
	screen_gui.Name = "SettingsUI"
	screen_gui.ResetOnSpawn = false
	screen_gui.Enabled = false
	screen_gui.Parent = player_gui
	
	-- Background
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.5
	background.BorderSizePixel = 0
	background.Parent = screen_gui
	
	-- Settings panel
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0.6, 0, 0.8, 0)
	panel.Position = UDim2.new(0.2, 0, 0.1, 0)
	panel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	panel.BorderSizePixel = 1
	panel.BorderColor3 = Color3.fromRGB(100, 100, 150)
	panel.Parent = screen_gui
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.1, 0)
	title.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	title.TextColor3 = Color3.fromRGB(200, 200, 255)
	title.TextSize = 28
	title.Font = Enum.Font.GothamBold
	title.Text = "SETTINGS"
	title.Parent = panel
	
	-- Tabs
	local tabs_frame = Instance.new("Frame")
	tabs_frame.Name = "TabsFrame"
	tabs_frame.Size = UDim2.new(0.2, 0, 0.8, 0)
	tabs_frame.Position = UDim2.new(0, 0, 0.1, 0)
	tabs_frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	tabs_frame.BorderSizePixel = 0
	tabs_frame.Parent = panel
	
	local tab_names = { "Graphics", "Audio", "Gameplay", "UI" }
	for i, tab_name in ipairs(tab_names) do
		local tab_button = Instance.new("TextButton")
		tab_button.Name = tab_name .. "Tab"
		tab_button.Size = UDim2.new(1, 0, 0.2, 0)
		tab_button.Position = UDim2.new(0, 0, (i - 1) * 0.2, 0)
		tab_button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		tab_button.TextColor3 = Color3.fromRGB(200, 200, 200)
		tab_button.TextSize = 14
		tab_button.Font = Enum.Font.GothamBold
		tab_button.Text = tab_name
		tab_button.BorderSizePixel = 0
		tab_button.Parent = tabs_frame
		
		tab_button.MouseButton1Click:Connect(function()
			self:switch_tab(tab_name)
		end)
	end
	
	-- Content area
	local content_frame = Instance.new("Frame")
	content_frame.Name = "ContentFrame"
	content_frame.Size = UDim2.new(0.8, 0, 0.8, 0)
	content_frame.Position = UDim2.new(0.2, 0, 0.1, 0)
	content_frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	content_frame.BorderSizePixel = 0
	content_frame.Parent = panel
	
	local content_label = Instance.new("TextLabel")
	content_label.Name = "ContentLabel"
	content_label.Size = UDim2.new(1, 0, 1, 0)
	content_label.BackgroundTransparency = 1
	content_label.TextColor3 = Color3.fromRGB(200, 200, 200)
	content_label.TextSize = 14
	content_label.Font = Enum.Font.GothamBold
	content_label.TextXAlignment = Enum.TextXAlignment.Left
	content_label.TextYAlignment = Enum.TextYAlignment.Top
	content_label.Text = "Graphics Settings\n\nQuality: Medium\nMotion Blur: On\nBloom: On\nShadows: On"
	content_label.Parent = content_frame
	
	-- Close button
	local close_button = Instance.new("TextButton")
	close_button.Name = "CloseButton"
	close_button.Size = UDim2.new(0.1, 0, 0.05, 0)
	close_button.Position = UDim2.new(0.85, 0, 0.02, 0)
	close_button.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
	close_button.TextColor3 = Color3.fromRGB(255, 255, 255)
	close_button.TextSize = 14
	close_button.Font = Enum.Font.GothamBold
	close_button.Text = "X"
	close_button.Parent = panel
	
	close_button.MouseButton1Click:Connect(function()
		self:toggle_settings()
	end)
	
	self.content_label = content_label
end

function SettingsManager:toggle_settings()
	local player = Players.LocalPlayer
	local player_gui = player:WaitForChild("PlayerGui")
	local settings_ui = player_gui:FindFirstChild("SettingsUI")
	
	if settings_ui then
		settings_ui.Enabled = not settings_ui.Enabled
	end
end

function SettingsManager:switch_tab(tab_name)
	if not self.content_label then return end
	
	local content_label = self.content_label
	
	if tab_name == "Graphics" then
		content_label.Text = "Graphics Settings\n\nQuality: " .. self:_get_quality_name() ..
			"\nMotion Blur: " .. (self.settings.motion_blur and "On" or "Off") ..
			"\nBloom: " .. (self.settings.bloom and "On" or "Off") ..
			"\nShadows: " .. (self.settings.shadows and "On" or "Off")
	elseif tab_name == "Audio" then
		content_label.Text = "Audio Settings\n\nMaster Volume: " .. math.floor(self.settings.master_volume * 100) .. "%" ..
			"\nMusic Volume: " .. math.floor(self.settings.music_volume * 100) .. "%" ..
			"\nSFX Volume: " .. math.floor(self.settings.sfx_volume * 100) .. "%" ..
			"\nVoice Volume: " .. math.floor(self.settings.voice_volume * 100) .. "%"
	elseif tab_name == "Gameplay" then
		content_label.Text = "Gameplay Settings\n\nMouse Sensitivity: " .. self.settings.mouse_sensitivity ..
			"\nInvert Mouse: " .. (self.settings.invert_mouse and "On" or "Off") ..
			"\nFOV: " .. self.settings.field_of_view ..
			"\nMotion Sickness Mode: " .. (self.settings.motion_sickness_mode and "On" or "Off")
	elseif tab_name == "UI" then
		content_label.Text = "UI Settings\n\nHUD Scale: " .. self.settings.hud_scale ..
			"\nShow FPS: " .. (self.settings.show_fps and "On" or "Off") ..
			"\nColorblind Mode: " .. (self.settings.colorblind_mode and "On" or "Off")
	end
end

function SettingsManager:_get_quality_name()
	local quality_names = {
		[1] = "Low",
		[2] = "Medium",
		[3] = "High",
		[4] = "Ultra",
	}
	return quality_names[self.settings.graphics_quality] or "Medium"
end

function SettingsManager:get_setting(key)
	return self.settings[key]
end

function SettingsManager:set_setting(key, value)
	if self.settings[key] ~= nil then
		self.settings[key] = value
		self:save_settings()
	end
end

return SettingsManager
