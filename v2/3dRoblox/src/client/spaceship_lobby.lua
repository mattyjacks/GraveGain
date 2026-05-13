-- LuckyStarShip Lobby Environment
local SpaceshipLobby = {}

function SpaceshipLobby:create_lobby_environment()
	print("[SpaceshipLobby] Creating LuckyStarShip lobby environment...")
	
	-- Create main floor
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Shape = Enum.PartType.Block
	floor.Size = Vector3.new(200, 2, 200)
	floor.Position = Vector3.new(0, 0, 0)
	floor.Material = Enum.Material.Metal
	floor.Color = Color3.fromRGB(40, 50, 70)
	floor.CanCollide = true
	floor.Anchored = true
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.BottomSurface = Enum.SurfaceType.Smooth
	floor.Parent = workspace
	
	-- Add floor grid pattern
	for x = -100, 100, 20 do
		for z = -100, 100, 20 do
			local grid_line = Instance.new("Part")
			grid_line.Name = "GridLine"
			grid_line.Shape = Enum.PartType.Block
			grid_line.Size = Vector3.new(0.2, 0.1, 20)
			grid_line.Position = Vector3.new(x, 1.1, z)
			grid_line.Material = Enum.Material.Neon
			grid_line.Color = Color3.fromRGB(100, 150, 200)
			grid_line.CanCollide = false
			grid_line.Anchored = true
			grid_line.Parent = workspace
		end
	end
	
	-- Create walls (spaceship hull)
	local wall_north = Instance.new("Part")
	wall_north.Name = "WallNorth"
	wall_north.Shape = Enum.PartType.Block
	wall_north.Size = Vector3.new(200, 50, 2)
	wall_north.Position = Vector3.new(0, 25, -100)
	wall_north.Material = Enum.Material.Metal
	wall_north.Color = Color3.fromRGB(60, 70, 90)
	wall_north.CanCollide = true
	wall_north.Anchored = true
	wall_north.Parent = workspace
	
	local wall_south = Instance.new("Part")
	wall_south.Name = "WallSouth"
	wall_south.Shape = Enum.PartType.Block
	wall_south.Size = Vector3.new(200, 50, 2)
	wall_south.Position = Vector3.new(0, 25, 100)
	wall_south.Material = Enum.Material.Metal
	wall_south.Color = Color3.fromRGB(60, 70, 90)
	wall_south.CanCollide = true
	wall_south.Anchored = true
	wall_south.Parent = workspace
	
	local wall_east = Instance.new("Part")
	wall_east.Name = "WallEast"
	wall_east.Shape = Enum.PartType.Block
	wall_east.Size = Vector3.new(2, 50, 200)
	wall_east.Position = Vector3.new(100, 25, 0)
	wall_east.Material = Enum.Material.Metal
	wall_east.Color = Color3.fromRGB(60, 70, 90)
	wall_east.CanCollide = true
	wall_east.Anchored = true
	wall_east.Parent = workspace
	
	local wall_west = Instance.new("Part")
	wall_west.Name = "WallWest"
	wall_west.Shape = Enum.PartType.Block
	wall_west.Size = Vector3.new(2, 50, 200)
	wall_west.Position = Vector3.new(-100, 25, 0)
	wall_west.Material = Enum.Material.Metal
	wall_west.Color = Color3.fromRGB(60, 70, 90)
	wall_west.CanCollide = true
	wall_west.Anchored = true
	wall_west.Parent = workspace
	
	-- Create ceiling
	local ceiling = Instance.new("Part")
	ceiling.Name = "Ceiling"
	ceiling.Shape = Enum.PartType.Block
	ceiling.Size = Vector3.new(200, 2, 200)
	ceiling.Position = Vector3.new(0, 50, 0)
	ceiling.Material = Enum.Material.Metal
	ceiling.Color = Color3.fromRGB(40, 50, 70)
	ceiling.CanCollide = true
	ceiling.Anchored = true
	ceiling.Parent = workspace
	
	-- Create central platform for character spawn
	local center_platform = Instance.new("Part")
	center_platform.Name = "CenterPlatform"
	center_platform.Shape = Enum.PartType.Cylinder
	center_platform.Size = Vector3.new(20, 0.5, 20)
	center_platform.Position = Vector3.new(0, 2.5, 0)
	center_platform.Material = Enum.Material.Neon
	center_platform.Color = Color3.fromRGB(100, 200, 255)
	center_platform.CanCollide = false
	center_platform.Anchored = true
	center_platform.TopSurface = Enum.SurfaceType.Smooth
	center_platform.BottomSurface = Enum.SurfaceType.Smooth
	center_platform.Parent = workspace
	
	-- Create window panels (spaceship aesthetic)
	for i = 1, 8 do
		local angle = (i - 1) * (math.pi * 2 / 8)
		local x = math.cos(angle) * 95
		local z = math.sin(angle) * 95
		
		local window = Instance.new("Part")
		window.Name = "Window_" .. i
		window.Shape = Enum.PartType.Block
		window.Size = Vector3.new(15, 15, 0.5)
		window.Position = Vector3.new(x, 25, z)
		window.Material = Enum.Material.Glass
		window.Color = Color3.fromRGB(100, 150, 200)
		window.CanCollide = false
		window.Anchored = true
		window.Transparency = 0.3
		window.Parent = workspace
		
		-- Rotate window to face outward
		window.CFrame = CFrame.new(window.Position) * CFrame.Angles(0, angle, 0)
	end
	
	-- Create decorative pillars
	for i = 1, 4 do
		local angle = (i - 1) * (math.pi / 2)
		local x = math.cos(angle) * 60
		local z = math.sin(angle) * 60
		
		local pillar = Instance.new("Part")
		pillar.Name = "Pillar_" .. i
		pillar.Shape = Enum.PartType.Cylinder
		pillar.Size = Vector3.new(3, 40, 3)
		pillar.Position = Vector3.new(x, 20, z)
		pillar.Material = Enum.Material.Metal
		pillar.Color = Color3.fromRGB(150, 150, 150)
		pillar.CanCollide = true
		pillar.Anchored = true
		pillar.Parent = workspace
	end
	
	-- Create lighting rigs
	local light1 = Instance.new("Part")
	light1.Name = "LightRig1"
	light1.Shape = Enum.PartType.Block
	light1.Size = Vector3.new(40, 2, 40)
	light1.Position = Vector3.new(-50, 48, -50)
	light1.Material = Enum.Material.Neon
	light1.Color = Color3.fromRGB(200, 200, 255)
	light1.CanCollide = false
	light1.Anchored = true
	light1.Transparency = 0.5
	light1.Parent = workspace
	
	local light2 = Instance.new("Part")
	light2.Name = "LightRig2"
	light2.Shape = Enum.PartType.Block
	light2.Size = Vector3.new(40, 2, 40)
	light2.Position = Vector3.new(50, 48, 50)
	light2.Material = Enum.Material.Neon
	light2.Color = Color3.fromRGB(200, 200, 255)
	light2.CanCollide = false
	light2.Anchored = true
	light2.Transparency = 0.5
	light2.Parent = workspace
	
	-- Add ambient lighting
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(100, 120, 150)
	lighting.OutdoorAmbient = Color3.fromRGB(100, 120, 150)
	lighting.ClockTime = 14
	
	-- Create a blue glow effect in the center
	local glow = Instance.new("Part")
	glow.Name = "CenterGlow"
	glow.Shape = Enum.PartType.Ball
	glow.Size = Vector3.new(30, 30, 30)
	glow.Position = Vector3.new(0, 15, 0)
	glow.Material = Enum.Material.Neon
	glow.Color = Color3.fromRGB(100, 200, 255)
	glow.CanCollide = false
	glow.Anchored = true
	glow.Transparency = 0.7
	glow.Parent = workspace
	
	print("[SpaceshipLobby] LuckyStarShip lobby created!")
end

return SpaceshipLobby
