extends Node

# Dialogue Manager - manages all dialogue, voice synthesis, and speech bubbles

class_name DialogueManager

signal dialogue_started(speaker: String, text: String)
signal dialogue_finished(speaker: String)
signal voice_playing(speaker: String)
signal voice_finished(speaker: String)

const ELEVENLABS_API_URL: String = "https://api.elevenlabs.io/v1/text-to-speech"
const OPENAI_API_URL: String = "https://api.openai.com/v1/chat/completions"

var elevenlabs_api_key: String = ""
var openai_api_key: String = ""
var use_ai_generation: bool = false

var active_dialogues: Dictionary = {}
var voice_cache: Dictionary = {}
var http_request: HTTPRequest = null

var speech_bubble_scene: PackedScene = null
var voice_profiles: Dictionary = {}

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	_load_api_keys()
	_initialize_voice_profiles()

func _load_api_keys() -> void:
	var config_file = ConfigFile.new()
	var err = config_file.load("user://api_keys.cfg")
	if err == OK:
		elevenlabs_api_key = config_file.get_value("apis", "elevenlabs_key", "")
		openai_api_key = config_file.get_value("apis", "openai_key", "")
		use_ai_generation = config_file.get_value("dialogue", "use_ai", false)

func _initialize_voice_profiles() -> void:
	voice_profiles = {
		"player": {
			"voice_id": "EXAVITQu4vr4xnSDxMaL",
			"name": "Player",
			"stability": 0.5,
			"similarity_boost": 0.75,
		},
		"goblin": {
			"voice_id": "IZSifUOsW53CPDnqqIHc",
			"name": "Goblin",
			"stability": 0.6,
			"similarity_boost": 0.7,
		},
		"orc": {
			"voice_id": "g5CIjZEefAQXax5SlqNe",
			"name": "Orc",
			"stability": 0.7,
			"similarity_boost": 0.65,
		},
		"skeleton": {
			"voice_id": "nPczCjzI2devNBz1zQrb",
			"name": "Skeleton",
			"stability": 0.8,
			"similarity_boost": 0.6,
		},
		"boss": {
			"voice_id": "5Q0KzCMw5DDiSgEgsKB2",
			"name": "Boss",
			"stability": 0.75,
			"similarity_boost": 0.7,
		},
	}

func speak(speaker: String, text: String, speaker_type: String = "player", position: Vector2 = Vector2.ZERO) -> void:
	if text.is_empty():
		return
	
	dialogue_started.emit(speaker, text)
	
	# Show speech bubble
	_show_speech_bubble(speaker, text, position)
	
	# Play voice if API key available
	if not elevenlabs_api_key.is_empty():
		_synthesize_and_play_voice(speaker, text, speaker_type)

func _show_speech_bubble(speaker: String, text: String, position: Vector2) -> void:
	var bubble = _create_speech_bubble(speaker, text, position)
	if bubble:
		add_child(bubble)
		active_dialogues[speaker] = bubble
		
		await get_tree().create_timer(2.0 + (text.length() * 0.05)).timeout
		if bubble and is_instance_valid(bubble):
			bubble.queue_free()
		active_dialogues.erase(speaker)
		dialogue_finished.emit(speaker)

func _create_speech_bubble(speaker: String, text: String, position: Vector2) -> Control:
	var bubble = Control.new()
	bubble.name = "SpeechBubble_%s" % speaker
	bubble.global_position = position + Vector2(0, -80)
	bubble.size = Vector2(200, 100)
	
	# Background panel
	var panel = PanelContainer.new()
	panel.size = bubble.size
	panel.modulate = Color(1, 1, 1, 0.95)
	bubble.add_child(panel)
	
	# Text label
	var label = Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(180, 80)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size = bubble.size - Vector2(20, 20)
	label.position = Vector2(10, 10)
	bubble.add_child(label)
	
	# Pointer triangle
	var pointer = Polygon2D.new()
	pointer.polygon = PackedVector2Array([
		Vector2(10, 0),
		Vector2(-10, 0),
		Vector2(0, 15)
	])
	pointer.color = Color(0.9, 0.9, 0.9, 0.95)
	pointer.position = Vector2(100, bubble.size.y)
	bubble.add_child(pointer)
	
	return bubble

func _synthesize_and_play_voice(speaker: String, text: String, speaker_type: String) -> void:
	if not voice_profiles.has(speaker_type):
		speaker_type = "player"
	
	var voice_profile = voice_profiles[speaker_type]
	var cache_key = "%s_%s" % [speaker_type, text.hash()]
	
	# Check cache first
	if voice_cache.has(cache_key):
		_play_cached_voice(speaker, voice_cache[cache_key])
		return
	
	# Request voice synthesis
	var url = "%s/%s" % [ELEVENLABS_API_URL, voice_profile["voice_id"]]
	var headers = [
		"xi-api-key: %s" % elevenlabs_api_key,
		"Content-Type: application/json"
	]
	
	var body = {
		"text": text,
		"model_id": "eleven_monolingual_v1",
		"voice_settings": {
			"stability": voice_profile["stability"],
			"similarity_boost": voice_profile["similarity_boost"]
		}
	}
	
	var json_body = JSON.stringify(body)
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	
	var response = await http_request.request_completed
	if response[0] == OK and response[1] == 200:
		var audio_data = response[3]
		voice_cache[cache_key] = audio_data
		_play_cached_voice(speaker, audio_data)

