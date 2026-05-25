-- Typing input handler and auto-targeting system
-- Captures keyboard input and manages word completion

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

local TypingHandler = {}

-- State
TypingHandler.CurrentTarget = nil
TypingHandler.TypedLetters = ""
TypingHandler.IsEnabled = false  -- starts disabled; enabled by SetEnabled(true) when game begins
TypingHandler.LastInputTime = 0

-- Remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ZombieTargetedEvent = RemoteEvents:WaitForChild("ZombieTargeted")
local ZombieTargetResponseEvent = RemoteEvents:WaitForChild("ZombieTargetResponse")
local WordProgressEvent = RemoteEvents:WaitForChild("WordProgress")
local WordCompleteEvent = RemoteEvents:WaitForChild("WordComplete")

-- Visual feedback
TypingHandler.TargetHighlight = nil
TypingHandler.TypedTextDisplay = nil

-- Initialize typing handler
function TypingHandler.Initialize()
	print("[TYPING] TypingHandler.Initialize() called")
	-- Create UI elements
	TypingHandler.CreateTypingUI()
	print("[TYPING] TypingUI created")

	-- Connect input events
	UserInputService.InputBegan:Connect(TypingHandler.OnInputBegan)
	UserInputService.InputChanged:Connect(TypingHandler.OnInputChanged)
	UserInputService.InputEnded:Connect(TypingHandler.OnInputEnded)
	print("[TYPING] Input events connected")

	-- Listen for target response from server
	ZombieTargetResponseEvent.OnClientEvent:Connect(function(zombieModel, word)
		if zombieModel and word then
			print("[TYPING] <<< ZombieTargetResponse received: word='" .. word .. "' model=", zombieModel.Name)
			print("[TYPING]   PendingFirstLetter was='" .. tostring(TypingHandler.PendingFirstLetter) .. "'")
			TypingHandler.CurrentTarget = { Model = zombieModel, Word = word }
			TypingHandler.TypedLetters = ""

			-- Reset billboard to plain text before any RichText updates
			local head = zombieModel:FindFirstChild("Head") or zombieModel.PrimaryPart
			local billboard = head and head:FindFirstChild("WordDisplay")
			if billboard then
				local label = billboard:FindFirstChild("Frame") and billboard.Frame:FindFirstChild("TextLabel")
				if label then
					label.RichText = false
					label.Text = word:upper()
					print("[TYPING]   Billboard reset to plain '" .. word:upper() .. "'")
				else
					print("[TYPING]   WARNING: Could not find billboard TextLabel for word='" .. word .. "'")
				end
			else
				print("[TYPING]   WARNING: No WordDisplay billboard found on zombie head for word='" .. word .. "'")
			end

			-- Process the buffered first letter that triggered the search
			if TypingHandler.PendingFirstLetter then
				print("[TYPING]   Processing buffered PendingFirstLetter='" .. TypingHandler.PendingFirstLetter .. "'")
				TypingHandler.ProcessInput(TypingHandler.PendingFirstLetter)
				TypingHandler.PendingFirstLetter = nil
			end
			TypingHandler.UpdateTargetHighlight()
			TypingHandler.UpdateTypedDisplay()
		else
			print("[TYPING] <<< ZombieTargetResponse received: NIL - no zombie matched prefix='" .. tostring(TypingHandler.PendingFirstLetter) .. "'")
			TypingHandler.PendingFirstLetter = nil
		end
	end)
	
	-- Start update loop
	RunService.Heartbeat:Connect(TypingHandler.Update)
end

