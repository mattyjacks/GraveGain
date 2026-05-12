-- drop_pod.lua  (CLIENT - NEW)
-- Plays a cinematic drop-pod spawn sequence when entering the dungeon.
-- Usage: DropPod.launch(landingPos, onLanded)
--   landingPos : Vector3 where the pod lands
--   onLanded   : function called after cinematic completes

local TweenService    = game:GetService("TweenService")
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")

local DropPod = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ── Screen fade helpers ────────────────────────────────────────────────────

local function makeFade(color, alpha)
	local gui = Instance.new("ScreenGui")
	gui.Name = "_DropPodFade"; gui.IgnoreGuiInset = true; gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
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

-- ── Build the pod model ────────────────────────────────────────────────────

local function buildPodModel(pos)
	local model = Instance.new("Model"); model.Name = "_DropPod"
	model.Parent = workspace

	local function p(props)
		local part = Instance.new("Part")
		part.Anchored = true; part.CanCollide = false
		part.CastShadow = true
		for k,v in pairs(props) do part[k]=v end
		part.Parent = model
		return part
	end

	-- Main capsule body
	local body = p({
		Name="Body", Shape=Enum.PartType.Block,
		Size=Vector3.new(4,8,4),
		Color=Color3.fromRGB(60,65,80), Material=Enum.Material.Metal,
		CFrame=CFrame.new(pos),
	})
	-- Nose cone
	p({ Name="Nose", Shape=Enum.PartType.Ball,
		Size=Vector3.new(4,4,4),
		Color=Color3.fromRGB(80,85,100), Material=Enum.Material.Metal,
		CFrame=CFrame.new(pos + Vector3.new(0,5,0)),
	})
	-- Heat shield bottom
	local shield = p({ Name="Shield", Shape=Enum.PartType.Cylinder,
		Size=Vector3.new(0.8,6,6),
		Color=Color3.fromRGB(220,80,20), Material=Enum.Material.Neon,
		CFrame=CFrame.new(pos + Vector3.new(0,-4.3,0))*CFrame.Angles(0,0,math.rad(90)),
	})
	local sl = Instance.new("PointLight",shield)
	sl.Color=Color3.fromRGB(255,120,0); sl.Brightness=4; sl.Range=60

	-- Engine nozzle glow
	local eng = p({ Name="Engine", Shape=Enum.PartType.Cylinder,
		Size=Vector3.new(2,3,3),
		Color=Color3.fromRGB(255,220,100), Material=Enum.Material.Neon,
		CFrame=CFrame.new(pos + Vector3.new(0,-5,0))*CFrame.Angles(0,0,math.rad(90)),
	})
	local el = Instance.new("PointLight",eng)
	el.Color=Color3.fromRGB(255,200,50); el.Brightness=5; el.Range=50

	-- Fire particles
	local fire = Instance.new("Fire", eng)
	fire.Color = Color3.fromRGB(255,100,0)
	fire.SecondaryColor = Color3.fromRGB(255,220,0)
	fire.Heat = 20; fire.Size = 8

	model.PrimaryPart = body
	return model, body, shield, eng
end

-- ── Main launch function ────────────────────────────────────────────────────

function DropPod.launch(landingPos, onLanded)
	landingPos = landingPos or Vector3.new(0, 0, 800)

	task.spawn(function()
		-- 1. Fade to black
		local blackGui = fadeIn(0.6)

		-- 2. Lock camera to cinematic mode
		local prevType = camera.CameraType
		camera.CameraType = Enum.CameraType.Scriptable

		-- Pod starts 800 studs above landing point
		local startPos = landingPos + Vector3.new(0, 800, 0)
		local pod, body, shield, eng = buildPodModel(startPos)

		-- 3. Snap camera to above the pod looking down
		camera.CFrame = CFrame.new(startPos + Vector3.new(20, 40, 20), startPos)

		-- 4. Fade back in to reveal space view
		fadeOut(blackGui, 0.8)

		-- 5. Pod descends via loop (800 studs over ~4 seconds)
		local descentTime = 4.0
		local elapsed     = 0
		local startCF     = CFrame.new(startPos)
		local endCF       = CFrame.new(landingPos + Vector3.new(0, 4, 0))

		local camOffset = Vector3.new(25, 20, 25)

		while elapsed < descentTime do
			local dt = RunService.RenderStepped:Wait()
			elapsed = elapsed + dt
			local t = math.min(elapsed / descentTime, 1)
			local eased = t * t * (3 - 2 * t)  -- smoothstep

			local podCF = startCF:Lerp(endCF, eased)
			pod:SetPrimaryPartCFrame(podCF)

			-- Camera follows pod from the side
			local podPos = podCF.Position
			camera.CFrame = CFrame.new(podPos + camOffset, podPos)

			-- Speed up glow as it nears
			local intensity = 1 + eased * 5
			if shield.Parent then
				shield.Parent:FindFirstChildWhichIsA("PointLight").Brightness = intensity * 4
			end
		end

		-- 6. Impact: flash + camera shake
		local impactGui, impactFrame = makeFade(Color3.fromRGB(255,150,50), 0)
		impactFrame.BackgroundTransparency = 0.3
		TweenService:Create(impactFrame, TweenInfo.new(0.5), {BackgroundTransparency=1}):Play()

		-- Shake camera briefly
		local shakeTime, shakeElapsed = 0.5, 0
		while shakeElapsed < shakeTime do
			local dt2 = RunService.RenderStepped:Wait()
			shakeElapsed = shakeElapsed + dt2
			local s = (1 - shakeElapsed / shakeTime) * 3
			camera.CFrame = camera.CFrame * CFrame.new(
				math.random(-100,100)/100*s,
				math.random(-100,100)/100*s, 0)
		end
		task.wait(0.4)
		impactGui:Destroy()

		-- 7. Fade to black again
		local blackGui2 = fadeIn(0.5)

		-- Clean up pod
		pod:Destroy()

		-- Restore camera
		camera.CameraType = prevType

		-- 8. Callback (teleport player, init dungeon, etc.)
		if onLanded then onLanded() end

		-- 9. Fade back to gameplay
		task.wait(0.2)
		fadeOut(blackGui2, 0.7)
	end)
end

return DropPod
