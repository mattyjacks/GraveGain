-- talent_ui.lua (CLIENT)
-- UI for spending talent points on various stat bonuses.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameData = require(Shared:WaitForChild("game_data"))

local TalentUI = {}
TalentUI.__index = TalentUI

function TalentUI.new(playerStats)
	local self = setmetatable({}, TalentUI)
	self.stats = playerStats
	self.gui = nil
	self.isOpen = false
	
	self:setupInput()
	return self
end

function TalentUI:setupInput()
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.T then -- 'T' for Talents
			self:toggle()
		end
	end)
end

function TalentUI:toggle()
	self.isOpen = not self.isOpen
	if self.isOpen then
		self:show()
	elseif self.gui then
		self.gui:Destroy()
		self.gui = nil
	end
end

function TalentUI:show()
	if self.gui then self.gui:Destroy() end
	
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui")
	
	local sg = Instance.new("ScreenGui")
	sg.Name = "TalentUI"
	sg.Parent = pg
	self.gui = sg
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 600, 0, 450)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	frame.BorderSizePixel = 0
	frame.Parent = sg
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 60)
	title.BackgroundTransparency = 1
	title.Text = "TALENT TREE"
	title.TextColor3 = Color3.fromRGB(255, 215, 100)
	title.TextSize = 32
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	
	local pointsLbl = Instance.new("TextLabel")
	pointsLbl.Size = UDim2.new(1, 0, 0, 30)
	pointsLbl.Position = UDim2.new(0, 0, 0, 60)
	pointsLbl.BackgroundTransparency = 1
	pointsLbl.Text = "Available Points: " .. (self.stats.talentPoints or 0)
	pointsLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	pointsLbl.TextSize = 18
	pointsLbl.Font = Enum.Font.Gotham
	pointsLbl.Parent = frame
	
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -40, 1, -120)
	container.Position = UDim2.new(0, 20, 0, 100)
	container.BackgroundTransparency = 1
	container.Parent = frame
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.Parent = container
	
	for talentKey, talent in pairs(GameData.TALENTS) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 60)
		row.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
		row.BorderSizePixel = 0
		row.Parent = container
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
		
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(0.6, 0, 0.6, 0)
		nameLbl.Position = UDim2.new(0.05, 0, 0.1, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = talent.name
		nameLbl.TextColor3 = Color3.new(1,1,1)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextSize = 18
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.Parent = row
		
		local descLbl = Instance.new("TextLabel")
		descLbl.Size = UDim2.new(0.6, 0, 0.4, 0)
		descLbl.Position = UDim2.new(0.05, 0, 0.6, 0)
		descLbl.BackgroundTransparency = 1
		descLbl.Text = talent.desc
		descLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
		descLbl.TextXAlignment = Enum.TextXAlignment.Left
		descLbl.TextSize = 14
		descLbl.Font = Enum.Font.Gotham
		descLbl.Parent = row
		
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.3, 0, 0.6, 0)
		btn.Position = UDim2.new(0.65, 0, 0.2, 0)
		btn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
		
		local currentLv = (self.stats.talents and self.stats.talents[talentKey]) or 0
		btn.Text = "Level " .. currentLv .. "/" .. talent.max
		btn.TextColor3 = Color3.new(1,1,1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		btn.Parent = row
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		
		if (self.stats.talentPoints or 0) > 0 and currentLv < talent.max then
			btn.MouseButton1Click:Connect(function()
				ReplicatedStorage.SpendTalentPoint:FireServer(talentKey)
				task.wait(0.1)
				self:show() -- Refresh
			end)
		else
			btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		end
	end
end

return TalentUI
