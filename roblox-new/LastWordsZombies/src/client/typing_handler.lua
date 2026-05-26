-- Typing input handler and auto-targeting system
-- Captures keyboard input and manages word completion

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

local TypingHandler = {}

-- State
TypingHandler.CurrentTarget = nil
TypingHandler.TypedLetters = ""
TypingHandler.IsEnabled = false  -- starts disabled; enabled by SetEnabled(true) when game begins
TypingHandler.LastInputTime = 0
TypingHandler.ActiveWordHints = {}  -- live list of active zombie words, used for re-targeting logic

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

	-- Bind all letter keys via ContextActionService at high priority.
	-- CAS fires BEFORE Studio hotkeys (like O=Output, I=Explorer) so we always get the event.
	local letterKeyCodes = {
		Enum.KeyCode.A, Enum.KeyCode.B, Enum.KeyCode.C, Enum.KeyCode.D,
		Enum.KeyCode.E, Enum.KeyCode.F, Enum.KeyCode.G, Enum.KeyCode.H,
		Enum.KeyCode.I, Enum.KeyCode.J, Enum.KeyCode.K, Enum.KeyCode.L,
		Enum.KeyCode.M, Enum.KeyCode.N, Enum.KeyCode.O, Enum.KeyCode.P,
		Enum.KeyCode.Q, Enum.KeyCode.R, Enum.KeyCode.S, Enum.KeyCode.T,
		Enum.KeyCode.U, Enum.KeyCode.V, Enum.KeyCode.W, Enum.KeyCode.X,
		Enum.KeyCode.Y, Enum.KeyCode.Z,
	}
	ContextActionService:BindActionAtPriority(
		"TypingInput",
		function(actionName, inputState, inputObj)
			if inputState == Enum.UserInputState.Begin then
				TypingHandler.OnInputBegan(inputObj, false)
			end
			return Enum.ContextActionResult.Sink  -- consume the input so Studio shortcuts (O=Output, I=Explorer, etc.) don't fire
		end,
		false,  -- createTouchButton
		3000,   -- priority: above default (2000) and above Studio shortcuts
		table.unpack(letterKeyCodes)
	)
	print("[TYPING] Input events connected via ContextActionService (O key fix)")

	-- Listen for target response from server
	ZombieTargetResponseEvent.OnClientEvent:Connect(function(zombieModel, word)
		if zombieModel and word then
			print("[TYPING] <<< ZombieTargetResponse received: word='" .. word .. "' model=", zombieModel.Name)
			print("[TYPING]   PendingFirstLetter was='" .. tostring(TypingHandler.PendingFirstLetter) .. "'")
			TypingHandler.CurrentTarget = { Model = zombieModel, Word = word }
			TypingHandler.TypedLetters = ""
			-- Hide hints while actively targeting - reduce visual noise
			if TypingHandler.WordHintsFrame then
				TypingHandler.WordHintsFrame.Visible = false
			end

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

	-- Invisible TextBox used as a keyboard capture sink.
	-- When a TextBox has focus in Roblox Studio, Studio's own keyboard shortcuts
	-- (O=Output, I=Explorer, P=etc.) are suppressed, so every key reaches our handler.
	local captureBox = Instance.new("TextBox")
	captureBox.Name = "KeyCapture"
	captureBox.Size = UDim2.new(0, 1, 0, 1)
	captureBox.Position = UDim2.new(0, 0, 0, 0)
	captureBox.BackgroundTransparency = 1
	captureBox.TextTransparency = 1
	captureBox.Text = ""
	captureBox.ClearTextOnFocus = false
	captureBox.MultiLine = false
	captureBox.Parent = screenGui
	TypingHandler.CaptureBox = captureBox

	-- Whenever text is typed into the capture box, forward each new character
	-- to our input handler, then clear the box.
	captureBox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = captureBox.Text
		if #text == 0 then return end
		captureBox.Text = ""  -- clear immediately
		for i = 1, #text do
			local ch = text:sub(i, i):lower()
			if ch:match("^%a$") and TypingHandler.IsEnabled then
				TypingHandler.LastInputTime = tick()
				print("[INPUT-TB] TextBox captured: '" .. ch .. "' | hasTarget=" .. tostring(TypingHandler.CurrentTarget ~= nil) .. " | typed='" .. TypingHandler.TypedLetters .. "'")
				if not TypingHandler.CurrentTarget and not TypingHandler.PendingFirstLetter then
					TypingHandler.FindTarget(ch)
				elseif not TypingHandler.PendingFirstLetter then
					TypingHandler.ProcessInput(ch)
				end
			end
		end
	end)

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

	-- Word hints panel: shows all active zombie words so player knows what letters are available
	local hintsFrame = Instance.new("Frame")
	hintsFrame.Name = "WordHintsFrame"
	hintsFrame.Size = UDim2.new(0, 220, 0, 300)
	hintsFrame.Position = UDim2.new(0, 16, 0.5, -150)
	hintsFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	hintsFrame.BackgroundTransparency = 0.45
	hintsFrame.BorderSizePixel = 1
	hintsFrame.BorderColor3 = Color3.new(0.3, 0.3, 0.4)
	hintsFrame.Visible = false
	hintsFrame.Parent = screenGui

	local hintsTitle = Instance.new("TextLabel")
	hintsTitle.Name = "HintsTitle"
	hintsTitle.Size = UDim2.new(1, 0, 0, 24)
	hintsTitle.Position = UDim2.new(0, 0, 0, 0)
	hintsTitle.BackgroundTransparency = 1
	hintsTitle.Text = "INCOMING WORDS"
	hintsTitle.TextColor3 = Color3.new(0.7, 0.7, 0.8)
	hintsTitle.TextScaled = true
	hintsTitle.Font = Enum.Font.SourceSansBold
	hintsTitle.Parent = hintsFrame

	local hintsList = Instance.new("Frame")
	hintsList.Name = "HintsList"
	hintsList.Size = UDim2.new(1, -8, 1, -30)
	hintsList.Position = UDim2.new(0, 4, 0, 28)
	hintsList.BackgroundTransparency = 1
	hintsList.Parent = hintsFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 3)
	listLayout.Parent = hintsList

	TypingHandler.WordHintsFrame = hintsFrame
	TypingHandler.HintsList = hintsList
