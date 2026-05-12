local LoreDatabase = {}

-- Lore type emojis
local LORE_TYPE_EMOJIS = {
	book = "📖",
	scroll = "📜",
	sign = "🪧",
	gravestone = "🪦",
	note = "📝",
	tablet = "📱",
	journal = "📕",
	letter = "💌",
	crystal = "🔮"
}

-- Lore source/category emojis
local LORE_CATEGORY_EMOJIS = {
	the_world = "🌍",
	human_history = "👨",
	elven_history = "🧝",
	dwarven_history = "⛏️",
	orc_history = "🗡️",
	goblin_tales = "👺",
	the_necrogenesis = "☠️",
	lucifer_hades = "😈",
	the_gods = "⚡",
	the_undead = "🧟",
	safespaces = "✨",
	personal_accounts = "💭",
	weapons_tech = "🔫",
	humor = "😄"
}

-- Rarity colors
local RARITY_COLORS = {
	common = Color3.fromRGB(200, 200, 200),
	uncommon = Color3.fromRGB(100, 200, 100),
	rare = Color3.fromRGB(100, 150, 255),
	epic = Color3.fromRGB(200, 100, 255),
	legendary = Color3.fromRGB(255, 200, 100)
}

function LoreDatabase.get_type_emoji(lore_type)
	return LORE_TYPE_EMOJIS[lore_type] or "📄"
end

function LoreDatabase.get_category_emoji(category)
	return LORE_CATEGORY_EMOJIS[category] or "📚"
end

function LoreDatabase.get_rarity_color(rarity)
	return RARITY_COLORS[rarity] or Color3.fromRGB(200, 200, 200)
end

function LoreDatabase.get_all_categories()
	local categories = {}
	for cat, _ in pairs(LORE_CATEGORY_EMOJIS) do
		table.insert(categories, cat)
	end
	table.sort(categories)
	return categories
end

function LoreDatabase.get_all_types()
	local types = {}
	for typ, _ in pairs(LORE_TYPE_EMOJIS) do
		table.insert(types, typ)
	end
	table.sort(types)
	return types
end

return LoreDatabase
