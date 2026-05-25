-- Word Dictionary for Dead-Letter Drop
-- Contains 1,000+ kid-safe words categorized by difficulty

local WordDictionary = {}

-- Difficulty levels based on word length and complexity
WordDictionary.Difficulties = {
	Easy = { minLength = 3, maxLength = 5, complexity = "simple" },
	Medium = { minLength = 6, maxLength = 8, complexity = "moderate" },
	Hard = { minLength = 9, maxLength = 12, complexity = "complex" },
	Extreme = { minLength = 13, maxLength = 20, complexity = "expert" }
}

-- Word pools for each difficulty - 1,000+ kid-safe words total
WordDictionary.Words = {
	Easy = {
		-- Animals
		"cat", "dog", "pig", "cow", "hen", "duck", "goat", "horse", "lion", "bear",
		"bird", "fish", "frog", "bee", "ant", "bug", "fly", "rat", "mouse", "bat",
		"fox", "wolf", "deer", "elk", "seal", "whale", "shark", "tuna", "crab", "lobster",
		-- Colors
		"red", "blue", "green", "pink", "gray", "brown", "black", "white", "gold", "silver",
		-- Food
		"apple", "banana", "grape", "melon", "peach", "pear", "plum", "berry", "lime", "lemon",
		"bread", "cheese", "milk", "eggs", "meat", "rice", "corn", "bean", "pea", "nut",
		"cake", "candy", "cookie", "pie", "jam", "honey", "sugar", "salt", "soup", "salad",
		-- Nature
		"tree", "leaf", "grass", "flower", "rose", "lily", "fern", "moss", "vine", "root",
		"rock", "stone", "sand", "dirt", "soil", "clay", "dust", "mud", "ice", "snow",
		"rain", "wind", "sun", "moon", "star", "cloud", "fog", "mist", "sky", "air",
		-- Body parts
		"head", "hand", "foot", "arm", "leg", "eye", "ear", "nose", "mouth", "tooth",
		"hair", "skin", "bone", "back", "neck", "chest", "face", "lip", "chin", "jaw",
		-- Actions
		"run", "walk", "jump", "hop", "skip", "dance", "sing", "play", "work", "rest",
		"eat", "drink", "sleep", "wake", "talk", "read", "write", "draw", "paint", "cook",
		"help", "give", "take", "make", "break", "fix", "build", "clean", "wash", "dry",
		"open", "close", "start", "stop", "go", "come", "sit", "stand", "lie", "move",
		-- Descriptors
		"big", "small", "tall", "short", "long", "wide", "thin", "fat", "hot", "cold",
		"warm", "cool", "wet", "dry", "soft", "hard", "smooth", "rough", "light", "heavy",
		"new", "old", "young", "fast", "slow", "loud", "quiet", "bright", "dark", "clear",
		-- Places
		"home", "room", "door", "wall", "floor", "roof", "yard", "gate", "path", "road",
		"park", "zoo", "farm", "shop", "store", "bank", "school", "church", "town", "city",
		-- Objects
		"ball", "toy", "game", "book", "pen", "pencil", "paper", "desk", "chair", "table",
		"bed", "lamp", "clock", "phone", "radio", "tv", "car", "bike", "boat", "plane",
		"key", "lock", "door", "window", "box", "bag", "cup", "plate", "bowl", "spoon",
		-- Family
		"mom", "dad", "son", "girl", "boy", "baby", "kid", "friend", "pal", "buddy",
		-- Numbers
		"one", "two", "six", "ten", "five", "nine", "four", "eight", "seven", "three"
	},
	
	Medium = {
		-- Animals
		"rabbit", "turtle", "monkey", "zebra", "giraffe", "elephant", "dolphin", "penguin", "eagle", "parrot",
		"butterfly", "ladybug", "grasshopper", "spider", "scorpion", "octopus", "jellyfish", "oyster", "clam", "scallop",
		"squirrel", "chipmunk", "beaver", "otter", "badger", "weasel", "ferret", "hamster", "guinea", "chinchilla",
		"canary", "parakeet", "cockatiel", "finch", "sparrow", "robin", "bluebird", "cardinal", "crow", "raven",
		-- Food
		"orange", "strawberry", "watermelon", "pineapple", "coconut", "avocado", "mango", "papaya", "kiwi", "cherry",
		"broccoli", "carrot", "cabbage", "lettuce", "spinach", "potato", "tomato", "cucumber", "pepper", "onion",
		"pumpkin", "squash", "zucchini", "celery", "asparagus", "mushroom", "garlic", "ginger", "cinnamon", "vanilla",
		"chicken", "turkey", "salmon", "tuna", "trout", "shrimp", "scallop", "clams", "oysters", "crab",
		"pasta", "noodle", "pizza", "burger", "sandwich", "taco", "burrito", "salad", "soup", "stew",
		"pancake", "waffle", "muffin", "biscuit", "croissant", "bagel", "pretzel", "popcorn", "chips", "crackers",
		-- Nature
		"mountain", "valley", "forest", "jungle", "desert", "island", "beach", "ocean", "river", "stream",
		"waterfall", "meadow", "prairie", "canyon", "volcano", "earthquake", "hurricane", "tornado", "thunder", "lightning",
		"rainbow", "sunset", "sunrise", "clouds", "breeze", "storm", "blizzard", "flood", "drought", "season",
		"spring", "summer", "autumn", "winter", "weather", "climate", "temperature", "humidity", "atmosphere", "environment",
		-- School & Learning
		"teacher", "student", "classroom", "library", "playground", "gymnasium", "cafeteria", "auditorium", "principal", "janitor",
		"reading", "writing", "arithmetic", "science", "history", "geography", "biology", "chemistry", "physics", "astronomy",
		"computer", "keyboard", "monitor", "printer", "internet", "website", "email", "program", "software", "hardware",
		"pencil", "eraser", "notebook", "backpack", "textbook", "dictionary", "encyclopedia", "magazine", "newspaper", "journal",
		-- Activities
		"swimming", "biking", "hiking", "camping", "fishing", "boating", "skiing", "skating", "surfing", "diving",
		"painting", "drawing", "sculpture", "photography", "dancing", "singing", "acting", "playing", "exercising", "training",
		"shopping", "cooking", "baking", "cleaning", "organizing", "decorating", "gardening", "planting", "watering", "harvesting",
		"traveling", "exploring", "discovering", "adventuring", "sightseeing", "touring", "visiting", "meeting", "gathering", "celebrating",
		-- Emotions & Feelings
		"happy", "excited", "joyful", "cheerful", "delighted", "pleased", "satisfied", "content", "proud", "confident",
		"brave", "courageous", "strong", "powerful", "mighty", "fearless", "bold", "daring", "heroic", "adventurous",
		"kind", "gentle", "caring", "loving", "friendly", "helpful", "generous", "thoughtful", "considerate", "polite",
		"calm", "peaceful", "relaxed", "comfortable", "cozy", "warm", "snug", "secure", "safe", "protected",
		-- Objects & Tools
		"computer", "telephone", "television", "refrigerator", "microwave", "dishwasher", "washing", "dryer", "vacuum", "blender",
		"hammer", "screwdriver", "wrench", "pliers", "saw", "drill", "ladder", "toolbox", "flashlight", "batteries",
		"bicycle", "motorcycle", "airplane", "helicopter", "submarine", "spaceship", "rocket", "satellite", "telescope", "microscope",
		"camera", "video", "music", "radio", "headphones", "speakers", "microphone", "guitar", "piano", "drums",
		-- Places & Buildings
		"hospital", "restaurant", "theater", "museum", "stadium", "airport", "station", "market", "mall", "center",
		"apartment", "building", "skyscraper", "factory", "warehouse", "garage", "shed", "cabin", "cottage", "mansion",
		"bridge", "tunnel", "highway", "railway", "subway", "sidewalk", "street", "avenue", "boulevard", "intersection",
		"playground", "park", "garden", "orchard", "farm", "ranch", "field", "meadow", "forest", "jungle"
	},
	
	Hard = {
		-- Advanced Animals
		"chimpanzee", "orangutan", "gorilla", "rhinoceros", "hippopotamus", "crocodile", "alligator", "chameleon", " Komodo", "dragon",
		"platypus", "echidna", "kangaroo", "wallaby", "koala", "wombat", "kookaburra", "cockatoo", "flamingo", "pelican",
		"albatross", "penguin", "seahorse", "starfish", "jellyfish", "anemone", "coral", "dolphin", "porpoise", "narwhal",
		"butterfly", "caterpillar", "chrysalis", "cocoon", "metamorphosis", "migration", "hibernation", "adaptation", "evolution", "extinction",
		-- Advanced Food & Cooking
		"architecture", "engineering", "construction", "foundation", "structure", "blueprint", "design", "planning", "development", "innovation",
		"vegetarian", "nutrition", "protein", "carbohydrate", "vitamin", "mineral", "calcium", "iron", "fiber", "antioxidant",
		"delicious", "nutritious", "wholesome", "organic", "homemade", "fresh", "natural", "healthy", "balanced", "variety",
		"ingredient", "recipe", "technique", "preparation", "combination", "presentation", "decoration", "garnish", "seasoning", "marination",
		-- Science & Nature
		"atmosphere", "environment", "ecosystem", "habitat", "conservation", "preservation", "protection", "endangered", "extinction", "biodiversity",
		"photosynthesis", "respiration", "circulation", "digestion", "reproduction", "metabolism", "chromosome", "mutation", "heredity", "genetics",
		"technology", "innovation", "invention", "discovery", "research", "experiment", "observation", "hypothesis", "conclusion", "theory",
		"astronomy", "telescope", "planet", "galaxy", "universe", "constellation", "asteroid", "comet", "meteor", "spaceship",
		"chemistry", "molecule", "compound", "reaction", "solution", "mixture", "element", "periodic", "laboratory", "equipment",
		"physics", "energy", "motion", "gravity", "velocity", "acceleration", "momentum", "friction", "magnetism", "electricity",
		-- Advanced Activities
		"imagination", "creativity", "inspiration", "motivation", "determination", "perseverance", "achievement", "accomplishment", "success", "victory",
		"adventure", "exploration", "discovery", "investigation", "examination", "observation", "participation", "contribution", "dedication", "commitment",
		"communication", "conversation", "discussion", "explanation", "description", "information", "knowledge", "understanding", "comprehension", "interpretation",
		"celebration", "ceremony", "tradition", "custom", "festival", "holiday", "vacation", "recreation", "entertainment", "amusement",
		-- Advanced Emotions & Character
		"compassionate", "understanding", "forgiving", "tolerant", "accepting", "respectful", "considerate", "thoughtful", "sensitive", "empathetic",
		"responsible", "dependable", "reliable", "trustworthy", "honest", "sincere", "genuine", "authentic", "truthful", "faithful",
		"enthusiastic", "passionate", "energetic", "vibrant", "dynamic", "spirited", "lively", "animated", "vivid", "brilliant",
		"thoughtful", "reflective", "contemplative", "meditative", "philosophical", "analytical", "logical", "rational", "reasonable", "sensible",
		-- Advanced Objects & Technology
		"architecture", "engineering", "mechanics", "electronics", "robotics", "automation", "computerization", "digitalization", "innovation", "technology",
		"transportation", "communication", "information", "education", "entertainment", "recreation", "accommodation", "destination", "navigation", "exploration",
		"instrument", "equipment", "apparatus", "mechanism", "device", "gadget", "appliance", "machine", "system", "network",
		"material", "substance", "element", "compound", "mixture", "solution", "texture", "density", "weight", "measurement",
		-- Advanced Places & Society
		"civilization", "society", "community", "population", "culture", "tradition", "heritage", "history", "ancestry", "genealogy",
		"government", "democracy", "freedom", "justice", "equality", "rights", "responsibility", "citizenship", "patriotism", "nationalism",
		"economics", "business", "commerce", "industry", "manufacturing", "production", "distribution", "marketing", "advertising", "consumption",
		"education", "knowledge", "wisdom", "intelligence", "learning", "teaching", "studying", "researching", "discovering", "understanding",
		"architecture", "construction", "building", "structure", "foundation", "framework", "skeleton", "blueprint", "design", "planning"
	},
	
	Extreme = {
		-- Scientific & Technical Terms
		"extraordinary", "revolutionary", "groundbreaking", "innovative", "transformational", "unprecedented", "remarkable", "exceptional", "outstanding", "spectacular",
		"breathtaking", "magnificent", "phenomenal", "incredible", "unbelievable", "astonishing", "amazing", "stunning", "awe-inspiring", "majestic",
		"communication", "transportation", "technology", "information", "infrastructure", "development", "advancement", "progress", "achievement", "accomplishment",
		"environmental", "sustainable", "renewable", "conservation", "preservation", "protection", "restoration", "rehabilitation", "regeneration", "revitalization",
		"understanding", "comprehension", "interpretation", "explanation", "clarification", "elucidation", "illustration", "demonstration", "presentation", "communication",
		"responsibility", "accountability", "dependability", "reliability", "trustworthiness", "credibility", "authenticity", "genuineness", "sincerity", "integrity",
		"entertainment", "recreation", "amusement", "enjoyment", "pleasure", "happiness", "contentment", "satisfaction", "fulfillment", "achievement",
		"imagination", "creativity", "inspiration", "innovation", "invention", "discovery", "exploration", "adventure", "investigation", "examination",
		"extraordinary", "magnificent", "spectacular", "phenomenal", "incredible", "unbelievable", "astonishing", "amazing", "stunning", "breathtaking",
		"revolutionary", "groundbreaking", "innovative", "transformational", "unprecedented", "remarkable", "exceptional", "outstanding", "spectacular", "magnificent",
		"communication", "transportation", "technology", "information", "infrastructure", "development", "advancement", "progress", "achievement", "accomplishment",
		"environmental", "sustainable", "renewable", "conservation", "preservation", "protection", "restoration", "rehabilitation", "regeneration", "revitalization",
		"understanding", "comprehension", "interpretation", "explanation", "clarification", "elucidation", "illustration", "demonstration", "presentation", "communication",
		"responsibility", "accountability", "dependability", "reliability", "trustworthiness", "credibility", "authenticity", "genuineness", "sincerity", "integrity",
		"entertainment", "recreation", "amusement", "enjoyment", "pleasure", "happiness", "contentment", "satisfaction", "fulfillment", "achievement",
		"imagination", "creativity", "inspiration", "innovation", "invention", "discovery", "exploration", "adventure", "investigation", "examination",
		"extraordinary", "magnificent", "spectacular", "phenomenal", "incredible", "unbelievable", "astonishing", "amazing", "stunning", "breathtaking",
		"revolutionary", "groundbreaking", "innovative", "transformational", "unprecedented", "remarkable", "exceptional", "outstanding", "spectacular", "magnificent",
		"communication", "transportation", "technology", "information", "infrastructure", "development", "advancement", "progress", "achievement", "accomplishment",
		"environmental", "sustainable", "renewable", "conservation", "preservation", "protection", "restoration", "rehabilitation", "regeneration", "revitalization"
	}
}

