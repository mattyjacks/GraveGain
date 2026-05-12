local WeaponSystem = {}

-- Weapon definitions for each race/class combination (primary weapon)
local WEAPONS = {
	human_dps = { name = "Plasma Rifle", type = "ranged", damage = 35, fire_rate = 0.1, melee = "Combat Knife" },
	human_tank = { name = "Pulse Cannon", type = "ranged", damage = 28, fire_rate = 0.15, melee = "Energy Shield" },
	human_support = { name = "Healing Blaster", type = "ranged", damage = 15, fire_rate = 0.2, melee = "Healing Rod" },
	human_mage = { name = "Energy Staff", type = "ranged", damage = 40, fire_rate = 0.25, melee = "Arcane Dagger" },
	
	elf_dps = { name = "Elven Longbow", type = "ranged", damage = 32, fire_rate = 0.12, melee = "Elven Blade" },
	elf_tank = { name = "Elven Greatbow", type = "ranged", damage = 26, fire_rate = 0.18, melee = "Elven Sword" },
	elf_support = { name = "Healing Bow", type = "ranged", damage = 12, fire_rate = 0.2, melee = "Healing Dagger" },
	elf_mage = { name = "Arcane Bow", type = "ranged", damage = 38, fire_rate = 0.22, melee = "Arcane Blade" },
	
	dwarf_dps = { name = "Dwarven Crossbow", type = "ranged", damage = 40, fire_rate = 0.2, melee = "Dwarven Pickaxe" },
	dwarf_tank = { name = "Dwarven Ballista", type = "ranged", damage = 32, fire_rate = 0.3, melee = "Dwarven Shield" },
	dwarf_support = { name = "Healing Crossbow", type = "ranged", damage = 18, fire_rate = 0.25, melee = "Healing Hammer" },
	dwarf_mage = { name = "Runic Crossbow", type = "ranged", damage = 42, fire_rate = 0.28, melee = "Runic Hammer" },
	
	orc_dps = { name = "Orc Greataxe", type = "melee", damage = 50, fire_rate = 0.4, ranged = "Orc Bow" },
	orc_tank = { name = "Orc Warhammer", type = "melee", damage = 42, fire_rate = 0.5, ranged = "Orc Cannon" },
	orc_support = { name = "Orc Mace", type = "melee", damage = 28, fire_rate = 0.45, ranged = "Orc Blaster" },
	orc_mage = { name = "Chaos Blade", type = "melee", damage = 48, fire_rate = 0.35, ranged = "Chaos Staff" }
}

function WeaponSystem:create_weapon_model(race, class_type, parent)
	local weapon = Instance.new("Model")
	local weapon_key = race .. "_" .. class_type
	local weapon_data = WEAPONS[weapon_key] or WEAPONS.human_dps
	weapon.Name = weapon_data.name
	weapon.Parent = parent
	
	-- Human weapons (ranged)
	if race == "human" and class_type == "dps" then
		-- Plasma Rifle: sleek sci-fi rifle
		self:create_plasma_rifle(weapon)
	elseif race == "human" and class_type == "tank" then
		-- Pulse Cannon: heavy cannon
		self:create_pulse_cannon(weapon)
	elseif race == "human" and class_type == "support" then
		-- Healing Blaster: medical weapon
		self:create_healing_blaster(weapon)
	elseif race == "human" and class_type == "mage" then
		-- Energy Staff: magical staff
		self:create_energy_staff(weapon)
	
	-- Elf weapons (bows)
	elseif race == "elf" and class_type == "dps" then
		-- Elven Longbow: elegant bow
		self:create_elven_longbow(weapon)
	elseif race == "elf" and class_type == "tank" then
		-- Elven Greatbow: powerful bow
		self:create_elven_greatbow(weapon)
	elseif race == "elf" and class_type == "support" then
		-- Healing Bow: support bow
		self:create_healing_bow(weapon)
	elseif race == "elf" and class_type == "mage" then
		-- Arcane Bow: magical bow
		self:create_arcane_bow(weapon)
	
	-- Dwarf weapons (crossbows)
	elseif race == "dwarf" and class_type == "dps" then
		-- Dwarven Crossbow: standard crossbow
		self:create_dwarven_crossbow(weapon)
	elseif race == "dwarf" and class_type == "tank" then
		-- Dwarven Ballista: heavy crossbow
		self:create_dwarven_ballista(weapon)
	elseif race == "dwarf" and class_type == "support" then
		-- Healing Crossbow: support crossbow
		self:create_healing_crossbow(weapon)
	elseif race == "dwarf" and class_type == "mage" then
		-- Runic Crossbow: magical crossbow
		self:create_runic_crossbow(weapon)
	
	-- Orc weapons (melee)
	elseif race == "orc" and class_type == "dps" then
		-- Orc Greataxe: massive axe
		self:create_orc_greataxe(weapon)
	elseif race == "orc" and class_type == "tank" then
		-- Orc Warhammer: heavy hammer
		self:create_orc_warhammer(weapon)
	elseif race == "orc" and class_type == "support" then
		-- Orc Mace: support mace
		self:create_orc_mace(weapon)
	elseif race == "orc" and class_type == "mage" then
		-- Chaos Blade: magical blade
		self:create_chaos_blade(weapon)
	else
		-- Fallback: simple rifle
		self:create_plasma_rifle(weapon)
	end
	
	-- Set primary part (first part created)
	local first_part = weapon:FindFirstChildOfClass("Part")
	if first_part then
		weapon.PrimaryPart = first_part
	end
	
	return weapon
end

