extends Node
class_name ConfigDB
## A singleton that holds cached settings as well as saving/loading them to/from files respectively.

var _settings_file : ConfigFile
var _settings_file_path : String
var _settings_old_file_path : String
var _cached_settings : Dictionary[String, Dictionary]

const _default_settings: Dictionary[String, Dictionary] = {
	"graphics" = {
		"window_type" = 0,
		"frame_rate_limit" = 0,
		"particle_amount" = 2,
		"brightness" = 50,
		"render_distance" = 10
	},

	"gameplay" = {
		"default_difficulty" = 1
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
	var temp_path := "user://game"
	DirAccess.make_dir_recursive_absolute(temp_path)
	_settings_file_path = temp_path + "/settings.cfg"
	_settings_old_file_path = temp_path + "/settings.old"
	load_settings()
	apply_settings()

func write_dict_to_settings() -> void:
	GlobalLogger.write_to_logs(self, "Saving settings...")
	if FileAccess.file_exists(_settings_file_path):
		_settings_file.save(_settings_old_file_path)
		GlobalLogger.write_to_logs(self, "Saved previous version as backup")
	for section: String in _cached_settings.keys():
		var section_dict: Dictionary[String, Variant] = _cached_settings[section]
		for key: String in section_dict.keys():
			_settings_file.set_value(section, key, section_dict[key])
	var err := _settings_file.save(_settings_file_path)
	if err != OK:
		GlobalLogger.write_to_logs(self, "Couldn't save settings, error: %s" % str(err))
		return
	GlobalLogger.write_to_logs(self, "Saved new settings")

func load_settings() -> Dictionary:
	GlobalLogger.write_to_logs(self, "Loading settings...")
	if not _cached_settings:
		_cached_settings = _default_settings.duplicate(true)
		var err: Error = _settings_file.load(_settings_file_path)
		if err != OK:
			GlobalLogger.write_to_logs(self, "Couldn't load settings file, error: %s, trying backup..." %str(err))
			err = _settings_file.load(_settings_old_file_path)
			if err != OK:
				GlobalLogger.write_to_logs(self, "Couldn't load backup settings file, error: %s, restoring defaults..." %str(err))
				return _cached_settings
		GlobalLogger.write_to_logs(self, "Settings file loaded! Parsing settings...")
		for section in _settings_file.get_sections():
			if not _cached_settings.has(section):
				_cached_settings[section] = {}
			for key in _settings_file.get_section_keys(section):
				_cached_settings[section][key] = _settings_file.get_value(section, key)
	GlobalLogger.write_to_logs(self, "Settings parsed and stored in cache")
	return _cached_settings

func get_setting(section: String, key: String, default: Variant = null) -> Variant:
	if _cached_settings.has(section):
		var section_dict: Dictionary[String, Variant] = {}
		section_dict.assign(_cached_settings[section])
		if section_dict.has(key):
			return section_dict[key]
	return default

func alter_setting(section : String, key : String, value: Variant) -> void:
	if _cached_settings.has(section):
		var section_dict: Dictionary[String, Variant] = _cached_settings[section]
		if section_dict.has(key):
			_cached_settings[section][key] = value
			apply_setting(section, key)

func apply_settings() -> void:
	for section: String in _cached_settings.keys():
		var section_dict: Dictionary[String, Variant] = {}
		section_dict.assign(_cached_settings[section])
		for key: String in section_dict.keys():
			apply_setting(section, key)

func apply_setting(section: String, key: String) -> void:
	var value: Variant = get_setting(section, key)
	if section == "graphics":
		match key:
			"frame_rate_limit":
				@warning_ignore("unsafe_call_argument")
				Engine.max_fps = int(value)
			"window_type":
				@warning_ignore("unsafe_cast")
				var window_mode := value as Window.Mode
				if window_mode in [Window.MODE_WINDOWED, Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]:
					get_window().mode = window_mode
	elif section == "audio":
		@warning_ignore("unsafe_cast")
		var bus_name := {"main_volume": "Master", "sfx_volume": "SFX", "music_volume": "Music"}.get(key, "") as String
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index >= 0:
			@warning_ignore("unsafe_call_argument")
			var normalized_volume := clampf(float(value) / 100.0, 0.0, 1.0)
			AudioServer.set_bus_volume_db(bus_index, linear_to_db(normalized_volume))
			AudioServer.set_bus_mute(bus_index, is_zero_approx(normalized_volume))
