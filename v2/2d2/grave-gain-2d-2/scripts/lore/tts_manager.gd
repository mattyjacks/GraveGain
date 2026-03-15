extends Node

signal tts_started(entry_id: String)
signal tts_finished(entry_id: String)
signal tts_error(entry_id: String, error_msg: String)

const CACHE_DIR := "user://tts_cache/"
const OPENAI_TTS_URL := "https://api.openai.com/v1/audio/speech"
const ELEVENLABS_TTS_URL := "https://api.elevenlabs.io/v1/text-to-speech/"

var openai_api_key: String = ""
var elevenlabs_api_key: String = ""

var elevenlabs_voice_map: Dictionary = {
	"narrator_dramatic": "pNInz6obpgDQGcFmaJgB",
	"ancient_elven": "EXAVITQu4vr4xnSDxMaL",
	"sinister_voice": "VR6AewLTigWG4xSOukaG",
}

var audio_player: AudioStreamPlayer = null
var current_entry_id: String = ""
var is_playing: bool = false
var http_request: HTTPRequest = null
var pending_requests: Array[Dictionary] = []
var is_requesting: bool = false

const API_KEY_PATH := "user://api_keys.cfg"

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	audio_player.finished.connect(_on_playback_finished)
	add_child(audio_player)

	http_request = HTTPRequest.new()
	http_request.request_completed.connect(_on_request_completed)
	http_request.download_chunk_size = 65536
	add_child(http_request)

	_ensure_cache_dir()
	_load_api_keys()

func _ensure_cache_dir() -> void:
	if not DirAccess.dir_exists_absolute(CACHE_DIR):
		DirAccess.make_dir_recursive_absolute(CACHE_DIR)

func _load_api_keys() -> void:
	if not FileAccess.file_exists(API_KEY_PATH):
		_save_default_api_keys()
		return
	var config := ConfigFile.new()
	var err := config.load(API_KEY_PATH)
	if err != OK:
		return
	openai_api_key = config.get_value("api_keys", "openai", "")
	elevenlabs_api_key = config.get_value("api_keys", "elevenlabs", "")

func _save_default_api_keys() -> void:
	var config := ConfigFile.new()
	config.set_value("api_keys", "openai", "")
	config.set_value("api_keys", "elevenlabs", "")
	config.save(API_KEY_PATH)

func set_openai_key(key: String) -> void:
	openai_api_key = key
	_save_api_keys()

func set_elevenlabs_key(key: String) -> void:
	elevenlabs_api_key = key
	_save_api_keys()

func _save_api_keys() -> void:
	var config := ConfigFile.new()
	config.set_value("api_keys", "openai", openai_api_key)
	config.set_value("api_keys", "elevenlabs", elevenlabs_api_key)
	config.save(API_KEY_PATH)

func has_openai_key() -> bool:
	return not openai_api_key.is_empty()

func has_elevenlabs_key() -> bool:
	return not elevenlabs_api_key.is_empty()

func speak_entry(entry: Dictionary) -> void:
	if entry.is_empty():
		return

	var entry_id: String = entry.get("id", "")
	if entry_id.is_empty():
		tts_error.emit("", "Entry has no ID")
		return
	var cache_path := _get_cache_path(entry_id)

	if FileAccess.file_exists(cache_path):
		_play_cached(entry_id, cache_path)
		return

	var provider: String = entry.get("voice_provider", "openai")
	var voice_id: String = entry.get("voice_id", "nova")
	var content: String = entry.get("content", "")

	if content.is_empty():
		tts_error.emit(entry_id, "No content to read")
		return

	if content.length() > 4000:
		content = content.substr(0, 4000)

	match provider:
		"openai":
			if not has_openai_key():
				tts_error.emit(entry_id, "OpenAI API key not set. Go to Settings to add your key.")
				return
			_request_openai_tts(entry_id, content, voice_id)
		"elevenlabs":
			if not has_elevenlabs_key():
				if has_openai_key():
					_request_openai_tts(entry_id, content, "onyx")
					return
				tts_error.emit(entry_id, "ElevenLabs API key not set. Go to Settings to add your key.")
				return
			var resolved_voice: String = elevenlabs_voice_map.get(voice_id, voice_id) as String
			_request_elevenlabs_tts(entry_id, content, resolved_voice)
		_:
			tts_error.emit(entry_id, "Unknown voice provider: " + provider)

