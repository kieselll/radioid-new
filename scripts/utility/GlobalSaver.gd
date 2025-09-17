extends Node

var save_dir_path : String
var save_dir_access : DirAccess
var game_dir_path : String

var process_handler : Node

func _ready() -> void:
	if not OS.has_feature("editor"):
		game_dir_path = "user://"
	else:
		game_dir_path = "C:/Users/Kirill/Desktop/Game Files"
	save_dir_path = game_dir_path + "/saves"
	
	if not DirAccess.dir_exists_absolute(save_dir_path):
		DirAccess.make_dir_absolute(save_dir_path)
	save_dir_access = DirAccess.open(save_dir_path)
	
	# CRITICAL DELETE THIS BEFORE RELEASE
	
	save_options({"idk_section" = {"option_1" = 12, "option_2" = 88}, "nother_section" = {"the only option" = 0}})
	
func save_game() -> void:
	process_handler = get_node(GlobalRef.get_handler("process_handler"))
	var save_file = FileAccess.open(save_dir_path + "/save_" + str(Time.get_datetime_string_from_system()), FileAccess.WRITE)
	save_file.store_string(JSON.stringify(process_handler.time))
	save_file.close()

func save_options(options : Dictionary) -> void:
	var options_file := ConfigFile.new()
	for section_name in options.keys():
		for key in options[section_name].keys():
			options_file.set_value(section_name, key, options[section_name][key])
	options_file.save(game_dir_path + "/options.cfg")
	print("Options file saved at ", game_dir_path + "/options.cfg")
