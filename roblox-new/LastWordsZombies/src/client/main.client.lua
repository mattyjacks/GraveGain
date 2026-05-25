-- Main client script for Dead-Letter Drop
-- Initializes all client-side systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Wire character hiding BEFORE waiting, so first spawn is never missed
local function HidePart(part)
	if part:IsA("BasePart") then
		part.Transparency = 1
		part.CanCollide = false
	elseif part:IsA("Decal") or part:IsA("SpecialMesh") or part:IsA("Texture") then
		part.Transparency = 1
	end
end

local function HideCharacter(character)
	-- Use timeout so we don't yield forever if character is destroyed mid-respawn
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	local hum = character:WaitForChild("Humanoid", 10)
	if not hrp or not hum then
		print("[CLIENT CHAR] HideCharacter timeout - character was destroyed before fully loading, skipping")
		return
	end
	for _, part in ipairs(character:GetDescendants()) do HidePart(part) end
	character.DescendantAdded:Connect(HidePart)
	hrp.Anchored = true
	hrp.CFrame = CFrame.new(0, -500, 0)
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.AutoRotate = false
	print("[CLIENT CHAR] Character hidden and frozen for", player.Name)
end

player.CharacterAdded:Connect(function(c)
	print("[CLIENT CHAR] CharacterAdded fired for", player.Name, "- spawning HideCharacter")
	task.spawn(HideCharacter, c)
end)
if player.Character then
	print("[CLIENT CHAR] Character already exists at script start - hiding immediately")
	task.spawn(HideCharacter, player.Character)
else
	print("[CLIENT CHAR] No character yet at script start - waiting for CharacterAdded")
end

print("[CLIENT BOOT] Waiting for RemoteEvents in ReplicatedStorage...")
-- Wait for game to load
ReplicatedStorage:WaitForChild("RemoteEvents")
print("[CLIENT BOOT] RemoteEvents found!")

-- Require modules
local TypingHandler = require(script.Parent.TypingHandler)
local WordDictionaryUI = require(script.Parent.WordDictionaryUI)
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

-- Remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Client state
local gameState = {
	isPlaying = false,
	currentWave = 1,
	score = 0,
	hasStarted = false,
	defeatedWords = {}
}

-- Initialize game
function InitializeGame()
	print("[CLIENT BOOT] ====== InitializeGame() called ======")
	print("[CLIENT BOOT] player=", player.Name, "userId=", player.UserId)

	-- Set up camera
	SetupCamera()
	
	print("[CLIENT BOOT] Camera set up")
	-- Initialize typing handler
	TypingHandler.Initialize()
	print("[CLIENT BOOT] TypingHandler initialized")

	-- Create UI
	CreateGameUI()
	print("[CLIENT BOOT] GameUI created")

	-- Connect remote events
	ConnectRemoteEvents()
	print("[CLIENT BOOT] RemoteEvents connected")

	-- Show start menu
	ShowStartMenu()
	print("[CLIENT BOOT] StartMenu shown - waiting for player input")
end

-- Set up camera
function SetupCamera()
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(Vector3.new(0, 5, 20), Vector3.new(0, 5, 0))
	camera.FieldOfView = 70
end

