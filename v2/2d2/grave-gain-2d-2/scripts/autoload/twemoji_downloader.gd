extends Node

# Twemoji Font Downloader - Helper script to download Twemoji fonts
# This script provides utilities for downloading and installing Twemoji fonts

class_name TwemojiDownloader

const TWEMOJI_DOWNLOAD_URL = "https://github.com/mozilla/twemoji-colr/releases/download/v0.7.0/Twemoji.Mozilla.ttf"
const FONT_SAVE_PATH = "user://fonts/emoji/Twemoji.Mozilla.ttf"

var download_in_progress: bool = false
var http_request: HTTPRequest = null

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_download_complete)

func download_twemoji() -> void:
	if download_in_progress:
		print("⚠ Download already in progress")
		return
	
	# Create directory if it doesn't exist
	var dir = DirAccess.open("user://fonts/")
	if dir == null:
		DirAccess.make_absolute_path("user://fonts/emoji/")
	
	download_in_progress = true
	print("⏳ Downloading Twemoji font...")
	print("URL: " + TWEMOJI_DOWNLOAD_URL)
	
	var error = http_request.request(TWEMOJI_DOWNLOAD_URL)
	if error != OK:
		print("✗ Failed to start download: " + str(error))
		download_in_progress = false

func _on_download_complete(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	download_in_progress = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		print("✗ Download failed with result: " + str(result))
		return
	
	if response_code != 200:
		print("✗ Download failed with HTTP code: " + str(response_code))
		return
	
	# Save the font file
	var file = FileAccess.open(FONT_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		print("✗ Failed to save font file")
		return
	
	file.store_buffer(body)
	print("✓ Twemoji font downloaded successfully!")
	print("Location: " + FONT_SAVE_PATH)
	print("Size: " + str(body.size()) + " bytes")
	print("Please restart the game to load the font")

func is_downloading() -> bool:
	return download_in_progress

func get_download_url() -> String:
	return TWEMOJI_DOWNLOAD_URL

func get_save_path() -> String:
	return FONT_SAVE_PATH
