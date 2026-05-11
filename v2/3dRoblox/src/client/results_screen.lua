-- Results Screen - Displays mission results and statistics
local Players = game:GetService("Players")

local ResultsScreen = {}
ResultsScreen.__index = ResultsScreen

local player = Players.LocalPlayer

function ResultsScreen:initialize()
	print("[ResultsScreen] Initializing...")
	print("[ResultsScreen] Initialized")
end

function ResultsScreen:show_mission_complete(mission_stats, player_stats)
	self:_create_results_screen(true, mission_stats, player_stats)
end

function ResultsScreen:show_mission_failed(mission_stats, player_stats)
	self:_create_results_screen(false, mission_stats, player_stats)
end

function ResultsScreen:_create_results_screen(success, mission_stats, player_stats)
	local player_gui = player:FindFirstChild("PlayerGui")
	if not player_gui then
		print("[ResultsScreen] PlayerGui not found, waiting...")
		player_gui = player:WaitForChild("PlayerGui")
	end
	
	local screen_gui = Instance.new("ScreenGui")
	screen_gui.Name = "ResultsScreen"
	screen_gui.ResetOnSpawn = false
	screen_gui.Parent = player_gui
	
	-- Background
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = success and Color3.fromRGB(20, 30, 20) or Color3.fromRGB(30, 20, 20)
	background.BorderSizePixel = 0
	background.Parent = screen_gui
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.15, 0)
	title.Position = UDim2.new(0, 0, 0.05, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = success and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
	title.TextSize = 64
	title.Font = Enum.Font.GothamBold
	title.Text = success and "MISSION COMPLETE!" or "MISSION FAILED!"
	title.Parent = screen_gui
	
	-- Stats panel
	local stats_panel = Instance.new("Frame")
	stats_panel.Name = "StatsPanel"
	stats_panel.Size = UDim2.new(0.6, 0, 0.6, 0)
	stats_panel.Position = UDim2.new(0.2, 0, 0.25, 0)
	stats_panel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	stats_panel.BorderSizePixel = 1
	stats_panel.BorderColor3 = Color3.fromRGB(100, 100, 150)
	stats_panel.Parent = screen_gui
	
	-- Stats content
	local stats_text = Instance.new("TextLabel")
	stats_text.Name = "StatsText"
	stats_text.Size = UDim2.new(1, 0, 1, 0)
	stats_text.BackgroundTransparency = 1
	stats_text.TextColor3 = Color3.fromRGB(200, 200, 200)
	stats_text.TextSize = 16
	stats_text.Font = Enum.Font.GothamMonospace
	stats_text.TextXAlignment = Enum.TextXAlignment.Left
	stats_text.TextYAlignment = Enum.TextYAlignment.Top
	stats_text.Parent = stats_panel
	
	-- Build stats text
	local stats_content = "MISSION STATISTICS\n\n"
	
	if mission_stats then
		stats_content = stats_content ..
			"Waves Survived: " .. (mission_stats.wave_number or 0) .. "\n" ..
			"Enemies Defeated: " .. (mission_stats.enemies_defeated or 0) .. "\n" ..
			"Mission Duration: " .. self:_format_time(mission_stats.duration or 0) .. "\n\n"
	end
	
	if player_stats then
		stats_content = stats_content ..
			"PLAYER STATISTICS\n\n" ..
			"Kills: " .. (player_stats.kills or 0) .. "\n" ..
			"Deaths: " .. (player_stats.deaths or 0) .. "\n" ..
			"Damage Dealt: " .. math.floor(player_stats.damage_dealt or 0) .. "\n" ..
			"Damage Taken: " .. math.floor(player_stats.damage_taken or 0) .. "\n" ..
			"Gold Collected: " .. (player_stats.gold or 0) .. "\n" ..
			"Critical Hits: " .. (player_stats.critical_hits or 0) .. "\n"
	end
	
	stats_text.Text = stats_content
	
	-- Continue button
	local continue_button = Instance.new("TextButton")
	continue_button.Name = "ContinueButton"
	continue_button.Size = UDim2.new(0.2, 0, 0.08, 0)
	continue_button.Position = UDim2.new(0.4, 0, 0.88, 0)
	continue_button.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	continue_button.TextColor3 = Color3.fromRGB(255, 255, 255)
	continue_button.TextSize = 20
	continue_button.Font = Enum.Font.GothamBold
	continue_button.Text = "CONTINUE"
	continue_button.Parent = screen_gui
	
	continue_button.MouseButton1Click:Connect(function()
		screen_gui:Destroy()
	end)
end

function ResultsScreen:_format_time(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", minutes, secs)
end

return ResultsScreen