-- ===== HUMAN WEAPONS =====
function WeaponSystem:create_plasma_rifle(weapon)
	-- Plasma Rifle: sleek sci-fi rifle
	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Shape = Enum.PartType.Cylinder
	barrel.Size = Vector3.new(0.25, 2.5, 0.25)
	barrel.Color = Color3.fromRGB(50, 50, 50)
	barrel.Material = Enum.Material.Metal
	barrel.CanCollide = false
	barrel.Parent = weapon
	
	local stock = Instance.new("Part")
	stock.Name = "Stock"
	stock.Shape = Enum.PartType.Block
	stock.Size = Vector3.new(0.4, 0.6, 1.2)
	stock.Color = Color3.fromRGB(30, 30, 30)
	stock.Material = Enum.Material.Metal
	stock.CanCollide = false
	stock.Parent = weapon
	stock.Position = barrel.Position - Vector3.new(0, 0, 0.8)
	
	local scope = Instance.new("Part")
	scope.Name = "Scope"
	scope.Shape = Enum.PartType.Cylinder
	scope.Size = Vector3.new(0.15, 0.8, 0.15)
	scope.Color = Color3.fromRGB(100, 150, 200)
	scope.Material = Enum.Material.Glass
	scope.CanCollide = false
	scope.Parent = weapon
	scope.Position = barrel.Position + Vector3.new(0.3, 0.3, 0)
	
	local energy_cell = Instance.new("Part")
	energy_cell.Name = "EnergyCell"
	energy_cell.Shape = Enum.PartType.Block
	energy_cell.Size = Vector3.new(0.3, 0.5, 0.3)
	energy_cell.Color = Color3.fromRGB(0, 200, 255)
	energy_cell.Material = Enum.Material.Neon
	energy_cell.CanCollide = false
	energy_cell.Parent = weapon
	energy_cell.Position = barrel.Position - Vector3.new(0.2, 0.3, 0.3)
end

function WeaponSystem:create_pulse_cannon(weapon)
	-- Pulse Cannon: heavy cannon
	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Shape = Enum.PartType.Cylinder
	barrel.Size = Vector3.new(0.4, 3, 0.4)
	barrel.Color = Color3.fromRGB(80, 80, 80)
	barrel.Material = Enum.Material.Metal
	barrel.CanCollide = false
	barrel.Parent = weapon
	
	local muzzle = Instance.new("Part")
	muzzle.Name = "Muzzle"
	muzzle.Shape = Enum.PartType.Cylinder
	muzzle.Size = Vector3.new(0.5, 0.3, 0.5)
	muzzle.Color = Color3.fromRGB(100, 100, 100)
	muzzle.Material = Enum.Material.Metal
	muzzle.CanCollide = false
	muzzle.Parent = weapon
	muzzle.Position = barrel.Position + Vector3.new(0, 1.6, 0)
	
	local stock = Instance.new("Part")
	stock.Name = "Stock"
	stock.Shape = Enum.PartType.Block
	stock.Size = Vector3.new(0.5, 0.8, 1.5)
	stock.Color = Color3.fromRGB(40, 40, 40)
	stock.Material = Enum.Material.Metal
	stock.CanCollide = false
	stock.Parent = weapon
	stock.Position = barrel.Position - Vector3.new(0, 0, 1)
	
	local power_core = Instance.new("Part")
	power_core.Name = "PowerCore"
	power_core.Shape = Enum.PartType.Ball
	power_core.Size = Vector3.new(0.4, 0.4, 0.4)
	power_core.Color = Color3.fromRGB(255, 100, 0)
	power_core.Material = Enum.Material.Neon
	power_core.CanCollide = false
	power_core.Parent = weapon
	power_core.Position = barrel.Position - Vector3.new(0.3, 0.5, 0.5)
end

function WeaponSystem:create_healing_blaster(weapon)
	-- Healing Blaster: medical weapon
	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Shape = Enum.PartType.Cylinder
	barrel.Size = Vector3.new(0.2, 2, 0.2)
	barrel.Color = Color3.fromRGB(100, 100, 100)
	barrel.Material = Enum.Material.Metal
	barrel.CanCollide = false
	barrel.Parent = weapon
	
	local stock = Instance.new("Part")
	stock.Name = "Stock"
	stock.Shape = Enum.PartType.Block
	stock.Size = Vector3.new(0.35, 0.5, 1)
	stock.Color = Color3.fromRGB(200, 200, 200)
	stock.Material = Enum.Material.Metal
	stock.CanCollide = false
	stock.Parent = weapon
	stock.Position = barrel.Position - Vector3.new(0, 0, 0.7)
	
	local heal_crystal = Instance.new("Part")
	heal_crystal.Name = "HealCrystal"
	heal_crystal.Shape = Enum.PartType.Block
	heal_crystal.Size = Vector3.new(0.25, 0.4, 0.25)
	heal_crystal.Color = Color3.fromRGB(0, 255, 100)
	heal_crystal.Material = Enum.Material.Neon
	heal_crystal.CanCollide = false
	heal_crystal.Parent = weapon
	heal_crystal.Position = barrel.Position + Vector3.new(0.2, 0.2, 0)
end

function WeaponSystem:create_energy_staff(weapon)
	-- Energy Staff: magical staff
	local staff = Instance.new("Part")
	staff.Name = "Staff"
	staff.Shape = Enum.PartType.Cylinder
	staff.Size = Vector3.new(0.15, 3, 0.15)
	staff.Color = Color3.fromRGB(100, 50, 150)
	staff.Material = Enum.Material.Metal
	staff.CanCollide = false
	staff.Parent = weapon
	
	local orb = Instance.new("Part")
	orb.Name = "Orb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(0.6, 0.6, 0.6)
	orb.Color = Color3.fromRGB(200, 100, 255)
	orb.Material = Enum.Material.Neon
	orb.CanCollide = false
	orb.Parent = weapon
	orb.Position = staff.Position + Vector3.new(0, 1.6, 0)
	
	local grip = Instance.new("Part")
	grip.Name = "Grip"
	grip.Shape = Enum.PartType.Block
	grip.Size = Vector3.new(0.3, 0.4, 0.3)
	grip.Color = Color3.fromRGB(150, 100, 50)
	grip.Material = Enum.Material.Metal
	grip.CanCollide = false
	grip.Parent = weapon
	grip.Position = staff.Position - Vector3.new(0, 1, 0)
