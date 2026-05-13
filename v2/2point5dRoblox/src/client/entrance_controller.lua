-- entrance_controller.lua  (CLIENT - NEW)
-- Plays a cinematic drop sequence based on the selected race.

local TweenService    = game:GetService("TweenService")
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local SpaceEnv        = require(script.Parent:WaitForChild("space_environment"))

local EntranceController = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ── Screen fade helpers ────────────────────────────────────────────────────

local function makeFade(color, alpha)
	local gui = Instance.new("ScreenGui")
	gui.Name = "_EntranceFade"; gui.IgnoreGuiInset = true; gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	gui.Parent = player.PlayerGui
	local f = Instance.new("Frame", gui)
	f.Size = UDim2.new(1,0,1,0); f.BackgroundColor3 = color
	f.BackgroundTransparency = alpha; f.BorderSizePixel = 0; f.ZIndex = 100
	return gui, f
end

local function fadeIn(t)  -- fade TO black
	local gui, f = makeFade(Color3.new(0,0,0), 1)
	f.BackgroundTransparency = 1
	local tw = TweenService:Create(f, TweenInfo.new(t, Enum.EasingStyle.Sine), {BackgroundTransparency = 0})
	tw:Play(); tw.Completed:Wait()
	return gui
end

local function fadeOut(gui, t) -- fade FROM black
	local f = gui:FindFirstChildWhichIsA("Frame")
	if not f then gui:Destroy(); return end
	local tw = TweenService:Create(f, TweenInfo.new(t, Enum.EasingStyle.Sine), {BackgroundTransparency = 1})
	tw:Play(); tw.Completed:Wait()
	gui:Destroy()
end

-- ── Ground Detection ───────────────────────────────────────────────────────
local function getGroundPosition(x, z)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	if player.Character then
		local instances = {player.Character}
		local lobby = workspace:FindFirstChild("Lobby")
		if lobby then table.insert(instances, lobby) end
		raycastParams.FilterDescendantsInstances = instances
	end
	
	-- Raycast from high up to find the actual world surface
	local result = workspace:Raycast(Vector3.new(x, 4000, z), Vector3.new(0, -6000, 0), raycastParams)
	if result then
		return result.Position
	end
	return Vector3.new(x, 0, z)
end

-- ── Cinematic Builders ─────────────────────────────────────────────────────

local function buildHumanPod(pos)
	local model = Instance.new("Model"); model.Name = "_DropPod"
	model.Parent = workspace

	local function p(props)
		local part = Instance.new("Part")
		part.Anchored = true; part.CanCollide = false; part.CastShadow = true
		for k,v in pairs(props) do part[k]=v end
		part.Parent = model
		return part
	end

	local body = p({Name="Body", Shape=Enum.PartType.Block, Size=Vector3.new(4,8,4), Color=Color3.fromRGB(60,65,80), Material=Enum.Material.Metal, CFrame=CFrame.new(pos)})
	p({Name="Nose", Shape=Enum.PartType.Ball, Size=Vector3.new(4,4,4), Color=Color3.fromRGB(80,85,100), Material=Enum.Material.Metal, CFrame=CFrame.new(pos + Vector3.new(0,5,0))})
	
	local shield = p({Name="Shield", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.8,6,6), Color=Color3.fromRGB(220,80,20), Material=Enum.Material.Neon, CFrame=CFrame.new(pos + Vector3.new(0,-4.3,0))*CFrame.Angles(0,0,math.rad(90))})
	local sl = Instance.new("PointLight",shield)
	sl.Color=Color3.fromRGB(255,120,0); sl.Brightness=4; sl.Range=60

	local eng = p({Name="Engine", Shape=Enum.PartType.Cylinder, Size=Vector3.new(2,3,3), Color=Color3.fromRGB(255,220,100), Material=Enum.Material.Neon, CFrame=CFrame.new(pos + Vector3.new(0,-5,0))*CFrame.Angles(0,0,math.rad(90))})
	local el = Instance.new("PointLight",eng)
	el.Color=Color3.fromRGB(255,200,50); el.Brightness=5; el.Range=50

	local fire = Instance.new("Fire", eng)
	fire.Color = Color3.fromRGB(255,100,0); fire.SecondaryColor = Color3.fromRGB(255,220,0); fire.Heat = 20; fire.Size = 8

	model.PrimaryPart = body
	return model, shield, fire
end