-- Create typing UI elements
function TypingHandler.CreateTypingUI()
	-- Create screen GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TypingUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	
	-- Current typed text display
	local typedFrame = Instance.new("Frame")
	typedFrame.Name = "TypedTextFrame"
	typedFrame.Size = UDim2.new(0, 400, 0, 60)
	typedFrame.Position = UDim2.new(0.5, -200, 0.9, -30)
	typedFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	typedFrame.BackgroundTransparency = 0.3
	typedFrame.BorderSizePixel = 2
	typedFrame.BorderColor3 = Color3.new(0, 1, 0.5)
	typedFrame.Parent = screenGui
	
	local typedLabel = Instance.new("TextLabel")
	typedLabel.Name = "TypedLabel"
	typedLabel.Size = UDim2.new(1, -20, 1, -20)
	typedLabel.Position = UDim2.new(0, 10, 0, 10)
	typedLabel.BackgroundTransparency = 1
	typedLabel.Text = ""
	typedLabel.TextColor3 = Color3.new(0, 1, 0.5)
	typedLabel.TextScaled = true
	typedLabel.Font = Enum.Font.SourceSansBold
	typedLabel.TextXAlignment = Enum.TextXAlignment.Center
	typedLabel.TextYAlignment = Enum.TextYAlignment.Center
	typedLabel.Parent = typedFrame
	
	TypingHandler.TypedTextDisplay = typedLabel
	
	-- Target indicator
	local targetIndicator = Instance.new("Frame")
	targetIndicator.Name = "TargetIndicator"
	targetIndicator.Size = UDim2.new(0, 100, 0, 4)
	targetIndicator.Position = UDim2.new(0.5, -50, 0.85, 0)
	targetIndicator.BackgroundColor3 = Color3.new(1, 1, 0)
	targetIndicator.BorderSizePixel = 0
	targetIndicator.Visible = false
	targetIndicator.Parent = screenGui
	
	TypingHandler.TargetHighlight = targetIndicator
end

-- Handle input began
function TypingHandler.OnInputBegan(input, gameProcessed)
	if not TypingHandler.IsEnabled then return end
	-- Do NOT check gameProcessed - movement keys (WASD) are consumed by Roblox
	-- but we still need letters like W, A, S, D to work in typing

	local inputType = input.UserInputType
	local key = input.KeyCode

	-- Only handle keyboard input
	if inputType ~= Enum.UserInputType.Keyboard then return end
	
	-- Ignore modifier keys
	if key == Enum.KeyCode.LeftShift or key == Enum.KeyCode.RightShift or
	   key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.RightControl or
	   key == Enum.KeyCode.LeftAlt or key == Enum.KeyCode.RightAlt then
		return
	end
	
	-- Ignore non-typing system keys
	if key == Enum.KeyCode.Escape or key == Enum.KeyCode.Tab or
	   key == Enum.KeyCode.Return or key == Enum.KeyCode.Backspace or
	   key == Enum.KeyCode.Space then
		return
	end
	
	-- Get character
	local character = TypingHandler.GetKeyCharacter(key)
	if not character then return end

	TypingHandler.LastInputTime = tick()
	print("[INPUT] Key pressed: '" .. character .. "' | hasTarget=" .. tostring(TypingHandler.CurrentTarget ~= nil) .. " | pendingLetter='" .. tostring(TypingHandler.PendingFirstLetter) .. "' | typed='" .. TypingHandler.TypedLetters .. "'")

	-- If no current target, try to find one by first letter
	if not TypingHandler.CurrentTarget and not TypingHandler.PendingFirstLetter then
		print("[INPUT] No target - firing FindTarget with prefix='" .. character .. "'")
		TypingHandler.FindTarget(character)
		return -- wait for server response before processing
	end

	if TypingHandler.PendingFirstLetter and not TypingHandler.CurrentTarget then
		print("[INPUT] Still waiting for server ZombieTargetResponse (pending='" .. tostring(TypingHandler.PendingFirstLetter) .. "') - key '" .. character .. "' buffered/ignored")
		return
	end

	-- If we have a target, process the input
	if TypingHandler.CurrentTarget then
		TypingHandler.ProcessInput(character)
	end
end