end

-- ===== ELF WEAPONS (BOWS) =====
function WeaponSystem:create_elven_longbow(weapon)
	-- Elven Longbow: elegant bow
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Shape = Enum.PartType.Cylinder
	frame.Size = Vector3.new(0.1, 2.2, 0.1)
	frame.Color = Color3.fromRGB(139, 69, 19)
	frame.Material = Enum.Material.Wood
	frame.CanCollide = false
	frame.Parent = weapon
	
	local bowstring = Instance.new("Part")
	bowstring.Name = "Bowstring"
	bowstring.Shape = Enum.PartType.Block
	bowstring.Size = Vector3.new(0.05, 2, 0.05)
	bowstring.Color = Color3.fromRGB(200, 200, 200)
	bowstring.Material = Enum.Material.Fabric
	bowstring.CanCollide = false
	bowstring.Parent = weapon
	bowstring.Position = frame.Position + Vector3.new(0.15, 0, 0)
	
	local grip = Instance.new("Part")
	grip.Name = "Grip"
	grip.Shape = Enum.PartType.Block
	grip.Size = Vector3.new(0.25, 0.3, 0.25)
	grip.Color = Color3.fromRGB(100, 50, 0)
	grip.Material = Enum.Material.Wood
	grip.CanCollide = false
	grip.Parent = weapon
	grip.Position = frame.Position
	
	local leaf = Instance.new("Part")
	leaf.Name = "Leaf"
	leaf.Shape = Enum.PartType.Block
	leaf.Size = Vector3.new(0.1, 0.3, 0.1)
	leaf.Color = Color3.fromRGB(34, 139, 34)
	leaf.Material = Enum.Material.Neon
	leaf.CanCollide = false
	leaf.Parent = weapon
	leaf.Position = frame.Position + Vector3.new(0.2, 0.8, 0)
end

function WeaponSystem:create_elven_greatbow(weapon)
	-- Elven Greatbow: powerful bow
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Shape = Enum.PartType.Cylinder
	frame.Size = Vector3.new(0.15, 2.8, 0.15)
	frame.Color = Color3.fromRGB(139, 69, 19)
	frame.Material = Enum.Material.Wood
	frame.CanCollide = false
	frame.Parent = weapon
	
	local bowstring = Instance.new("Part")
	bowstring.Name = "Bowstring"
	bowstring.Shape = Enum.PartType.Block
	bowstring.Size = Vector3.new(0.08, 2.6, 0.08)
	bowstring.Color = Color3.fromRGB(220, 220, 220)
	bowstring.Material = Enum.Material.Fabric
	bowstring.CanCollide = false
	bowstring.Parent = weapon
	bowstring.Position = frame.Position + Vector3.new(0.2, 0, 0)
	
	local grip = Instance.new("Part")
	grip.Name = "Grip"
	grip.Shape = Enum.PartType.Block
	grip.Size = Vector3.new(0.3, 0.4, 0.3)
	grip.Color = Color3.fromRGB(100, 50, 0)
	grip.Material = Enum.Material.Wood
	grip.CanCollide = false
	grip.Parent = weapon
	grip.Position = frame.Position
	
	local crystal = Instance.new("Part")
	crystal.Name = "Crystal"
	crystal.Shape = Enum.PartType.Block
	crystal.Size = Vector3.new(0.15, 0.4, 0.15)
	crystal.Color = Color3.fromRGB(100, 200, 255)
	crystal.Material = Enum.Material.Neon
	crystal.CanCollide = false
	crystal.Parent = weapon
	crystal.Position = frame.Position + Vector3.new(0.25, 1.2, 0)
end

function WeaponSystem:create_healing_bow(weapon)
	-- Healing Bow: support bow
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Shape = Enum.PartType.Cylinder
	frame.Size = Vector3.new(0.1, 2, 0.1)
	frame.Color = Color3.fromRGB(200, 200, 100)
	frame.Material = Enum.Material.Wood
	frame.CanCollide = false
	frame.Parent = weapon
	
	local bowstring = Instance.new("Part")
	bowstring.Name = "Bowstring"
	bowstring.Shape = Enum.PartType.Block
	bowstring.Size = Vector3.new(0.05, 1.8, 0.05)
	bowstring.Color = Color3.fromRGB(255, 200, 100)
	bowstring.Material = Enum.Material.Fabric
	bowstring.CanCollide = false
	bowstring.Parent = weapon
	bowstring.Position = frame.Position + Vector3.new(0.15, 0, 0)
	
	local heal_aura = Instance.new("Part")
	heal_aura.Name = "HealAura"
	heal_aura.Shape = Enum.PartType.Ball
	heal_aura.Size = Vector3.new(0.3, 0.3, 0.3)
	heal_aura.Color = Color3.fromRGB(0, 255, 100)
	heal_aura.Material = Enum.Material.Neon
	heal_aura.CanCollide = false
	heal_aura.Parent = weapon
	heal_aura.Position = frame.Position + Vector3.new(0.2, 0.7, 0)
end