local function buildDwarfParachute(character)
	local canopy = Instance.new("Part")
	canopy.Name = "_ParachuteCanopy"
	canopy.Size = Vector3.new(20, 2, 20)
	canopy.Shape = Enum.PartType.Ball
	canopy.Color = Color3.fromRGB(0, 150, 255)
	canopy.Material = Enum.Material.Neon
	canopy.Transparency = 0.6
	canopy.CanCollide = false
	canopy.Anchored = true
	canopy.Parent = workspace
	
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxassetid://244221446"
	particles.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
	particles.Size = NumberSequence.new(2, 0)
	particles.Rate = 100
	particles.Speed = NumberRange.new(5, 10)
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Parent = canopy

	return canopy
end

local function buildOrcBird(pos)
	local model = Instance.new("Model"); model.Name = "_GiantBird"
	model.Parent = workspace

	local function p(props)
		local part = Instance.new("Part")
		part.Anchored = true; part.CanCollide = false; part.CastShadow = true
		for k,v in pairs(props) do part[k]=v end
		part.Parent = model
		return part
	end

	local body = p({Name="Body", Shape=Enum.PartType.Block, Size=Vector3.new(6,4,12), Color=Color3.fromRGB(40,30,20), Material=Enum.Material.Slate, CFrame=CFrame.new(pos)})
	p({Name="Head", Shape=Enum.PartType.Ball, Size=Vector3.new(4,4,4), Color=Color3.fromRGB(40,30,20), Material=Enum.Material.Slate, CFrame=CFrame.new(pos + Vector3.new(0,1,-6))})
	p({Name="Beak", Shape=Enum.PartType.Wedge, Size=Vector3.new(1,2,4), Color=Color3.fromRGB(200,150,50), Material=Enum.Material.SmoothPlastic, CFrame=CFrame.new(pos + Vector3.new(0,1,-8))*CFrame.Angles(0,math.rad(180),0)})
	
	local lWing = p({Name="LWing", Shape=Enum.PartType.Block, Size=Vector3.new(15,0.5,6), Color=Color3.fromRGB(30,20,10), Material=Enum.Material.Slate, CFrame=CFrame.new(pos + Vector3.new(-10,1,0))})
	local rWing = p({Name="RWing", Shape=Enum.PartType.Block, Size=Vector3.new(15,0.5,6), Color=Color3.fromRGB(30,20,10), Material=Enum.Material.Slate, CFrame=CFrame.new(pos + Vector3.new(10,1,0))})
	
	model.PrimaryPart = body
	return model, lWing, rWing
end

-- ── Entrance Controller Core ───────────────────────────────────────────────