-- Get character from key code
function TypingHandler.GetKeyCharacter(keyCode)
	local keyMap = {
		[Enum.KeyCode.A] = "a", [Enum.KeyCode.B] = "b", [Enum.KeyCode.C] = "c",
		[Enum.KeyCode.D] = "d", [Enum.KeyCode.E] = "e", [Enum.KeyCode.F] = "f",
		[Enum.KeyCode.G] = "g", [Enum.KeyCode.H] = "h", [Enum.KeyCode.I] = "i",
		[Enum.KeyCode.J] = "j", [Enum.KeyCode.K] = "k", [Enum.KeyCode.L] = "l",
		[Enum.KeyCode.M] = "m", [Enum.KeyCode.N] = "n", [Enum.KeyCode.O] = "o",
		[Enum.KeyCode.P] = "p", [Enum.KeyCode.Q] = "q", [Enum.KeyCode.R] = "r",
		[Enum.KeyCode.S] = "s", [Enum.KeyCode.T] = "t", [Enum.KeyCode.U] = "u",
		[Enum.KeyCode.V] = "v", [Enum.KeyCode.W] = "w", [Enum.KeyCode.X] = "x",
		[Enum.KeyCode.Y] = "y", [Enum.KeyCode.Z] = "z",
		[Enum.KeyCode.One] = "1", [Enum.KeyCode.Two] = "2", [Enum.KeyCode.Three] = "3",
		[Enum.KeyCode.Four] = "4", [Enum.KeyCode.Five] = "5", [Enum.KeyCode.Six] = "6",
		[Enum.KeyCode.Seven] = "7", [Enum.KeyCode.Eight] = "8", [Enum.KeyCode.Nine] = "9",
		[Enum.KeyCode.Zero] = "0"
	}
	
	return keyMap[keyCode]
end

-- Find/retarget zombie by full typed prefix
function TypingHandler.FindTarget(prefix)
	TypingHandler.PendingFirstLetter = prefix
	ZombieTargetedEvent:FireServer(prefix)
end

-- Set target zombie (called by server)
function TypingHandler.SetTarget(zombieData)
	TypingHandler.CurrentTarget = zombieData
	TypingHandler.TypedLetters = ""
	
	-- Update visual feedback
	TypingHandler.UpdateTargetHighlight()
	TypingHandler.UpdateTypedDisplay()
end

