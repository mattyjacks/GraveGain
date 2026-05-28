-- BattleSharks Voxel Types System
-- Defines different voxel materials and their properties

local VoxelTypes = {}

-- Voxel material types
VoxelTypes.MaterialType = {
	Water = "Water",
	Sand = "Sand",
	Gravel = "Gravel",
	Stone = "Stone",
	Coral = "Coral",
	Seaweed = "Seaweed",
	Volcanic = "Volcanic",
	Ice = "Ice",
	Mud = "Mud",
	Crystal = "Crystal",
	Air = "Air"
}

-- Voxel properties for each material type
VoxelTypes.Properties = {
	[VoxelTypes.MaterialType.Water] = {
		Name = "Water",
		Color = Color3.new(0.2, 0.6, 1.0),
		Transparency = 0.8,
		Reflectance = 0.3,
		Material = Enum.Material.Water,
		Density = 1.0,
		Strength = 0,
		IsSolid = false,
		IsLiquid = true,
		IsTransparent = true,
		LightPassesThrough = true,
		CanSwimThrough = true,
		FlowSpeed = 2.0,
		Resistance = 0.1
	},
	
	[VoxelTypes.MaterialType.Sand] = {
		Name = "Sand",
		Color = Color3.new(0.9, 0.8, 0.6),
		Transparency = 0,
		Reflectance = 0.1,
		Material = Enum.Material.Sand,
		Density = 1.5,
		Strength = 1,
		IsSolid = true,
		IsLiquid = false,
		IsTransparent = false,
		LightPassesThrough = false,
		CanSwimThrough = false,
		Resistance = 0.3,
		ParticleEffect = "Sand"
	},
	
	[VoxelTypes.MaterialType.Gravel] = {
		Name = "Gravel",
		Color = Color3.new(0.5, 0.5, 0.5),
		Transparency = 0,
		Reflectance = 0.2,
		Material = Enum.Material.Gravel,
		Density = 2.0,
		Strength = 2,
		IsSolid = true,
		IsLiquid = false,
		IsTransparent = false,
		LightPassesThrough = false,
		CanSwimThrough = false,
		Resistance = 0.5,
		ParticleEffect = "Gravel"
	},
	
	[VoxelTypes.MaterialType.Stone] = {
		Name = "Stone",
		Color = Color3.new(0.6, 0.6, 0.7),
		Transparency = 0,
		Reflectance = 0.1,
		Material = Enum.Material.Stone,
		Density = 3.0,
		Strength = 5,
		IsSolid = true,
		IsLiquid = false,
		IsTransparent = false,
		LightPassesThrough = false,
		CanSwimThrough = false,
		Resistance = 1.0
	},
	
	[VoxelTypes.MaterialType.Coral] = {
		Name = "Coral",
		Color = Color3.new(1.0, 0.4, 0.6),
		Transparency = 0.2,
		Reflectance = 0.3,
		Material = Enum.Material.Plastic,
		Density = 1.2,
		Strength = 2,
		IsSolid = true,
		IsLiquid = false,
		IsTransparent = true,
		LightPassesThrough = true,
		CanSwimThrough = false,
		Resistance = 0.4,
		GlowEffect = true
	},
	
	[VoxelTypes.MaterialType.Seaweed] = {
		Name = "Seaweed",
		Color = Color3.new(0.2, 0.8, 0.3),
		Transparency = 0.4,
		Reflectance = 0.1,
		Material = Enum.Material.Grass,
		Density = 0.8,
		Strength = 0,
		IsSolid = false,
		IsLiquid = false,
		IsTransparent = true,
		LightPassesThrough = true,
		CanSwimThrough = true,
		Resistance = 0.1,
		Animated = true,
		SwaySpeed = 2.0
	},
	
	[VoxelTypes.MaterialType.Volcanic] = {
		Name = "Volcanic Rock",
		Color = Color3.new(0.3, 0.1, 0.1),
		Transparency = 0,
		Reflectance = 0.05,
		Material = Enum.Material.Basalt,
		Density = 3.5,
		Strength = 8,
		IsSolid = true,
		IsLiquid = false,
		IsTransparent = false,
		LightPassesThrough = false,
		CanSwimThrough = false,
		Resistance = 2.0,
		HeatDamage = 5,
		GlowEffect = true
	},
	
	[VoxelTypes.MaterialType.Ice] = {
		Name = "Ice",
		Color = Color3.new(0.8, 0.9, 1.0),
		Transparency = 0.3,
		Reflectance = 0.8,
		Material = Enum.Material.Ice,
		Density = 0.9,
		Strength = 3,
		IsSolid = true,
		IsLiquid = false,
		IsTransparent = true,
		LightPassesThrough = true,
		CanSwimThrough = false,
		Resistance = 0.7,
		Slippery = true,
		ColdDamage = 2
	},
	
	[VoxelTypes.MaterialType.Mud] = {
		Name = "Mud",
		Color = Color3.new(0.4, 0.3, 0.2),
		Transparency = 0,
		Reflectance = 0.05,
		Material = Enum.Material.Mud,
		Density = 1.8,
		Strength = 1,
		IsSolid = true,
		IsLiquid = false,
		IsTransparent = false,
		LightPassesThrough = false,
		CanSwimThrough = false,
		Resistance = 0.2,
		SlowsMovement = true,
		SpeedReduction = 0.5
	},
	
	[VoxelTypes.MaterialType.Crystal] = {
		Name = "Crystal",
		Color = Color3.new(0.7, 0.3, 1.0),
		Transparency = 0.1,
		Reflectance = 0.9,
		Material = Enum.Material.Glass,
		Density = 2.5,
		Strength = 6,
		IsSolid = true,
		IsLiquid = false,
		IsTransparent = true,
		LightPassesThrough = true,
		CanSwimThrough = false,
		Resistance = 1.5,
		GlowEffect = true,
		LightRefraction = true
	},
	
	[VoxelTypes.MaterialType.Air] = {
		Name = "Air",
		Color = Color3.new(1, 1, 1),
		Transparency = 1,
		Reflectance = 0,
		Material = Enum.Material.Air,
		Density = 0.1,
		Strength = 0,
		IsSolid = false,
		IsLiquid = false,
		IsTransparent = true,
		LightPassesThrough = true,
		CanSwimThrough = true,
		Resistance = 0
	}
}

