-- BattleSharks Game Utilities
-- Common utility functions used across all systems

local GameConstants = require(script.Parent.Parent.Constants.GameConstants)
local GameEnums = require(script.Parent.Parent.Enums.GameEnums)

local GameUtilities = {}

-- MATH UTILITIES
function GameUtilities.Lerp(a, b, t)
	return a + (b - a) * t
end

function GameUtilities.Clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

function GameUtilities.RoundToDecimal(value, decimalPlaces)
	local multiplier = 10 ^ decimalPlaces
	return math.round(value * multiplier) / multiplier
end

function GameUtilities.RandomFloat(min, max)
	return math.random() * (max - min) + min
end

function GameUtilities.RandomBool(probability)
	probability = probability or 0.5
	return math.random() <= probability
end

function GameUtilities.RandomChoice(choices)
	if #choices == 0 then return nil end
	local index = math.random(1, #choices)
	return choices[index]
end

function GameUtilities.WeightedRandomChoice(choices)
	if #choices == 0 then return nil end
	
	local totalWeight = 0
	for _, choice in pairs(choices) do
		totalWeight += choice.Weight or 1
	end
	
	local randomValue = math.random() * totalWeight
	local currentWeight = 0
	
	for _, choice in pairs(choices) do
		currentWeight += choice.Weight or 1
		if randomValue <= currentWeight then
			return choice.Value or choice
		end
	end
	
	return choices[#choices].Value or choices[#choices]
end

-- VECTOR UTILITIES
function GameUtilities.GetDirection(from, to)
	local direction = (to - from).Unit
	return direction
end

function GameUtilities.GetDistance(from, to)
	return (from - to).Magnitude
end

function GameUtilities.GetDistanceSquared(from, to)
	local diff = from - to
	return diff:Dot(diff)
end

function GameUtilities.IsInRange(position, target, range)
	return GameUtilities.GetDistanceSquared(position, target) <= (range * range)
end

function GameUtilities.GetLookVectorFromRotation(rotation)
	return rotation * Vector3.new(0, 0, -1)
end

-- TIME UTILITIES
function GameUtilities.FormatTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	else
		return string.format("%d:%02d", minutes, secs)
	end
end

function GameUtilities.GetTimestamp()
	return os.time()
end

function GameUtilities.IsSameDay(timestamp1, timestamp2)
	local date1 = os.date("*t", timestamp1)
	local date2 = os.date("*t", timestamp2)
	return date1.day == date2.day and date1.month == date2.month and date1.year == date2.year
end

-- STRING UTILITIES
function GameUtilities.FormatNumber(number)
	if number >= 1000000 then
		return string.format("%.1fM", number / 1000000)
	elseif number >= 1000 then
		return string.format("%.1fK", number / 1000)
	else
		return tostring(math.floor(number))
	end
end

function GameUtilities.FormatCurrency(amount, currencyType)
	local formatted = GameUtilities.FormatNumber(amount)
	
	if currencyType == GameEnums.CurrencyType.GOLD then
		return formatted .. " 🪙"
	elseif currencyType == GameEnums.CurrencyType.CRYSTALS then
		return formatted .. " 💎"
	else
		return formatted
	end
end

function GameUtilities.TruncateString(text, maxLength)
	if #text <= maxLength then
		return text
	else
		return text:sub(1, maxLength - 3) .. "..."
	end
end

function GameUtilities.SplitString(text, delimiter)
	local result = {}
	local pattern = string.format("([^%s]+)", delimiter)
	
	for match in text:gmatch(pattern) do
		table.insert(result, match)
	end
	
	return result
end

-- TABLE UTILITIES
function GameUtilities.ShallowCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = value
	end
	return copy
end

function GameUtilities.DeepCopy(original)
	local copy = {}
	
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = GameUtilities.DeepCopy(value)
		else
			copy[key] = value
		end
	end
	
	return copy
end

function GameUtilities.ContainsKey(table, key)
	return table[key] ~= nil
end

function GameUtilities.ContainsValue(table, value)
	for _, v in pairs(table) do
		if v == value then
			return true
		end
	end
	return false
end

function GameUtilities.GetTableSize(table)
	local count = 0
	for _ in pairs(table) do
		count += 1
	end
	return count
end

function GameUtilities.ClearTable(table)
	for key in pairs(table) do
		table[key] = nil
	end
end

-- COLOR UTILITIES
function GameUtilities.LerpColor(color1, color2, t)
	local r = GameUtilities.Lerp(color1.R, color2.R, t)
	local g = GameUtilities.Lerp(color1.G, color2.G, t)
	local b = GameUtilities.Lerp(color1.B, color2.B, t)
	return Color3.new(r, g, b)
end

function GameUtilities.ColorToHex(color)
	return string.format("#%02X%02X%02X", 
		math.floor(color.R * 255),
		math.floor(color.G * 255),
		math.floor(color.B * 255)
	)
end

function GameUtilities.HexToColor(hex)
	hex = hex:gsub("#", "")
	local r = tonumber(hex:sub(1, 2), 16) / 255
	local g = tonumber(hex:sub(3, 4), 16) / 255
	local b = tonumber(hex:sub(5, 6), 16) / 255
	return Color3.new(r, g, b)
end

-- VALIDATION UTILITIES
function GameUtilities.IsValidPlayer(player)
	return player and player:IsA("Player")
end

function GameUtilities.IsValidCharacter(character)
	return character and character:IsA("Model") and character:FindFirstChild("Humanoid")
end

function GameUtilities.IsValidHumanoid(humanoid)
	return humanoid and humanoid:IsA("Humanoid")
end

function GameUtilities.IsPlayerInOcean(character)
	if not character then return false end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	return humanoidRootPart.Position.Y <= GameConstants.WATER_LEVEL
end

-- DAMAGE CALCULATION UTILITIES
function GameUtilities.CalculateDamage(baseDamage, damageMultiplier, criticalChance, criticalMultiplier)
	damageMultiplier = damageMultiplier or 1
	criticalChance = criticalChance or 0
	criticalMultiplier = criticalMultiplier or 2
	
	local damage = baseDamage * damageMultiplier
	
	-- Check for critical hit
	if math.random() <= criticalChance then
		damage *= criticalMultiplier
	end
	
	return math.floor(damage)
end

function GameUtilities.ApplyDamageReduction(damage, reductionPercent)
	reductionPercent = GameUtilities.Clamp(reductionPercent, 0, 1)
	return damage * (1 - reductionPercent)
end

-- XP CALCULATION UTILITIES
function GameUtilities.CalculateXPForLevel(level)
	return GameConstants.XP_PER_LEVEL * (level ^ 1.5)
end

function GameUtilities.CalculateXPProgress(currentXP, level)
	local xpForCurrentLevel = GameUtilities.CalculateXPForLevel(level)
	local xpForNextLevel = GameUtilities.CalculateXPForLevel(level + 1)
	local xpNeeded = xpForNextLevel - xpForCurrentLevel
	local xpProgress = currentXP - xpForCurrentLevel
	
	return GameUtilities.Clamp(xpProgress / xpNeeded, 0, 1)
end

-- PERFORMANCE UTILITIES
function GameUtilities.CreateDebounce(cooldownTime)
	local lastExecution = 0
	
	return function()
		local currentTime = tick()
		if currentTime - lastExecution >= cooldownTime then
			lastExecution = currentTime
			return true
		end
		return false
	end
end

function GameUtilities.Throttle(functionToThrottle, delay)
	local isThrottled = false
	
	return function(...)
		if isThrottled then return end
		
		isThrottled = true
		task.spawn(functionToThrottle, ...)
		
		task.delay(delay, function()
			isThrottled = false
		end)
	end
end

-- DEBUG UTILITIES
function GameUtilities.DebugPrint(message, category)
	category = category or "General"
	
	if GameConstants.DEBUG_MODE then
		print(string.format("[%s] %s", category, message))
	end
end

function GameUtilities.LogWarning(message, category)
	category = category or "Warning"
	warn(string.format("[%s] %s", category, message))
end

function GameUtilities.LogError(message, category)
	category = category or "Error"
	error(string.format("[%s] %s", category, message))
end

return GameUtilities
