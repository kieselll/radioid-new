extends Node
class_name ConfigDB
## A singleton that holds cached settings as well as saving/loading them to/from files respectively.

var _settings_file : ConfigFile
var _settings_file_path : String
var _settings_old_file_path : String
var _cached_settings : Dictionary

const _default_settings = {
	"graphics" = {
		"window_type" = 0,
		"frame_rate_limit" = 0,
		"particle_amount" = 2,
		"brightness" = 50
	},
	
	"gameplay" = {
		"default_difficuty" = 1
	},
	
	"controls" = {
		"camera_movement_sensitivity" = 100,
		"camera_zoom_sensitivity" = 100,
		"invert_camera_movement" = 0,
		"invert_camera_zoom" = 0
	},
	
	"audio" = {
		"main_volume" = 100,
		"sfx_volume" = 100,
		"music_volume" = 50
	},
	
	"saves" = {
		"game_path" = "user://",
		"autosave_frequency" = 4
	}
}

func _ready() -> void:
	_settings_file = ConfigFile.new()
	GlobalLogger.write_to_logs(self, "Created new ConfigFile")
	var temp_path
	temp_path = "user:///game"
	_settings_file_path = temp_path + "/settings.cfg"
	_settings_old_file_path = temp_path + "/settings.old"
	load_settings()
	if get_setting("graphics", "frame_rate_limit"):
		Engine.max_fps = get_setting("graphics", "frame_rate_limit")
	match get_setting("graphics", "window_type", 0):
		0:
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
		1:
			get_window().mode = Window.MODE_WINDOWED

func write_dict_to_settings() -> void:
	GlobalLogger.write_to_logs(self, "Saving settings...")
	_settings_file.save(_settings_old_file_path)
	GlobalLogger.write_to_logs(self, "Saved previous version as backup")
	var _settings_to_save = _cached_settings.merged(_default_settings)
	for section in _settings_to_save.keys():
		var _section_to_save = _settings_to_save[section].merged(_default_settings[section])
		for key in _section_to_save.keys():
			_settings_file.set_value(section, key, _settings_to_save[section][key])
	_settings_file.save(_settings_file_path)
	GlobalLogger.write_to_logs(self, "Saved new settings")

func load_settings() -> Dictionary:
	GlobalLogger.write_to_logs(self, "Loading settings...")
	if not _cached_settings:
		var err = _settings_file.load(_settings_file_path)
		if err != OK:
			GlobalLogger.write_to_logs(self, "Couldn't load settings file, error: %s, trying backup..." %str(err))
			err = _settings_file.load(_settings_old_file_path)
			if err != OK:
				GlobalLogger.write_to_logs(self, "Couldn't load backup settings file, error: %s, restoring defaults..." %str(err))
				return _default_settings
		GlobalLogger.write_to_logs(self, "Settings file loaded! Parsing settings...")
		for section in _settings_file.get_sections():
			_cached_settings[section] = {}
			for key in _settings_file.get_section_keys(section):
				_cached_settings[section][key] = _settings_file.get_value(section, key)
	GlobalLogger.write_to_logs(self, "Settings parsed and stored in cache")
	return _cached_settings

func get_setting(section: String, key: String, default = null):
	if _cached_settings.has(section) and _cached_settings[section].has(key):
		return _cached_settings[section][key]
	return default

func alter_setting(section : String, key : String, value):
	if _cached_settings.has(section) and _cached_settings[section].has(key):
		_cached_settings[section][key] = value