function EntranceController.launch(race, serverLandingPos, onLanded)
	task.spawn(function()
		local blackGui = fadeIn(0.2) -- Faster fade for seamless feel
		local prevType = camera.CameraType
		camera.CameraType = Enum.CameraType.Scriptable
		
		SpaceEnv.applyFullBright()
		
		-- Resolve exact ground position
		local exactGroundPos = getGroundPosition(serverLandingPos.X, serverLandingPos.Z)
		local startPos = exactGroundPos + Vector3.new(0, 800, 0)
		
		local character = player.Character
		if character and character.PrimaryPart then
			character.PrimaryPart.Anchored = true
			character:PivotTo(CFrame.new(startPos))
		end

		local descentTime = 4.0
		local elapsed = 0
		
		-- Setup based on race
		local visualObj, visualObj2, visualObj3 = nil, nil, nil
		if race == "Human" then
			visualObj, visualObj2, visualObj3 = buildHumanPod(startPos)
			if character then character.Parent = nil end -- hide character
		elseif race == "Dwarf" then
			descentTime = 5.0
			visualObj = buildDwarfParachute()
		elseif race == "Elf" then
			descentTime = 4.5
			-- Add glowing aura
			visualObj = Instance.new("ParticleEmitter")
			visualObj.Color = ColorSequence.new(Color3.fromRGB(150, 255, 150))
			visualObj.Size = NumberSequence.new(3, 0)
			visualObj.Rate = 200
			visualObj.Speed = NumberRange.new(5, 15)
			visualObj.Lifetime = NumberRange.new(1, 2)
			if character and character.PrimaryPart then
				visualObj.Parent = character.PrimaryPart
			end
		elseif race == "Orc" then
			descentTime = 4.0
			visualObj, visualObj2, visualObj3 = buildOrcBird(startPos + Vector3.new(0, 8, 0))
		end

		fadeOut(blackGui, 0.3) -- Fast fade out

		local startCF = CFrame.new(startPos)
		
		while elapsed < descentTime do
			local dt = RunService.RenderStepped:Wait()
			elapsed = elapsed + dt
			local t = math.min(elapsed / descentTime, 1)
			
			local currentPos
			local eased = t
			
			if race == "Human" then
				-- Fast drop, rocket slow down at the end
				eased = t * t * (3 - 2 * t)
				if t > 0.8 then
					visualObj3.Size = 15 -- Fire intensifies
					visualObj2.Color = Color3.fromRGB(255, 150, 50)
				end
				currentPos = startPos:Lerp(exactGroundPos + Vector3.new(0, 4, 0), eased)
				visualObj:SetPrimaryPartCFrame(CFrame.new(currentPos))
				camera.CFrame = CFrame.new(currentPos + Vector3.new(25, 20, 25), currentPos)
				
			elseif race == "Dwarf" then
				-- Steady parachute glide
				eased = t
				currentPos = startPos:Lerp(exactGroundPos + Vector3.new(0, 2, 0), eased)
				if character then
					character:PivotTo(CFrame.new(currentPos))
				end
				visualObj.CFrame = CFrame.new(currentPos + Vector3.new(0, 15, 0))
				camera.CFrame = CFrame.new(currentPos + Vector3.new(20, 30, 20), currentPos)
				
			elseif race == "Elf" then
				-- Magic levitation slow down
				eased = math.sin(t * math.pi * 0.5)
				currentPos = startPos:Lerp(exactGroundPos + Vector3.new(0, 3, 0), eased)
				if character then
					character:PivotTo(CFrame.new(currentPos))
					-- Spin character gently
					character:PivotTo(character:GetPivot() * CFrame.Angles(0, math.rad(t * 360), 0))
				end
				camera.CFrame = CFrame.new(currentPos + Vector3.new(25, 10, 25), currentPos)
				
			elseif race == "Orc" then
				-- Bird swoop
				eased = t * t * (3 - 2 * t)
				currentPos = startPos:Lerp(exactGroundPos + Vector3.new(0, 2, 0), eased)
				
				-- Bird swoops down and then pulls up
				local birdPos = currentPos + Vector3.new(0, 8 + math.sin(t * math.pi)*10, 0)
				visualObj:SetPrimaryPartCFrame(CFrame.new(birdPos) * CFrame.Angles(math.rad(-20 + t*40), 0, 0))
				
				-- Flap wings
				visualObj2.CFrame = CFrame.new(birdPos + Vector3.new(-10, 1 + math.sin(elapsed*10)*3, 0)) * CFrame.Angles(0, 0, math.rad(math.sin(elapsed*10)*20))
				visualObj3.CFrame = CFrame.new(birdPos + Vector3.new(10, 1 + math.sin(elapsed*10)*3, 0)) * CFrame.Angles(0, 0, math.rad(-math.sin(elapsed*10)*20))
				
				if character then
					character:PivotTo(CFrame.new(birdPos + Vector3.new(0, -6, 0)))
				end
				camera.CFrame = CFrame.new(birdPos + Vector3.new(30, 20, 30), birdPos)
			end
		end

		-- End of cinematic impact
		local impactGui, impactFrame = makeFade(Color3.fromRGB(255,255,255), 0)
		impactFrame.BackgroundTransparency = 0.3
		TweenService:Create(impactFrame, TweenInfo.new(0.5), {BackgroundTransparency=1}):Play()
		
		-- Bird flies away
		if race == "Orc" then
			task.spawn(function()
				local bElapsed = 0
				local bStart = visualObj:GetPrimaryPartCFrame().Position
				while bElapsed < 2.0 do
					local dt = RunService.RenderStepped:Wait()
					bElapsed = bElapsed + dt
					local flyUpPos = bStart + Vector3.new(0, bElapsed * 100, bElapsed * 50)
					visualObj:SetPrimaryPartCFrame(CFrame.new(flyUpPos))
				end
				visualObj:Destroy()
			end)
		end

		local shakeTime, shakeElapsed = 0.5, 0
		while shakeElapsed < shakeTime do
			local dt2 = RunService.RenderStepped:Wait()
			shakeElapsed = shakeElapsed + dt2
			local s = (1 - shakeElapsed / shakeTime) * 3
			camera.CFrame = camera.CFrame * CFrame.new(math.random(-50,50)/100*s, math.random(-50,50)/100*s, 0)
		end
		task.wait(0.4)
		impactGui:Destroy()

		local blackGui2 = fadeIn(0.5)

		-- Cleanup
		if race == "Human" then
			visualObj:Destroy()
		elseif race == "Dwarf" then
			visualObj:Destroy()
		elseif race == "Elf" then
			visualObj:Destroy()
		end
		
		if character then
			character.Parent = workspace
			character:PivotTo(CFrame.new(exactGroundPos + Vector3.new(0, 5, 0)))
			if character.PrimaryPart then
				character.PrimaryPart.Anchored = false
			end
		end

		camera.CameraType = prevType

		if onLanded then onLanded() end

		task.wait(0.2)
		fadeOut(blackGui2, 0.7)
	end)
end

return EntranceController