function WeaponSystem:create_arcane_bow(weapon)
	-- Arcane Bow: magical bow
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Shape = Enum.PartType.Cylinder
	frame.Size = Vector3.new(0.12, 2.3, 0.12)
	frame.Color = Color3.fromRGB(100, 50, 150)
	frame.Material = Enum.Material.Metal
	frame.CanCollide = false
	frame.Parent = weapon
	
	local bowstring = Instance.new("Part")
	bowstring.Name = "Bowstring"
	bowstring.Shape = Enum.PartType.Block
	bowstring.Size = Vector3.new(0.06, 2.1, 0.06)
	bowstring.Color = Color3.fromRGB(200, 100, 255)
	bowstring.Material = Enum.Material.Neon
	bowstring.CanCollide = false
	bowstring.Parent = weapon
	bowstring.Position = frame.Position + Vector3.new(0.18, 0, 0)
	
	local arcane_gem = Instance.new("Part")
	arcane_gem.Name = "ArcaneGem"
	arcane_gem.Shape = Enum.PartType.Block
	arcane_gem.Size = Vector3.new(0.2, 0.3, 0.2)
	arcane_gem.Color = Color3.fromRGB(150, 100, 255)
	arcane_gem.Material = Enum.Material.Neon
	arcane_gem.CanCollide = false
	arcane_gem.Parent = weapon
	arcane_gem.Position = frame.Position + Vector3.new(0.22, 0.9, 0)
end

-- ===== DWARF WEAPONS (CROSSBOWS) =====
function WeaponSystem:create_dwarven_crossbow(weapon)
	-- Dwarven Crossbow: standard crossbow
	local stock = Instance.new("Part")
	stock.Name = "Stock"
	stock.Shape = Enum.PartType.Block
	stock.Size = Vector3.new(0.3, 0.4, 1.5)
	stock.Color = Color3.fromRGB(100, 100, 100)
	stock.Material = Enum.Material.Metal
	stock.CanCollide = false
	stock.Parent = weapon
	
	local bow_arm = Instance.new("Part")
	bow_arm.Name = "BowArm"
	bow_arm.Shape = Enum.PartType.Block
	bow_arm.Size = Vector3.new(0.15, 1.2, 0.15)
	bow_arm.Color = Color3.fromRGB(120, 120, 120)
	bow_arm.Material = Enum.Material.Metal
	bow_arm.CanCollide = false
	bow_arm.Parent = weapon
	bow_arm.Position = stock.Position + Vector3.new(0, 0.6, 0.5)
	
	local string = Instance.new("Part")
	string.Name = "String"
	string.Shape = Enum.PartType.Block
	string.Size = Vector3.new(0.05, 1, 0.05)
	string.Color = Color3.fromRGB(200, 200, 200)
	string.Material = Enum.Material.Fabric
	string.CanCollide = false
	string.Parent = weapon
	string.Position = bow_arm.Position + Vector3.new(0.1, 0, 0)
	
	local trigger = Instance.new("Part")
	trigger.Name = "Trigger"
	trigger.Shape = Enum.PartType.Block
	trigger.Size = Vector3.new(0.1, 0.2, 0.2)
	trigger.Color = Color3.fromRGB(80, 80, 80)
	trigger.Material = Enum.Material.Metal
	trigger.CanCollide = false
	trigger.Parent = weapon
	trigger.Position = stock.Position + Vector3.new(0, -0.15, 0.3)
end

function WeaponSystem:create_dwarven_ballista(weapon)
	-- Dwarven Ballista: heavy crossbow
	local stock = Instance.new("Part")
	stock.Name = "Stock"
	stock.Shape = Enum.PartType.Block
	stock.Size = Vector3.new(0.4, 0.6, 2)
	stock.Color = Color3.fromRGB(80, 80, 80)
	stock.Material = Enum.Material.Metal
	stock.CanCollide = false
	stock.Parent = weapon
	
	local bow_arm = Instance.new("Part")
	bow_arm.Name = "BowArm"
	bow_arm.Shape = Enum.PartType.Block
	bow_arm.Size = Vector3.new(0.2, 1.5, 0.2)
	bow_arm.Color = Color3.fromRGB(100, 100, 100)
	bow_arm.Material = Enum.Material.Metal
	bow_arm.CanCollide = false
	bow_arm.Parent = weapon
	bow_arm.Position = stock.Position + Vector3.new(0, 0.8, 0.7)
	
	local string = Instance.new("Part")
	string.Name = "String"
	string.Shape = Enum.PartType.Block
	string.Size = Vector3.new(0.08, 1.3, 0.08)
	string.Color = Color3.fromRGB(220, 220, 220)
	string.Material = Enum.Material.Fabric
	string.CanCollide = false
	string.Parent = weapon
	string.Position = bow_arm.Position + Vector3.new(0.15, 0, 0)
	
	local power_core = Instance.new("Part")
	power_core.Name = "PowerCore"
	power_core.Shape = Enum.PartType.Ball
	power_core.Size = Vector3.new(0.35, 0.35, 0.35)
	power_core.Color = Color3.fromRGB(255, 100, 0)
	power_core.Material = Enum.Material.Neon
	power_core.CanCollide = false
	power_core.Parent = weapon
	power_core.Position = stock.Position + Vector3.new(0.25, 0.3, 0.5)
end

