-- Server-side game state: score, wave, defeated words, player ready tracking

local GameState = {}

GameState.isRunning     = false
GameState.hasEverStarted = false
GameState.currentWave   = 1
GameState.score         = 0
GameState.startTime     = 0
GameState.playersReady  = {}
GameState.defeatedWords = {}

function GameState.Reset()
	GameState.isRunning    = true
	GameState.hasEverStarted = true
	GameState.currentWave  = 1
	GameState.score        = 0
	GameState.defeatedWords = {}
	GameState.playersReady  = {}
	GameState.startTime    = tick()
end

function GameState.AddDefeatedWord(word, playerName, wave)
	if word and not GameState.defeatedWords[word] then
		GameState.defeatedWords[word] = {
			word      = word,
			defeatedBy = playerName,
			time      = tick(),
			wave      = wave
		}
	end
end

function GameState.GetDefeatedWordsList()
	local list = {}
	for _, data in pairs(GameState.defeatedWords) do
		table.insert(list, data)
	end
	table.sort(list, function(a, b) return a.word < b.word end)
	return list
end

return GameState