func _request_openai_tts(entry_id: String, text: String, voice: String) -> void:
	if is_requesting:
		pending_requests.append({"entry_id": entry_id, "text": text, "voice": voice, "provider": "openai"})
		return

	is_requesting = true
	current_entry_id = entry_id
	tts_started.emit(entry_id)

	var body := JSON.stringify({
		"model": "tts-1",
		"input": text,
		"voice": voice,
		"response_format": "mp3",
	})

	var headers := [
		"Authorization: Bearer " + openai_api_key,
		"Content-Type: application/json",
	]

	var cache_path := _get_cache_path(entry_id)
	http_request.download_file = cache_path

	var err := http_request.request(OPENAI_TTS_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		is_requesting = false
		tts_error.emit(entry_id, "HTTP request failed: " + str(err))

func _request_elevenlabs_tts(entry_id: String, text: String, voice_id: String) -> void:
	if is_requesting:
		pending_requests.append({"entry_id": entry_id, "text": text, "voice": voice_id, "provider": "elevenlabs"})
		return

	is_requesting = true
	current_entry_id = entry_id
	tts_started.emit(entry_id)

	var url := ELEVENLABS_TTS_URL + voice_id
	var body := JSON.stringify({
		"text": text,
		"model_id": "eleven_monolingual_v1",
		"voice_settings": {
			"stability": 0.5,
			"similarity_boost": 0.75,
		},
	})

	var headers := [
		"xi-api-key: " + elevenlabs_api_key,
		"Content-Type: application/json",
		"Accept: audio/mpeg",
	]

	var cache_path := _get_cache_path(entry_id)
	http_request.download_file = cache_path

	var err := http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		is_requesting = false
		tts_error.emit(entry_id, "HTTP request failed: " + str(err))

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	is_requesting = false
	var entry_id := current_entry_id

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		var error_cache_path := _get_cache_path(entry_id)
		if FileAccess.file_exists(error_cache_path):
			DirAccess.remove_absolute(error_cache_path)
		var err_msg := "TTS request failed (HTTP " + str(response_code) + ")"
		if response_code == 401:
			err_msg = "Invalid API key. Check your settings."
		elif response_code == 429:
			err_msg = "Rate limited. Please wait and try again."
		tts_error.emit(entry_id, err_msg)
		_process_pending()
		return

	var cache_path := _get_cache_path(entry_id)
	if FileAccess.file_exists(cache_path):
		_play_cached(entry_id, cache_path)
	else:
		tts_error.emit(entry_id, "Cache file not found after download")

	_process_pending()

func _process_pending() -> void:
	if pending_requests.is_empty():
		return
	var next: Dictionary = pending_requests.pop_front()
	match next["provider"]:
		"openai":
			_request_openai_tts(next["entry_id"], next["text"], next["voice"])
		"elevenlabs":
			_request_elevenlabs_tts(next["entry_id"], next["text"], next["voice"])

func _play_cached(entry_id: String, cache_path: String) -> void:
	var file := FileAccess.open(cache_path, FileAccess.READ)
	if not file:
		tts_error.emit(entry_id, "Could not open cached audio")
		return

	var data := file.get_buffer(file.get_length())
	file = null

	var stream := AudioStreamMP3.new()
	stream.data = data

	current_entry_id = entry_id
	is_playing = true
	audio_player.stream = stream
	audio_player.play()
	tts_started.emit(entry_id)

func _on_playback_finished() -> void:
	is_playing = false
	tts_finished.emit(current_entry_id)

func stop() -> void:
	if is_playing:
		audio_player.stop()
		is_playing = false
		tts_finished.emit(current_entry_id)

func is_currently_playing() -> bool:
	return is_playing

func get_playback_position() -> float:
	if is_playing and audio_player.stream:
		return audio_player.get_playback_position()
	return 0.0

func get_playback_length() -> float:
	if audio_player and audio_player.stream:
		return audio_player.stream.get_length()
	return 0.0

func _get_cache_path(entry_id: String) -> String:
	return CACHE_DIR + entry_id + ".mp3"

func clear_cache() -> void:
	var dir := DirAccess.open(CACHE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".mp3"):
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

func is_entry_cached(entry_id: String) -> bool:
	return FileAccess.file_exists(_get_cache_path(entry_id))