function WeaponSystem:create_healing_crossbow(weapon)
	-- Healing Crossbow: support crossbow
	local stock = Instance.new("Part")
	stock.Name = "Stock"
	stock.Shape = Enum.PartType.Block
	stock.Size = Vector3.new(0.25, 0.35, 1.2)
	stock.Color = Color3.fromRGB(150, 150, 150)
	stock.Material = Enum.Material.Metal
	stock.CanCollide = false
	stock.Parent = weapon
	
	local bow_arm = Instance.new("Part")
	bow_arm.Name = "BowArm"
	bow_arm.Shape = Enum.PartType.Block
	bow_arm.Size = Vector3.new(0.12, 0.9, 0.12)
	bow_arm.Color = Color3.fromRGB(130, 130, 130)
	bow_arm.Material = Enum.Material.Metal
	bow_arm.CanCollide = false
	bow_arm.Parent = weapon
	bow_arm.Position = stock.Position + Vector3.new(0, 0.45, 0.4)
	
	local heal_crystal = Instance.new("Part")
	heal_crystal.Name = "HealCrystal"
	heal_crystal.Shape = Enum.PartType.Block
	heal_crystal.Size = Vector3.new(0.2, 0.3, 0.2)
	heal_crystal.Color = Color3.fromRGB(0, 255, 100)
	heal_crystal.Material = Enum.Material.Neon
	heal_crystal.CanCollide = false
	heal_crystal.Parent = weapon
	heal_crystal.Position = stock.Position + Vector3.new(0.15, 0.15, 0.3)
end

function WeaponSystem:create_runic_crossbow(weapon)
	-- Runic Crossbow: magical crossbow
	local stock = Instance.new("Part")
	stock.Name = "Stock"
	stock.Shape = Enum.PartType.Block
	stock.Size = Vector3.new(0.28, 0.4, 1.3)
	stock.Color = Color3.fromRGB(100, 50, 150)
	stock.Material = Enum.Material.Metal
	stock.CanCollide = false
	stock.Parent = weapon
	
	local bow_arm = Instance.new("Part")
	bow_arm.Name = "BowArm"
	bow_arm.Shape = Enum.PartType.Block
	bow_arm.Size = Vector3.new(0.14, 1, 0.14)
	bow_arm.Color = Color3.fromRGB(120, 80, 180)
	bow_arm.Material = Enum.Material.Metal
	bow_arm.CanCollide = false
	bow_arm.Parent = weapon
	bow_arm.Position = stock.Position + Vector3.new(0, 0.5, 0.45)
	
	local rune = Instance.new("Part")
	rune.Name = "Rune"
	rune.Shape = Enum.PartType.Block
	rune.Size = Vector3.new(0.22, 0.35, 0.22)
	rune.Color = Color3.fromRGB(200, 100, 255)
	rune.Material = Enum.Material.Neon
	rune.CanCollide = false
	rune.Parent = weapon
	rune.Position = stock.Position + Vector3.new(0.18, 0.2, 0.35)
end

-- ===== ORC WEAPONS (MELEE) =====
function WeaponSystem:create_orc_greataxe(weapon)
	-- Orc Greataxe: massive axe
	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Shape = Enum.PartType.Block
	blade.Size = Vector3.new(1.2, 1.5, 0.2)
	blade.Color = Color3.fromRGB(100, 100, 100)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Parent = weapon
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Cylinder
	handle.Size = Vector3.new(0.25, 2, 0.25)
	handle.Color = Color3.fromRGB(80, 40, 0)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = blade.Position - Vector3.new(0, 1.2, 0)
	
	local pommel = Instance.new("Part")
	pommel.Name = "Pommel"
	pommel.Shape = Enum.PartType.Ball
	pommel.Size = Vector3.new(0.4, 0.4, 0.4)
	pommel.Color = Color3.fromRGB(200, 100, 0)
	pommel.Material = Enum.Material.Metal
	pommel.CanCollide = false
	pommel.Parent = weapon
	pommel.Position = handle.Position - Vector3.new(0, 1.1, 0)
end

function WeaponSystem:create_orc_warhammer(weapon)
	-- Orc Warhammer: heavy hammer
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Block
	head.Size = Vector3.new(0.8, 1.2, 0.8)
	head.Color = Color3.fromRGB(80, 80, 80)
	head.Material = Enum.Material.Metal
	head.CanCollide = false
	head.Parent = weapon
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Cylinder
	handle.Size = Vector3.new(0.3, 2.2, 0.3)
	handle.Color = Color3.fromRGB(100, 50, 0)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = head.Position - Vector3.new(0, 1.3, 0)
	
	local spike = Instance.new("Part")
	spike.Name = "Spike"
	spike.Shape = Enum.PartType.Block
	spike.Size = Vector3.new(0.15, 0.6, 0.15)
	spike.Color = Color3.fromRGB(150, 150, 150)
	spike.Material = Enum.Material.Metal
	spike.CanCollide = false
	spike.Parent = weapon
	spike.Position = head.Position + Vector3.new(0, 0.7, 0)
end

function WeaponSystem:create_orc_mace(weapon)
	-- Orc Mace: support mace
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(0.6, 0.6, 0.6)
	head.Color = Color3.fromRGB(100, 100, 100)
	head.Material = Enum.Material.Metal
	head.CanCollide = false
	head.Parent = weapon
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Cylinder
	handle.Size = Vector3.new(0.2, 1.5, 0.2)
	handle.Color = Color3.fromRGB(120, 60, 0)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = head.Position - Vector3.new(0, 0.8, 0)
	
	local bands = Instance.new("Part")
	bands.Name = "Bands"
	bands.Shape = Enum.PartType.Block
	bands.Size = Vector3.new(0.25, 0.15, 0.25)
	bands.Color = Color3.fromRGB(200, 150, 100)
	bands.Material = Enum.Material.Metal
	bands.CanCollide = false
	bands.Parent = weapon
	bands.Position = handle.Position - Vector3.new(0, 0.5, 0)
end

