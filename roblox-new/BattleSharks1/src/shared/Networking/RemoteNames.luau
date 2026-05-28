-- BattleSharks Remote Event Names
-- Centralized naming for all network communications

local RemoteNames = {}

-- CLIENT TO SERVER EVENTS
RemoteNames.ClientToServer = {
	-- Player Actions
	PlayerSpawn = "PlayerSpawn",
	PlayerMove = "PlayerMove",
	PlayerAttack = "PlayerAttack",
	PlayerBoost = "PlayerBoost",
	PlayerInteract = "PlayerInteract",
	
	-- Game Systems
	FeedShark = "FeedShark",
	CleanAquarium = "CleanAquarium",
	ApplyMutation = "ApplyMutation",
	ChangeClass = "ChangeClass",
	UseItem = "UseItem",
	BuyItem = "BuyItem",
	SellItem = "SellItem",
	
	-- Inventory Management
	MoveItem = "MoveItem",
	EquipItem = "EquipItem",
	UnequipItem = "UnequipItem",
	
	-- Aquarium Management
	PlaceDecoration = "PlaceDecoration",
	RemoveDecoration = "RemoveDecoration",
	ChangeBackground = "ChangeBackground",
	
	-- Social Systems
	SendFriendRequest = "SendFriendRequest",
	AcceptFriendRequest = "AcceptFriendRequest",
	DeclineFriendRequest = "DeclineFriendRequest",
	JoinGuild = "JoinGuild",
	LeaveGuild = "LeaveGuild",
	
	-- Daily Systems
	ClaimDailyReward = "ClaimDailyReward",
	ClaimWeeklyReward = "ClaimWeeklyReward",
	
	-- Save Systems
	SaveGameData = "SaveGameData",
	LoadGameData = "LoadGameData"
}

-- SERVER TO CLIENT EVENTS
RemoteNames.ServerToClient = {
	-- Game State Updates
	UpdatePlayerStats = "UpdatePlayerStats",
	UpdateHunger = "UpdateHunger",
	UpdateHealth = "UpdateHealth",
	UpdateXP = "UpdateXP",
	UpdateLevel = "UpdateLevel",
	UpdateGold = "UpdateGold",
	UpdateCrystals = "UpdateCrystals",
	
	-- World Updates
	EnemySpawned = "EnemySpawned",
	EnemyDespawned = "EnemyDespawned",
	EnemyDied = "EnemyDied",
	ItemSpawned = "ItemSpawned",
	ItemDespawned = "ItemDespawned",
	ItemPickedUp = "ItemPickedUp",
	
	-- Ability Updates
	AbilityUsed = "AbilityUsed",
	AbilityCooldown = "AbilityCooldown",
	AbilityReady = "AbilityReady",
	
	-- Mutation Updates
	MutationApplied = "MutationApplied",
	MutationRemoved = "MutationRemoved",
	MutationExpired = "MutationExpired",
	
	-- Aquarium Updates
	AquariumStateChanged = "AquariumStateChanged",
	DecorationPlaced = "DecorationPlaced",
	DecorationRemoved = "DecorationRemoved",
	BackgroundChanged = "BackgroundChanged",
	
	-- UI Updates
	ShowNotification = "ShowNotification",
	HideNotification = "HideNotification",
	OpenUI = "OpenUI",
	CloseUI = "CloseUI",
	
	-- Social Updates
	FriendOnline = "FriendOnline",
	FriendOffline = "FriendOffline",
	GuildMessage = "GuildMessage",
	GuildMemberJoined = "GuildMemberJoined",
	GuildMemberLeft = "GuildMemberLeft",
	
	-- System Messages
	GameMessage = "GameMessage",
	Error = "Error",
	Success = "Success",
	Warning = "Warning"
}

-- REMOTE FUNCTIONS (CLIENT TO SERVER)
RemoteNames.ClientFunctions = {
	GetPlayerData = "GetPlayerData",
	GetInventory = "GetInventory",
	GetAquariumData = "GetAquariumData",
	GetShopItems = "GetShopItems",
	GetDailyRewards = "GetDailyRewards",
	GetFriendList = "GetFriendList",
	GetGuildData = "GetGuildData",
	ValidatePurchase = "ValidatePurchase",
	CanAffordItem = "CanAffordItem"
}

-- REMOTE FUNCTIONS (SERVER TO CLIENT)
RemoteNames.ServerFunctions = {
	GetClientPosition = "GetClientPosition",
	GetClientCamera = "GetClientCamera",
	PingClient = "PingClient",
	ValidateClient = "ValidateClient"
}

return RemoteNames