-- Get voxel properties by material type
function VoxelTypes.GetProperties(materialType)
	return VoxelTypes.Properties[materialType] or VoxelTypes.Properties[VoxelTypes.MaterialType.Air]
end

-- Check if a voxel type is solid
function VoxelTypes.IsSolid(materialType)
	local properties = VoxelTypes.GetProperties(materialType)
	return properties.IsSolid
end

-- Check if a voxel type is liquid
function VoxelTypes.IsLiquid(materialType)
	local properties = VoxelTypes.GetProperties(materialType)
	return properties.IsLiquid
end

-- Check if a voxel type is transparent
function VoxelTypes.IsTransparent(materialType)
	local properties = VoxelTypes.GetProperties(materialType)
	return properties.IsTransparent
end

-- Get voxel resistance for destruction calculations
function VoxelTypes.GetResistance(materialType)
	local properties = VoxelTypes.GetProperties(materialType)
	return properties.Resistance or 0
end

-- Get voxel color with optional variation
function VoxelTypes.GetColor(materialType, variation)
	variation = variation or 0
	local properties = VoxelTypes.GetProperties(materialType)
	local baseColor = properties.Color
	
	-- Add slight color variation for natural look
	if variation > 0 then
		return Color3.new(
			math.clamp(baseColor.R + (math.random() - 0.5) * variation, 0, 1),
			math.clamp(baseColor.G + (math.random() - 0.5) * variation, 0, 1),
			math.clamp(baseColor.B + (math.random() - 0.5) * variation, 0, 1)
		)
	end
	
	return baseColor
end

-- Get all solid voxel types
function VoxelTypes.GetSolidTypes()
	local solidTypes = {}
	for materialType, properties in pairs(VoxelTypes.Properties) do
		if properties.IsSolid then
			table.insert(solidTypes, materialType)
		end
	end
	return solidTypes
end

-- Get all liquid voxel types
function VoxelTypes.GetLiquidTypes()
	local liquidTypes = {}
	for materialType, properties in pairs(VoxelTypes.Properties) do
		if properties.IsLiquid then
			table.insert(liquidTypes, materialType)
		end
	end
	return liquidTypes
end

-- Check if voxel can be destroyed by damage
function VoxelTypes.CanDestroy(materialType, damage)
	local properties = VoxelTypes.GetProperties(materialType)
	return properties.Strength > 0 and damage >= properties.Resistance
end

return VoxelTypes