function WeaponSystem:create_chaos_blade(weapon)
	-- Chaos Blade: magical blade
	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Shape = Enum.PartType.Block
	blade.Size = Vector3.new(0.3, 2, 0.1)
	blade.Color = Color3.fromRGB(150, 50, 150)
	blade.Material = Enum.Material.Neon
	blade.CanCollide = false
	blade.Parent = weapon
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Cylinder
	handle.Size = Vector3.new(0.25, 1.2, 0.25)
	handle.Color = Color3.fromRGB(50, 20, 50)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = blade.Position - Vector3.new(0, 1.2, 0)
	
	local chaos_orb = Instance.new("Part")
	chaos_orb.Name = "ChaosOrb"
	chaos_orb.Shape = Enum.PartType.Ball
	chaos_orb.Size = Vector3.new(0.35, 0.35, 0.35)
	chaos_orb.Color = Color3.fromRGB(255, 50, 255)
	chaos_orb.Material = Enum.Material.Neon
	chaos_orb.CanCollide = false
	chaos_orb.Parent = weapon
	chaos_orb.Position = handle.Position - Vector3.new(0, 0.8, 0)
end

-- ===== SECONDARY MELEE WEAPONS (for ranged classes) =====
function WeaponSystem:create_combat_knife(weapon)
	-- Combat Knife: compact blade
	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Shape = Enum.PartType.Block
	blade.Size = Vector3.new(0.15, 0.8, 0.05)
	blade.Color = Color3.fromRGB(150, 150, 150)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Parent = weapon
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Block
	handle.Size = Vector3.new(0.12, 0.4, 0.12)
	handle.Color = Color3.fromRGB(100, 50, 0)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = blade.Position - Vector3.new(0, 0.4, 0)
end

function WeaponSystem:create_energy_shield(weapon)
	-- Energy Shield: defensive barrier
	local shield = Instance.new("Part")
	shield.Name = "Shield"
	shield.Shape = Enum.PartType.Block
	shield.Size = Vector3.new(0.6, 0.8, 0.15)
	shield.Color = Color3.fromRGB(100, 200, 255)
	shield.Material = Enum.Material.Neon
	shield.CanCollide = false
	shield.Parent = weapon
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Block
	handle.Size = Vector3.new(0.2, 0.3, 0.2)
	handle.Color = Color3.fromRGB(50, 50, 50)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = shield.Position - Vector3.new(0, 0.3, 0)
end

function WeaponSystem:create_healing_rod(weapon)
	-- Healing Rod: support staff
	local rod = Instance.new("Part")
	rod.Name = "Rod"
	rod.Shape = Enum.PartType.Cylinder
	rod.Size = Vector3.new(0.1, 1.2, 0.1)
	rod.Color = Color3.fromRGB(200, 200, 100)
	rod.Material = Enum.Material.Metal
	rod.CanCollide = false
	rod.Parent = weapon
	
	local crystal = Instance.new("Part")
	crystal.Name = "Crystal"
	crystal.Shape = Enum.PartType.Ball
	crystal.Size = Vector3.new(0.25, 0.25, 0.25)
	crystal.Color = Color3.fromRGB(0, 255, 100)
	crystal.Material = Enum.Material.Neon
	crystal.CanCollide = false
	crystal.Parent = weapon
	crystal.Position = rod.Position + Vector3.new(0, 0.7, 0)
end

function WeaponSystem:create_arcane_dagger(weapon)
	-- Arcane Dagger: magical blade
	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Shape = Enum.PartType.Block
	blade.Size = Vector3.new(0.12, 0.9, 0.04)
	blade.Color = Color3.fromRGB(150, 100, 255)
	blade.Material = Enum.Material.Neon
	blade.CanCollide = false
	blade.Parent = weapon
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Block
	handle.Size = Vector3.new(0.1, 0.35, 0.1)
	handle.Color = Color3.fromRGB(50, 20, 50)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = blade.Position - Vector3.new(0, 0.45, 0)
end

function WeaponSystem:create_elven_blade(weapon)
	-- Elven Blade: graceful sword
	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Shape = Enum.PartType.Block
	blade.Size = Vector3.new(0.2, 1.2, 0.08)
	blade.Color = Color3.fromRGB(100, 200, 255)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Parent = weapon
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Block
	handle.Size = Vector3.new(0.15, 0.4, 0.15)
	handle.Color = Color3.fromRGB(139, 69, 19)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = blade.Position - Vector3.new(0, 0.6, 0)
end

function WeaponSystem:create_elven_sword(weapon)
	-- Elven Sword: larger blade
	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Shape = Enum.PartType.Block
	blade.Size = Vector3.new(0.25, 1.5, 0.1)
	blade.Color = Color3.fromRGB(100, 200, 255)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Parent = weapon
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Block
	handle.Size = Vector3.new(0.18, 0.5, 0.18)
	handle.Color = Color3.fromRGB(139, 69, 19)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = blade.Position - Vector3.new(0, 0.75, 0)
	
	local gem = Instance.new("Part")
	gem.Name = "Gem"
	gem.Shape = Enum.PartType.Ball
	gem.Size = Vector3.new(0.15, 0.15, 0.15)
	gem.Color = Color3.fromRGB(100, 255, 200)
	gem.Material = Enum.Material.Neon
	gem.CanCollide = false
	gem.Parent = weapon
	gem.Position = handle.Position - Vector3.new(0, 0.3, 0)
end

function WeaponSystem:create_healing_dagger(weapon)
	-- Healing Dagger: support blade
	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Shape = Enum.PartType.Block
	blade.Size = Vector3.new(0.1, 0.7, 0.04)
	blade.Color = Color3.fromRGB(200, 200, 100)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Parent = weapon
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Block
	handle.Size = Vector3.new(0.1, 0.3, 0.1)
	handle.Color = Color3.fromRGB(100, 50, 0)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = blade.Position - Vector3.new(0, 0.35, 0)
end