-- Create game UI
function CreateGameUI()
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Main game UI
	local gameUi = Instance.new("ScreenGui")
	gameUi.Name = "GameUI"
	gameUi.ResetOnSpawn = false
	gameUi.Parent = playerGui
	
	-- Score display
	local scoreFrame = Instance.new("Frame")
	scoreFrame.Name = "ScoreFrame"
	scoreFrame.Size = UDim2.new(0, 200, 0, 80)
	scoreFrame.Position = UDim2.new(0, 10, 0, 10)
	scoreFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	scoreFrame.BackgroundTransparency = 0.3
	scoreFrame.BorderSizePixel = 2
	scoreFrame.BorderColor3 = Color3.new(0, 1, 0.5)
	scoreFrame.Parent = gameUi
	
	local scoreLabel = Instance.new("TextLabel")
	scoreLabel.Name = "ScoreLabel"
	scoreLabel.Size = UDim2.new(1, -20, 0.5, -10)
	scoreLabel.Position = UDim2.new(0, 10, 0, 5)
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.Text = "SCORE: 0"
	scoreLabel.TextColor3 = Color3.new(0, 1, 0.5)
	scoreLabel.TextScaled = true
	scoreLabel.Font = Enum.Font.SourceSansBold
	scoreLabel.TextXAlignment = Enum.TextXAlignment.Left
	scoreLabel.Parent = scoreFrame
	
	local waveLabel = Instance.new("TextLabel")
	waveLabel.Name = "WaveLabel"
	waveLabel.Size = UDim2.new(1, -20, 0.5, -10)
	waveLabel.Position = UDim2.new(0, 10, 0.5, 5)
	waveLabel.BackgroundTransparency = 1
	waveLabel.Text = "WAVE: 1"
	waveLabel.TextColor3 = Color3.new(1, 1, 1)
	waveLabel.TextScaled = true
	scoreLabel.Font = Enum.Font.SourceSansBold
	waveLabel.TextXAlignment = Enum.TextXAlignment.Left
	waveLabel.Parent = scoreFrame
	
	-- Game over screen (hidden initially)
	local gameOverScreen = Instance.new("Frame")
	gameOverScreen.Name = "GameOverScreen"
	gameOverScreen.Size = UDim2.new(1, 0, 1, 0)
	gameOverScreen.Position = UDim2.new(0, 0, 0, 0)
	gameOverScreen.BackgroundColor3 = Color3.new(0, 0, 0)
	gameOverScreen.BackgroundTransparency = 0.8
	gameOverScreen.Visible = false
	gameOverScreen.Parent = gameUi
	
	local gameOverTitle = Instance.new("TextLabel")
	gameOverTitle.Name = "GameOverTitle"
	gameOverTitle.Size = UDim2.new(0, 400, 0, 100)
	gameOverTitle.Position = UDim2.new(0.5, -200, 0.3, -50)
	gameOverTitle.BackgroundTransparency = 1
	gameOverTitle.Text = "GAME OVER"
	gameOverTitle.TextColor3 = Color3.new(1, 0, 0)
	gameOverTitle.TextScaled = true
	gameOverTitle.Font = Enum.Font.SourceSansBold
	gameOverTitle.Parent = gameOverScreen
	
	local finalScoreLabel = Instance.new("TextLabel")
	finalScoreLabel.Name = "FinalScoreLabel"
	finalScoreLabel.Size = UDim2.new(0, 400, 0, 60)
	finalScoreLabel.Position = UDim2.new(0.5, -200, 0.5, -30)
	finalScoreLabel.BackgroundTransparency = 1
	finalScoreLabel.Text = "FINAL SCORE: 0"
	finalScoreLabel.TextColor3 = Color3.new(1, 1, 1)
	finalScoreLabel.TextScaled = true
	finalScoreLabel.Font = Enum.Font.SourceSans
	finalScoreLabel.Parent = gameOverScreen
	
	local dictionaryButton = Instance.new("TextButton")
	dictionaryButton.Name = "DictionaryButton"
	dictionaryButton.Size = UDim2.new(0, 200, 0, 60)
	dictionaryButton.Position = UDim2.new(0.5, -100, 0.65, -30)
	dictionaryButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1.0)
	dictionaryButton.BorderSizePixel = 0
	dictionaryButton.Text = "📚 VIEW DICTIONARY"
	dictionaryButton.TextColor3 = Color3.new(1, 1, 1)
	dictionaryButton.TextScaled = true
	dictionaryButton.Font = Enum.Font.SourceSansBold
	dictionaryButton.Parent = gameOverScreen
	
	dictionaryButton.MouseButton1Click:Connect(function()
		WordDictionaryUI.Show(gameState.defeatedWords)
	end)
	
	local restartButton = Instance.new("TextButton")
	restartButton.Name = "RestartButton"
	restartButton.Size = UDim2.new(0, 200, 0, 60)
	restartButton.Position = UDim2.new(0.5, -100, 0.75, -30)
	restartButton.BackgroundColor3 = Color3.new(0, 1, 0.5)
	restartButton.BorderSizePixel = 0
	restartButton.Text = "RESTART"
	restartButton.TextColor3 = Color3.new(0, 0, 0)
	restartButton.TextScaled = true
	restartButton.Font = Enum.Font.SourceSansBold
	restartButton.Parent = gameOverScreen
	
	restartButton.MouseButton1Click:Connect(function()
		RestartGame()
	end)
end