func _play_cached_voice(speaker: String, audio_data: PackedByteArray) -> void:
	var audio_stream = AudioStreamMP3.new()
	audio_stream.data = audio_data
	
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = audio_stream
	audio_player.bus = "Master"
	add_child(audio_player)
	audio_player.play()
	
	voice_playing.emit(speaker)
	await audio_player.finished
	voice_finished.emit(speaker)
	audio_player.queue_free()

func generate_dialogue(context: String, character_type: String, situation: String) -> String:
	if use_ai_generation and not openai_api_key.is_empty():
		return await _generate_with_gpt(context, character_type, situation)
	else:
		return _generate_with_rules(character_type, situation)

func _generate_with_gpt(context: String, character_type: String, situation: String) -> String:
	var prompt = "You are a %s in a dungeon crawler game. %s. Respond with a single short line (max 15 words) that the character would say. Be dramatic and fitting for the situation." % [character_type, situation]
	
	var headers = [
		"Authorization: Bearer %s" % openai_api_key,
		"Content-Type: application/json"
	]
	
	var body = {
		"model": "gpt-4o-mini",
		"messages": [
			{
				"role": "user",
				"content": prompt
			}
		],
		"max_tokens": 50,
		"temperature": 0.8
	}
	
	var json_body = JSON.stringify(body)
	http_request.request(OPENAI_API_URL, headers, HTTPClient.METHOD_POST, json_body)
	
	var response = await http_request.request_completed
	if response[0] == OK and response[1] == 200:
		var json = JSON.parse_string(response[3].get_string_from_utf8())
		if json and json.has("choices"):
			var message = json["choices"][0]["message"]["content"]
			return message.strip_edges()
	
	return _generate_with_rules(character_type, situation)

func _generate_with_rules(character_type: String, situation: String) -> String:
	var lines: Array[String] = []
	
	match character_type:
		"player":
			match situation:
				"combat_hit":
					lines = ["Take this!", "Hyah!", "Got you!", "Not today!", "Come on!"]
				"combat_miss":
					lines = ["Missed!", "Darn!", "Almost!", "Gotta be faster!"]
				"combat_take_damage":
					lines = ["Ugh!", "That hurt!", "Not good!", "I'm still standing!"]
				"combat_kill":
					lines = ["Victory!", "One down!", "Excellent!", "Too easy!"]
				"exploration":
					lines = ["What's this?", "Interesting...", "Let's keep moving.", "Stay alert.", "I sense danger."]
				"low_health":
					lines = ["I need to heal!", "This is bad!", "Can't go on like this!"]
				_:
					lines = ["Hmm.", "Interesting.", "Let's go."]
		
		"goblin":
			match situation:
				"combat_alert":
					lines = ["Intruder!", "Attack!", "Get 'em!", "Grrr!", "You die now!"]
				"combat_hit":
					lines = ["Hehehehe!", "Got ya!", "Die!", "Taste steel!"]
				"combat_take_damage":
					lines = ["Ow!", "You'll pay!", "Grrr!", "I'll get you!"]
				"conversation":
					lines = ["What's that sound?", "Did you hear that?", "Something's coming...", "Stay sharp."]
				_:
					lines = ["Grrr...", "Hehehehe!", "What?"]
		
		"orc":
			match situation:
				"combat_alert":
					lines = ["INTRUDER!", "ATTACK NOW!", "CRUSH YOU!", "FEEL MY WRATH!"]
				"combat_hit":
					lines = ["HAHAHAHA!", "DIE!", "SMASH!", "TAKE THIS!"]
				"combat_take_damage":
					lines = ["ARGH!", "YOU DARE?!", "I'LL CRUSH YOU!", "MORE PAIN!"]
				"conversation":
					lines = ["Something stirs...", "I smell weakness...", "Prepare yourselves!"]
				_:
					lines = ["GRRRR!", "HAHAHAHA!", "CRUSH!"]
		
		"skeleton":
			match situation:
				"combat_alert":
					lines = ["Bones rattle...", "Intruder detected.", "Engage target.", "Destroy."]
				"combat_hit":
					lines = ["Clack clack!", "Bone strike!", "Perish.", "Your end."]
				"combat_take_damage":
					lines = ["Bones crack...", "Damage sustained.", "Recalculating...", "I persist."]
				"conversation":
					lines = ["Undead senses tingling...", "Something approaches...", "Vigilance required."]
				_:
					lines = ["Clack clack...", "Bones rattle...", "Undead."]
		
		_:
			lines = ["...", "Hmm.", "Indeed."]
	
	return lines[randi() % lines.size()]

func is_speaking(speaker: String) -> bool:
	return active_dialogues.has(speaker)

func stop_speaking(speaker: String) -> void:
	if active_dialogues.has(speaker):
		var bubble = active_dialogues[speaker]
		if is_instance_valid(bubble):
			bubble.queue_free()
		active_dialogues.erase(speaker)