function WeaponSystem:create_arcane_blade(weapon)
	-- Arcane Blade: magical sword
	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Shape = Enum.PartType.Block
	blade.Size = Vector3.new(0.22, 1.3, 0.08)
	blade.Color = Color3.fromRGB(150, 100, 255)
	blade.Material = Enum.Material.Neon
	blade.CanCollide = false
	blade.Parent = weapon
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Block
	handle.Size = Vector3.new(0.15, 0.45, 0.15)
	handle.Color = Color3.fromRGB(50, 20, 50)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = blade.Position - Vector3.new(0, 0.65, 0)
end

function WeaponSystem:create_dwarven_pickaxe(weapon)
	-- Dwarven Pickaxe: mining weapon
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Block
	head.Size = Vector3.new(0.5, 0.3, 0.5)
	head.Color = Color3.fromRGB(100, 100, 100)
	head.Material = Enum.Material.Metal
	head.CanCollide = false
	head.Parent = weapon
	
	local pick = Instance.new("Part")
	pick.Name = "Pick"
	pick.Shape = Enum.PartType.Block
	pick.Size = Vector3.new(0.15, 0.4, 0.15)
	pick.Color = Color3.fromRGB(150, 150, 150)
	pick.Material = Enum.Material.Metal
	pick.CanCollide = false
	pick.Parent = weapon
	pick.Position = head.Position + Vector3.new(0.3, 0, 0)
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Cylinder
	handle.Size = Vector3.new(0.15, 1, 0.15)
	handle.Color = Color3.fromRGB(80, 40, 0)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = head.Position - Vector3.new(0, 0.6, 0)
end

function WeaponSystem:create_dwarven_shield(weapon)
	-- Dwarven Shield: defensive barrier
	local shield = Instance.new("Part")
	shield.Name = "Shield"
	shield.Shape = Enum.PartType.Block
	shield.Size = Vector3.new(0.7, 1, 0.2)
	shield.Color = Color3.fromRGB(100, 100, 100)
	shield.Material = Enum.Material.Metal
	shield.CanCollide = false
	shield.Parent = weapon
	
	local boss = Instance.new("Part")
	boss.Name = "Boss"
	boss.Shape = Enum.PartType.Ball
	boss.Size = Vector3.new(0.3, 0.3, 0.3)
	boss.Color = Color3.fromRGB(200, 150, 100)
	boss.Material = Enum.Material.Metal
	boss.CanCollide = false
	boss.Parent = weapon
	boss.Position = shield.Position
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Block
	handle.Size = Vector3.new(0.15, 0.3, 0.15)
	handle.Color = Color3.fromRGB(80, 40, 0)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = shield.Position - Vector3.new(0, 0.3, 0)
end

function WeaponSystem:create_healing_hammer(weapon)
	-- Healing Hammer: support hammer
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Block
	head.Size = Vector3.new(0.4, 0.4, 0.4)
	head.Color = Color3.fromRGB(200, 200, 100)
	head.Material = Enum.Material.Metal
	head.CanCollide = false
	head.Parent = weapon
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Cylinder
	handle.Size = Vector3.new(0.12, 1, 0.12)
	handle.Color = Color3.fromRGB(100, 50, 0)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = head.Position - Vector3.new(0, 0.6, 0)
end

function WeaponSystem:create_runic_hammer(weapon)
	-- Runic Hammer: magical hammer
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Block
	head.Size = Vector3.new(0.45, 0.45, 0.45)
	head.Color = Color3.fromRGB(100, 50, 150)
	head.Material = Enum.Material.Metal
	head.CanCollide = false
	head.Parent = weapon
	
	local rune = Instance.new("Part")
	rune.Name = "Rune"
	rune.Shape = Enum.PartType.Block
	rune.Size = Vector3.new(0.2, 0.2, 0.2)
	rune.Color = Color3.fromRGB(200, 100, 255)
	rune.Material = Enum.Material.Neon
	rune.CanCollide = false
	rune.Parent = weapon
	rune.Position = head.Position
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Cylinder
	handle.Size = Vector3.new(0.15, 1.1, 0.15)
	handle.Color = Color3.fromRGB(50, 20, 50)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Parent = weapon
	handle.Position = head.Position - Vector3.new(0, 0.65, 0)
end

-- ===== SECONDARY RANGED WEAPONS (for melee classes) =====
function WeaponSystem:create_orc_bow(weapon)
	-- Orc Bow: powerful bow
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Shape = Enum.PartType.Cylinder
	frame.Size = Vector3.new(0.2, 2.5, 0.2)
	frame.Color = Color3.fromRGB(100, 50, 0)
	frame.Material = Enum.Material.Wood
	frame.CanCollide = false
	frame.Parent = weapon
	
	local bowstring = Instance.new("Part")
	bowstring.Name = "Bowstring"
	bowstring.Shape = Enum.PartType.Block
	bowstring.Size = Vector3.new(0.1, 2.3, 0.1)
	bowstring.Color = Color3.fromRGB(220, 220, 220)
	bowstring.Material = Enum.Material.Fabric
	bowstring.CanCollide = false
	bowstring.Parent = weapon
	bowstring.Position = frame.Position + Vector3.new(0.25, 0, 0)
	
	local grip = Instance.new("Part")
	grip.Name = "Grip"
	grip.Shape = Enum.PartType.Block
	grip.Size = Vector3.new(0.35, 0.4, 0.35)
	grip.Color = Color3.fromRGB(80, 40, 0)
	grip.Material = Enum.Material.Wood
	grip.CanCollide = false
	grip.Parent = weapon
	grip.Position = frame.Position
end