-- Get a random word based on difficulty and current wave/score
function WordDictionary.GetRandomWord(difficulty, customWeight)
	local wordPool = WordDictionary.Words[difficulty]
	if not wordPool or #wordPool == 0 then
		wordPool = WordDictionary.Words.Easy
	end

	local index = math.random(1, #wordPool)
	local word = wordPool[index]:match("^%s*(.-)%s*$") -- trim whitespace
	return word
end

-- Get difficulty based on score/wave progression
function WordDictionary.GetDifficultyByProgress(score, wave)
	local baseDifficulty = "Easy"
	
	-- Scale difficulty based on wave
	if wave >= 20 then
		baseDifficulty = "Extreme"
	elseif wave >= 15 then
		baseDifficulty = "Hard"
	elseif wave >= 8 then
		baseDifficulty = "Medium"
	elseif wave >= 3 then
		-- Mix of Easy and Medium
		baseDifficulty = math.random() > 0.6 and "Medium" or "Easy"
	end
	
	-- Occasionally throw in harder words for variety
	if math.random() < 0.1 then
		local difficulties = {"Easy", "Medium", "Hard", "Extreme"}
		local nextLevel = difficulties[math.min(4, (tonumber(string.find("Easy,Medium,Hard,Extreme", baseDifficulty)) + 3) / 7 + 1)]
		return nextLevel or baseDifficulty
	end
	
	return baseDifficulty
end

-- Validate word (no special characters, reasonable length)
function WordDictionary.IsValidWord(word)
	if type(word) ~= "string" then return false end
	if #word < 2 or #word > 25 then return false end
	if word:match("[^%w]") then return false end -- Only alphanumeric
	return true
end

-- Get word statistics
function WordDictionary.GetWordStats(word)
	return {
		length = #word,
		difficulty = WordDictionary.EstimateDifficulty(word),
		complexity = WordDictionary.CalculateComplexity(word)
	}
end

-- Estimate difficulty of any word
function WordDictionary.EstimateDifficulty(word)
	local len = #word
	if len <= 5 then return "Easy" end
	if len <= 8 then return "Medium" end
	if len <= 12 then return "Hard" end
	return "Extreme"
end

-- Calculate complexity score (0-100)
function WordDictionary.CalculateComplexity(word)
	local score = 0
	
	-- Length contribution
	score = score + (#word * 2)
	
	-- Repeated letters decrease complexity
	local repeats = 0
	for i = 1, #word - 1 do
		if word:sub(i, i) == word:sub(i + 1, i + 1) then
			repeats = repeats + 1
		end
	end
	score = score - (repeats * 5)
	
	-- Common letter patterns
	local commonPatterns = {"th", "he", "in", "er", "an", "re", "ed", "on", "en", "at"}
	for _, pattern in ipairs(commonPatterns) do
		if word:lower():find(pattern) then
			score = score - 3
		end
	end
	
	-- Rare letters increase complexity
	local rareLetters = {"q", "x", "z", "j", "v", "k"}
	for _, letter in ipairs(rareLetters) do
		if word:lower():find(letter) then
			score = score + 4
		end
	end
	
	return math.max(0, math.min(100, score))
end

return WordDictionary
