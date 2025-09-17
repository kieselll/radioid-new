extends Node

var settings_file : ConfigFile
var settings_file_path : String

func _ready() -> void:
	settings_file = ConfigFile.new()
	if not OS.has_feature("editor"):
		settings_file_path = "user://settings.cfg"
	else:
		settings_file_path = "C:/Users/Kirill/Desktop/Game Files" + "/settings.cfg"
	var error = settings_file.load(settings_file_path)
	if error != OK:
		printerr("Config file not loaded")

func write_to_settings(section : String, key : String, value) -> void:
	settings_file.set_value(section, key, value)
	settings_file.save(settings_file_path)

func read_from_settings(section : String, key : String):
	return settings_file.get_value(section, key)
