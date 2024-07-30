extends Node

var config = ConfigFile.new()
const SETTINGS_FILE_PATH = "user://settings.ini"

func _ready():
	if !FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.set_value("keybinding", "move_up", "W")
		config.set_value("keybinding", "move_left", "A")
		config.set_value("keybinding", "move_down", "S")
		config.set_value("keybinding", "move_right", "D")
		config.set_value("keybinding", "jump", "Space")
		config.set_value("keybinding", "interact", "E")
		config.set_value("keybinding", "throw", "R")
		config.set_value("keybinding", "inventory", "I")
		config.set_value("keybinding", "craft", "C")
		
		config.set_value("video", "fullscreen", true)
		config.set_value("video", "screen_shake", false)
		
		config.set_value("audio", "master_volume", 1.0)
		config.set_value("audio", "sfx_volume", 1.0)
		
		config.save(SETTINGS_FILE_PATH)
	else:
		config.load(SETTINGS_FILE_PATH)
		
func save_video_setting(key: String, value):
	config.set_value("video", key, value)
	config.save(SETTINGS_FILE_PATH)
	
func load_video_setting():
	var video_settings = {}
	for key in config.get_section_keys("video"):
		video_settings[key] = config.get_value("video", key)
	return video_settings

func save_audio_setting(key: String, value):
	config.set_value("audio", key, value)
	config.save(SETTINGS_FILE_PATH)
	
func load_audio_setting():
	var audio_settings = {}
	for key in config.get_section_keys("audio"):
		audio_settings[key] = config.get_value("audio", key)
	return audio_settings