-- Show start menu
function ShowStartMenu()
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Create start menu
	local startMenu = Instance.new("ScreenGui")
	startMenu.Name = "StartMenu"
	startMenu.ResetOnSpawn = false
	startMenu.Parent = playerGui
	
	-- Background
	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.new(0, 0, 0)
	background.BackgroundTransparency = 0.2
	background.Parent = startMenu
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 700, 0, 100)
	title.Position = UDim2.new(0.5, -350, 0.2, -50)
	title.BackgroundTransparency = 1
	title.Text = "LAST WORDS ZOMBIES"
	title.TextColor3 = Color3.new(0, 1, 0.5)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = startMenu
	
	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(0, 600, 0, 40)
	subtitle.Position = UDim2.new(0.5, -300, 0.3, -20)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Type the words. Survive the horde."
	subtitle.TextColor3 = Color3.new(1, 1, 1)
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.SourceSans
	subtitle.Parent = startMenu
	
	-- Start button
	local startButton = Instance.new("TextButton")
	startButton.Size = UDim2.new(0, 250, 0, 80)
	startButton.Position = UDim2.new(0.5, -125, 0.6, -40)
	startButton.BackgroundColor3 = Color3.new(0, 1, 0.5)
	startButton.BorderSizePixel = 0
	startButton.Text = "START GAME"
	startButton.TextColor3 = Color3.new(0, 0, 0)
	startButton.TextScaled = true
	startButton.Font = Enum.Font.SourceSansBold
	startButton.Parent = startMenu
	
	-- Instructions
	local instructions = Instance.new("TextLabel")
	instructions.Size = UDim2.new(0, 600, 0, 120)
	instructions.Position = UDim2.new(0.5, -300, 0.8, -60)
	instructions.BackgroundTransparency = 1
	instructions.Text = "Type the words above zombie heads to destroy them.\nWords are auto-targeted by first letter.\nSurvive as long as you can!"
	instructions.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	instructions.TextScaled = false
	instructions.Font = Enum.Font.SourceSans
	instructions.TextSize = 18
	instructions.TextWrapped = true
	instructions.Parent = startMenu
	
	-- Handle start button
	startButton.MouseButton1Click:Connect(function()
		startMenu:Destroy()
		StartGame()
	end)
	
	-- Handle Enter key
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Return then
			if startMenu.Parent then
				startMenu:Destroy()
				StartGame()
			end
		end
	end)
end

-- Start the game
function StartGame()
	print("[STARTGAME CLIENT] ====== StartGame() called on client ======")
	print("[STARTGAME CLIENT] gameState before:", "isPlaying=", gameState.isPlaying, "hasStarted=", gameState.hasStarted, "wave=", gameState.currentWave, "score=", gameState.score)

	gameState.isPlaying = true
	gameState.hasStarted = true

	-- Enable typing handler
	TypingHandler.SetEnabled(true)
	print("[STARTGAME CLIENT] TypingHandler enabled")

	-- Notify server we're ready
	print("[STARTGAME CLIENT] Firing PlayerReady to server")
	RemoteEvents.PlayerReady:FireServer()

	-- Hide any game over screen
	local gameUi = player:WaitForChild("PlayerGui"):FindFirstChild("GameUI")
	if gameUi then
		local gameOverScreen = gameUi:FindFirstChild("GameOverScreen")
		if gameOverScreen then
			gameOverScreen.Visible = false
			print("[STARTGAME CLIENT] GameOverScreen hidden")
		end
	else
		print("[STARTGAME CLIENT] WARNING: GameUI not found in PlayerGui!")
	end
end

-- Restart the game
function RestartGame()
	print("[RESTART CLIENT] ====== RestartGame() called ======")
	print("[RESTART CLIENT] gameState before reset:", "isPlaying=", gameState.isPlaying, "wave=", gameState.currentWave, "score=", gameState.score)

	-- Reset local state
	gameState.isPlaying = false
	gameState.currentWave = 1
	gameState.score = 0
	gameState.hasStarted = false

	-- Reset typing handler
	TypingHandler.SetEnabled(false)
	TypingHandler.ResetTyping()
	print("[RESTART CLIENT] TypingHandler disabled and reset")

	-- Tell server to restart - it will fire GameStart back to all clients
	print("[RESTART CLIENT] Firing GameStart to server - waiting for server GameStart response")
	RemoteEvents.GameStart:FireServer()
	print("[RESTART CLIENT] NOTE: Do NOT call StartGame() here - wait for server's GameStart event")
end

-- Update score display
function UpdateScore(newScore)
	gameState.score = newScore
	
	local gameUi = player:WaitForChild("PlayerGui"):FindFirstChild("GameUI")
	if gameUi then
		local scoreFrame = gameUi:FindFirstChild("ScoreFrame")
		if scoreFrame then
			local scoreLabel = scoreFrame:FindFirstChild("ScoreLabel")
			if scoreLabel then
				scoreLabel.Text = "SCORE: " .. newScore
			end
		end
	end
end

-- Update wave display
function UpdateWave(waveNumber)
	gameState.currentWave = waveNumber
	
	local gameUi = player:WaitForChild("PlayerGui"):FindFirstChild("GameUI")
	if gameUi then
		local scoreFrame = gameUi:FindFirstChild("ScoreFrame")
		if scoreFrame then
			local waveLabel = scoreFrame:FindFirstChild("WaveLabel")
			if waveLabel then
				waveLabel.Text = "WAVE: " .. waveNumber
			end
		end
	end
end

-- Lock player in place on game over
function LockPlayer()
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end
	-- Lock camera to fixed position
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(Vector3.new(0, 5, 20), Vector3.new(0, 5, 0))
end