function WeaponSystem:create_orc_cannon(weapon)
	-- Orc Cannon: heavy cannon
	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Shape = Enum.PartType.Cylinder
	barrel.Size = Vector3.new(0.5, 3.2, 0.5)
	barrel.Color = Color3.fromRGB(60, 60, 60)
	barrel.Material = Enum.Material.Metal
	barrel.CanCollide = false
	barrel.Parent = weapon
	
	local muzzle = Instance.new("Part")
	muzzle.Name = "Muzzle"
	muzzle.Shape = Enum.PartType.Cylinder
	muzzle.Size = Vector3.new(0.6, 0.4, 0.6)
	muzzle.Color = Color3.fromRGB(80, 80, 80)
	muzzle.Material = Enum.Material.Metal
	muzzle.CanCollide = false
	muzzle.Parent = weapon
	muzzle.Position = barrel.Position + Vector3.new(0, 1.7, 0)
	
	local stock = Instance.new("Part")
	stock.Name = "Stock"
	stock.Shape = Enum.PartType.Block
	stock.Size = Vector3.new(0.6, 1, 1.8)
	stock.Color = Color3.fromRGB(40, 40, 40)
	stock.Material = Enum.Material.Metal
	stock.CanCollide = false
	stock.Parent = weapon
	stock.Position = barrel.Position - Vector3.new(0, 0.2, 1.2)
end

function WeaponSystem:create_orc_blaster(weapon)
	-- Orc Blaster: energy blaster
	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Shape = Enum.PartType.Cylinder
	barrel.Size = Vector3.new(0.35, 2.2, 0.35)
	barrel.Color = Color3.fromRGB(80, 80, 80)
	barrel.Material = Enum.Material.Metal
	barrel.CanCollide = false
	barrel.Parent = weapon
	
	local stock = Instance.new("Part")
	stock.Name = "Stock"
	stock.Shape = Enum.PartType.Block
	stock.Size = Vector3.new(0.5, 0.7, 1.3)
	stock.Color = Color3.fromRGB(50, 50, 50)
	stock.Material = Enum.Material.Metal
	stock.CanCollide = false
	stock.Parent = weapon
	stock.Position = barrel.Position - Vector3.new(0, 0, 0.9)
	
	local power_core = Instance.new("Part")
	power_core.Name = "PowerCore"
	power_core.Shape = Enum.PartType.Ball
	power_core.Size = Vector3.new(0.5, 0.5, 0.5)
	power_core.Color = Color3.fromRGB(255, 100, 0)
	power_core.Material = Enum.Material.Neon
	power_core.CanCollide = false
	power_core.Parent = weapon
	power_core.Position = barrel.Position - Vector3.new(0.4, 0.3, 0.6)
end

function WeaponSystem:create_chaos_staff(weapon)
	-- Chaos Staff: magical staff
	local staff = Instance.new("Part")
	staff.Name = "Staff"
	staff.Shape = Enum.PartType.Cylinder
	staff.Size = Vector3.new(0.2, 3, 0.2)
	staff.Color = Color3.fromRGB(100, 50, 150)
	staff.Material = Enum.Material.Metal
	staff.CanCollide = false
	staff.Parent = weapon
	
	local orb = Instance.new("Part")
	orb.Name = "Orb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(0.7, 0.7, 0.7)
	orb.Color = Color3.fromRGB(255, 50, 255)
	orb.Material = Enum.Material.Neon
	orb.CanCollide = false
	orb.Parent = weapon
	orb.Position = staff.Position + Vector3.new(0, 1.6, 0)
	
	local grip = Instance.new("Part")
	grip.Name = "Grip"
	grip.Shape = Enum.PartType.Block
	grip.Size = Vector3.new(0.3, 0.5, 0.3)
	grip.Color = Color3.fromRGB(50, 20, 50)
	grip.Material = Enum.Material.Metal
	grip.CanCollide = false
	grip.Parent = weapon
	grip.Position = staff.Position - Vector3.new(0, 1.2, 0)
end

function WeaponSystem:create_secondary_weapon_model(race, class_type, parent)
	local weapon = Instance.new("Model")
	local weapon_key = race .. "_" .. class_type
	local weapon_data = WEAPONS[weapon_key] or WEAPONS.human_dps
	local secondary_name = weapon_data.melee or weapon_data.ranged or "Secondary Weapon"
	weapon.Name = secondary_name
	weapon.Parent = parent
	
	-- Create secondary weapon based on race/class
	if race == "human" then
		if class_type == "dps" then
			self:create_combat_knife(weapon)
		elseif class_type == "tank" then
			self:create_energy_shield(weapon)
		elseif class_type == "support" then
			self:create_healing_rod(weapon)
		elseif class_type == "mage" then
			self:create_arcane_dagger(weapon)
		end
	elseif race == "elf" then
		if class_type == "dps" then
			self:create_elven_blade(weapon)
		elseif class_type == "tank" then
			self:create_elven_sword(weapon)
		elseif class_type == "support" then
			self:create_healing_dagger(weapon)
		elseif class_type == "mage" then
			self:create_arcane_blade(weapon)
		end
	elseif race == "dwarf" then
		if class_type == "dps" then
			self:create_dwarven_pickaxe(weapon)
		elseif class_type == "tank" then
			self:create_dwarven_shield(weapon)
		elseif class_type == "support" then
			self:create_healing_hammer(weapon)
		elseif class_type == "mage" then
			self:create_runic_hammer(weapon)
		end
	elseif race == "orc" then
		if class_type == "dps" then
			self:create_orc_bow(weapon)
		elseif class_type == "tank" then
			self:create_orc_cannon(weapon)
		elseif class_type == "support" then
			self:create_orc_blaster(weapon)
		elseif class_type == "mage" then
			self:create_chaos_staff(weapon)
		end
	else
		self:create_combat_knife(weapon)
	end
	
	-- Set primary part
	local first_part = weapon:FindFirstChildOfClass("Part")
	if first_part then
		weapon.PrimaryPart = first_part
	end
	
	return weapon
end

function WeaponSystem.get_weapon_stats(race)
	return WEAPONS[race] or WEAPONS.human_dps
end

return WeaponSystem