-- Process keyboard input
function TypingHandler.ProcessInput(character)
	if not TypingHandler.CurrentTarget then
		print("[PROCESS] ProcessInput called but CurrentTarget is nil - ignoring '" .. character .. "'")
		return
	end

	local targetWord = TypingHandler.CurrentTarget.Word
	local currentTyped = TypingHandler.TypedLetters

	-- Check if character matches next expected character
	local nextCharIndex = #currentTyped + 1
	if nextCharIndex <= #targetWord then
		local expectedChar = targetWord:sub(nextCharIndex, nextCharIndex):lower()
		print("[PROCESS] Checking '" .. character .. "' against expected '" .. expectedChar .. "' (pos " .. nextCharIndex .. "/" .. #targetWord .. " of '" .. targetWord .. "')")

		if character == expectedChar then
			TypingHandler.TypedLetters = currentTyped .. character
			print("[PROCESS] CORRECT! typed now='" .. TypingHandler.TypedLetters .. "' (" .. #TypingHandler.TypedLetters .. "/" .. #targetWord .. ")")

			TypingHandler.PlayTypingSound()

			-- Check if word is complete
			if #TypingHandler.TypedLetters == #targetWord then
				print("[PROCESS] WORD COMPLETE: '" .. targetWord .. "'")
				TypingHandler.CompleteWord()
			else
				TypingHandler.UpdateProgress()
			end
		else
			print("[PROCESS] WRONG KEY: '" .. character .. "' expected '" .. expectedChar .. "' on word '" .. targetWord .. "' typed so far='" .. currentTyped .. "'")
			-- Wrong character typed - if typed prefix so far still valid, keep target
			-- If nothing typed yet, try retargeting with first char in case another zombie matches
			if #currentTyped == 0 and not TypingHandler.PendingFirstLetter then
				print("[PROCESS] Retargeting with char='" .. character .. "' (nothing typed yet on current target)")
				TypingHandler.CurrentTarget = nil
				TypingHandler.FindTarget(character)
			end
		end
	end
end

-- Complete word
function TypingHandler.CompleteWord()
	if not TypingHandler.CurrentTarget then
		print("[COMPLETE] CompleteWord called but CurrentTarget is nil!")
		return
	end
	print("[COMPLETE] ====== WORD COMPLETE: '" .. TypingHandler.CurrentTarget.Word .. "' ======")

	-- Flash the word display fully green before destroying
	local model = TypingHandler.CurrentTarget.Model
	local wordDisplay = model and model:FindFirstChild("Head") and model.Head:FindFirstChild("WordDisplay")
					  or model and model.PrimaryPart and model.PrimaryPart:FindFirstChild("WordDisplay")
	if wordDisplay then
		local frame = wordDisplay:FindFirstChild("Frame")
		local label = frame and frame:FindFirstChild("TextLabel")
		if label then
			local word = TypingHandler.CurrentTarget.Word
			local green = '<font color="rgb(0,255,128)">'
			local full = ""
			for i = 1, #word do
				full = full .. green .. word:sub(i,i) .. "</font>"
			end
			label.RichText = true
			label.Text = full
		end
	end

	-- Small delay so player sees the full-green flash
	task.delay(0.12, function()
		print("[COMPLETE] Firing WordComplete to server for model:", model and model.Name or "nil")
		WordCompleteEvent:FireServer(model)
	end)

	TypingHandler.PlayCompletionSound()
	print("[COMPLETE] ResetTyping called - ready for next target")
	TypingHandler.ResetTyping()
end

-- Update word progress
function TypingHandler.UpdateProgress()
	if not TypingHandler.CurrentTarget then return end
	
	-- Update server with Model reference and typed letters
	WordProgressEvent:FireServer(TypingHandler.CurrentTarget.Model, TypingHandler.TypedLetters)
	
	-- Update local display
	TypingHandler.UpdateTypedDisplay()
end

-- Reset typing state
function TypingHandler.ResetTyping()
	print("[RESET] ResetTyping called | was targeting='" .. (TypingHandler.CurrentTarget and TypingHandler.CurrentTarget.Word or "nil") .. "' typed='" .. TypingHandler.TypedLetters .. "'")
	TypingHandler.CurrentTarget = nil
	TypingHandler.TypedLetters = ""
	TypingHandler.PendingFirstLetter = nil

	TypingHandler.UpdateTargetHighlight()
	TypingHandler.UpdateTypedDisplay()
end

-- Update target highlight
function TypingHandler.UpdateTargetHighlight()
	if TypingHandler.TargetHighlight then
		TypingHandler.TargetHighlight.Visible = (TypingHandler.CurrentTarget ~= nil)
	end
end

-- Update typed text display
function TypingHandler.UpdateTypedDisplay()
	if TypingHandler.TypedTextDisplay then
		if TypingHandler.CurrentTarget then
			TypingHandler.TypedTextDisplay.Text = TypingHandler.TypedLetters:upper()
		else
			TypingHandler.TypedTextDisplay.Text = ""
		end
	end
end

-- Play typing sound effect
function TypingHandler.PlayTypingSound()
	-- No built-in rbxasset typing sound available without HTTP assets
end

-- Play word completion sound
function TypingHandler.PlayCompletionSound()
	-- No built-in rbxasset completion sound available without HTTP assets
end

-- Handle input changed (for repeat keys)
function TypingHandler.OnInputChanged(input, gameProcessed)
	-- Handle key repeat if needed
end

-- Handle input ended
function TypingHandler.OnInputEnded(input, gameProcessed)
	-- Could be used for special key combinations
end

-- Update loop (for visual effects and timeouts)
function TypingHandler.Update(deltaTime)
	-- Reset only after 8 seconds of no input (gives time for network + slow typists)
	if TypingHandler.CurrentTarget and tick() - TypingHandler.LastInputTime > 8.0 then
		TypingHandler.ResetTyping()
	end
	
	-- Update target highlight position if we have a target
	if TypingHandler.CurrentTarget and TypingHandler.TargetHighlight then
		local zombieModel = TypingHandler.CurrentTarget.Model
		if zombieModel and zombieModel.PrimaryPart then
			local worldPos = zombieModel.PrimaryPart.Position
			local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(worldPos)
			
			if onScreen then
				TypingHandler.TargetHighlight.Position = UDim2.new(0, screenPos.X - 50, 0, screenPos.Y - 50)
			end
		end
	end
end

-- Enable/disable typing handler
function TypingHandler.SetEnabled(enabled)
	print("[TYPING] SetEnabled(" .. tostring(enabled) .. ") called | was:", TypingHandler.IsEnabled)
	TypingHandler.IsEnabled = enabled

	if not enabled then
		TypingHandler.ResetTyping()
	end
end

-- Get current typing state
function TypingHandler.GetState()
	return {
		hasTarget = TypingHandler.CurrentTarget ~= nil,
		typedLetters = TypingHandler.TypedLetters,
		isEnabled = TypingHandler.IsEnabled
	}
end

return TypingHandler