-- Show game over screen
function ShowGameOver(reason, finalScore, defeatedWords)
	print("Game over:", reason, "Score:", finalScore, "Words learned:", #(defeatedWords or {}))
	
	gameState.isPlaying = false
	gameState.defeatedWords = defeatedWords or {}
	
	-- Disable typing handler
	TypingHandler.SetEnabled(false)

	-- Lock player movement and camera
	LockPlayer()
	
	local gameUi = player:WaitForChild("PlayerGui"):FindFirstChild("GameUI")
	if gameUi then
		local gameOverScreen = gameUi:FindFirstChild("GameOverScreen")
		if gameOverScreen then
			-- Make it fully opaque so player can't see/interact with game
			gameOverScreen.BackgroundTransparency = 0
			gameOverScreen.BackgroundColor3 = Color3.new(0, 0, 0)
			gameOverScreen.Visible = true
			gameOverScreen.ZIndex = 10
			
			local gameOverTitle = gameOverScreen:FindFirstChild("GameOverTitle")
			if gameOverTitle then
				gameOverTitle.ZIndex = 11
				if reason == "zombie_reached" then
					gameOverTitle.Text = "THEY GOT YOU!"
				else
					gameOverTitle.Text = "GAME OVER"
				end
			end

			local finalScoreLabel = gameOverScreen:FindFirstChild("FinalScoreLabel")
			if finalScoreLabel then
				finalScoreLabel.ZIndex = 11
				finalScoreLabel.Text = "FINAL SCORE: " .. (finalScore or 0)
			end

			-- Set ZIndex on buttons too
			for _, child in ipairs(gameOverScreen:GetChildren()) do
				if child:IsA("GuiObject") then
					child.ZIndex = 11
				end
			end
		end
	end

	-- Show word dictionary after a short delay
	if defeatedWords and #defeatedWords > 0 then
		task.delay(1.0, function()
			WordDictionaryUI.Show(defeatedWords)
		end)
	end
end

-- Reset all UI and state for a fresh game
function ResetForNewGame()
	gameState.isPlaying = true
	gameState.hasStarted = true
	gameState.currentWave = 1
	gameState.score = 0

	-- Hide game over screen
	local gameUi = player:WaitForChild("PlayerGui"):FindFirstChild("GameUI")
	if gameUi then
		local gameOverScreen = gameUi:FindFirstChild("GameOverScreen")
		if gameOverScreen then
			gameOverScreen.Visible = false
		end
		-- Reset HUD
		local scoreFrame = gameUi:FindFirstChild("ScoreFrame")
		if scoreFrame then
			local s = scoreFrame:FindFirstChild("ScoreLabel")
			local w = scoreFrame:FindFirstChild("WaveLabel")
			if s then s.Text = "SCORE: 0" end
			if w then w.Text = "WAVE: 1" end
		end
	end

	-- Reset camera
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(Vector3.new(0, 5, 20), Vector3.new(0, 5, 0))

	-- Re-enable typing
	TypingHandler.SetEnabled(true)
	TypingHandler.ResetTyping()
end

-- Connect remote events
function ConnectRemoteEvents()
	print("[EVENTS] Connecting all RemoteEvent listeners")

	RemoteEvents.GameStart.OnClientEvent:Connect(function()
		print("[EVENTS] <<< GameStart received from server >>>") 
		print("[EVENTS] gameState before reset:", "isPlaying=", gameState.isPlaying, "wave=", gameState.currentWave)
		ResetForNewGame()
	end)

	RemoteEvents.GameOver.OnClientEvent:Connect(function(reason, finalScore, defeatedWords)
		print("[EVENTS] <<< GameOver received from server >>> reason=", reason, "score=", finalScore, "defeatedWords=", #(defeatedWords or {}))
		ShowGameOver(reason, finalScore, defeatedWords)
	end)

	RemoteEvents.WaveComplete.OnClientEvent:Connect(function(waveNumber, score)
		print("[EVENTS] <<< WaveComplete received >>> waveNumber=", waveNumber, "score=", score)
		UpdateWave(waveNumber)
		UpdateScore(score)
	end)

	print("[EVENTS] All listeners connected")
end

-- Update loop
RunService.Heartbeat:Connect(function(deltaTime)
	-- Always enforce camera lock when not playing (game over)
	if not gameState.isPlaying and gameState.hasStarted then
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.new(Vector3.new(0, 5, 20), Vector3.new(0, 5, 0))
		return
	end

	if not gameState.isPlaying then return end
	
	-- Keep camera at fixed game position while playing
	local camera = workspace.CurrentCamera
	if camera.CameraType == Enum.CameraType.Scriptable then
		camera.CFrame = CFrame.new(Vector3.new(0, 5, 20), Vector3.new(0, 5, 0))
	end
end)

-- Initialize the game
InitializeGame()

return {}