end

-- Update the word hints panel with current active words
function TypingHandler.UpdateWordHints(words)
	-- Store for use by ProcessInput re-targeting logic
	TypingHandler.ActiveWordHints = words
	local frame = TypingHandler.WordHintsFrame
	local list = TypingHandler.HintsList
	if not frame or not list then return end

	-- Clear old hints
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	if #words == 0 then
		frame.Visible = false
		return
	end

	frame.Visible = true
	for i, word in ipairs(words) do
		local row = Instance.new("Frame")
		row.Name = "HintRow" .. i
		row.Size = UDim2.new(1, 0, 0, 22)
		row.BackgroundTransparency = 1
		row.LayoutOrder = i
		row.Parent = list

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -8, 1, 0)
		label.Position = UDim2.new(0, 8, 0, 0)
		label.BackgroundTransparency = 1
		-- Highlight first letter in bright yellow, rest in white
		local firstLetter = word:sub(1,1):upper()
		local rest = word:sub(2):upper()
		label.RichText = true
		label.Text = '<font color="#FFE040"><b>' .. firstLetter .. '</b></font>' .. rest
		label.TextColor3 = Color3.new(0.9, 0.9, 0.9)
		label.TextScaled = true
		label.Font = Enum.Font.SourceSansBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row
	end
	print("[HINTS] Updated word hints panel:", #words, "words")
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
	print("[INPUT] Key pressed: '" .. character .. "' | hasTarget=" .. tostring(TypingHandler.CurrentTarget ~= nil) .. " | pendingLetter='" .. tostring(TypingHandler.PendingFirstLetter) .. "' | typed='" .. TypingHandler.TypedLetters .. "' | gameProcessed=" .. tostring(gameProcessed))

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
			-- Check if this key matches a DIFFERENT zombie's first letter (from hints list)
			-- If so, abandon current target and switch - lets player pivot mid-word
			local matchesOtherZombie = false
			if TypingHandler.ActiveWordHints then
				for _, hintWord in ipairs(TypingHandler.ActiveWordHints) do
					if hintWord ~= targetWord and hintWord:sub(1,1):lower() == character then
						matchesOtherZombie = true
						break
					end
				end
			end
			if matchesOtherZombie and not TypingHandler.PendingFirstLetter and #currentTyped <= 1 then
				print("[PROCESS] Key '" .. character .. "' matches a different zombie - abandoning '" .. targetWord .. "' (only " .. #currentTyped .. " letters in) and retargeting")
				TypingHandler.CurrentTarget = nil
				TypingHandler.TypedLetters = ""
				TypingHandler.FindTarget(character)
			elseif #currentTyped == 0 and not TypingHandler.PendingFirstLetter then
				print("[PROCESS] Retargeting with char='" .. character .. "' (nothing typed yet on current target)")
				TypingHandler.CurrentTarget = nil
				TypingHandler.FindTarget(character)
			else
				print("[PROCESS] Wrong key ignored - no other zombie starts with '" .. character .. "', staying on '" .. targetWord .. "'")
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

	-- Show hints panel again now that we're untargeted
	if TypingHandler.WordHintsFrame then
		TypingHandler.WordHintsFrame.Visible = TypingHandler.HintsList and #TypingHandler.HintsList:GetChildren() > 1
	end

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
	-- Idle timeout: only abandon target if zombie is still far away (Z < -40).
	-- Never auto-drop a close zombie - player must kill it or it triggers game over.
	if TypingHandler.CurrentTarget and tick() - TypingHandler.LastInputTime > 8.0 then
		local model = TypingHandler.CurrentTarget.Model
		local zombieZ = model and model.PrimaryPart and model.PrimaryPart.Position.Z or -999
		if zombieZ < -40 then
			print("[TIMEOUT] Idle 8s and zombie is far (Z=" .. string.format("%.1f", zombieZ) .. ") - resetting target")
			TypingHandler.ResetTyping()
		else
			print("[TIMEOUT] Idle 8s but zombie is CLOSE (Z=" .. string.format("%.1f", zombieZ) .. ") - NOT resetting, player must type it")
			TypingHandler.LastInputTime = tick()  -- reset timer so this log doesn't spam every frame
		end
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
		-- Unbind CAS so Studio shortcuts (O, I, P, etc.) work again in menus/game over
		ContextActionService:UnbindAction("TypingInput")
		print("[TYPING] CAS TypingInput unbound (game not active)")
		-- Release TextBox focus
		if TypingHandler.CaptureBox then
			game:GetService("UserInputService"):GetFocusedTextBox() -- just a read, focus released naturally
		end
	else
		-- Re-bind CAS when game is active - must sink O before Studio eats it
		local letterKeyCodes = {
			Enum.KeyCode.A, Enum.KeyCode.B, Enum.KeyCode.C, Enum.KeyCode.D,
			Enum.KeyCode.E, Enum.KeyCode.F, Enum.KeyCode.G, Enum.KeyCode.H,
			Enum.KeyCode.I, Enum.KeyCode.J, Enum.KeyCode.K, Enum.KeyCode.L,
			Enum.KeyCode.M, Enum.KeyCode.N, Enum.KeyCode.O, Enum.KeyCode.P,
			Enum.KeyCode.Q, Enum.KeyCode.R, Enum.KeyCode.S, Enum.KeyCode.T,
			Enum.KeyCode.U, Enum.KeyCode.V, Enum.KeyCode.W, Enum.KeyCode.X,
			Enum.KeyCode.Y, Enum.KeyCode.Z,
		}
		ContextActionService:BindActionAtPriority(
			"TypingInput",
			function(actionName, inputState, inputObj)
				if inputState == Enum.UserInputState.Begin then
					TypingHandler.OnInputBegan(inputObj, false)
				end
				return Enum.ContextActionResult.Sink
			end,
			false, 3000, table.unpack(letterKeyCodes)
		)
		print("[TYPING] CAS TypingInput rebound (game active)")
		-- Focus the invisible TextBox - this suppresses Studio's keyboard shortcuts
		if TypingHandler.CaptureBox then
			TypingHandler.CaptureBox:CaptureFocus()
			print("[TYPING] CaptureBox focused")
			-- Re-focus if it ever loses focus (e.g. player clicks elsewhere) while game is active
			TypingHandler.CaptureBox.FocusLost:Connect(function()
				if TypingHandler.IsEnabled then
					task.defer(function()
						if TypingHandler.IsEnabled and TypingHandler.CaptureBox then
							TypingHandler.CaptureBox:CaptureFocus()
						end
					end)
				end
			end)
		end
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
