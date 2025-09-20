extends Node
class_name Saver

var save_dir_path : String
var save_dir_access : DirAccess
var game_dir_path : String

var _process_handler : Node

func _ready() -> void:
	if not OS.has_feature("editor"): # CRITICAL DELETE THIS BEFORE RELEASE
		game_dir_path = "user://"
	else:
		game_dir_path = "C:/Users/Kirill/Desktop/Game Files"
	save_dir_path = game_dir_path + "/saves"
	
	if not DirAccess.dir_exists_absolute(save_dir_path):
		DirAccess.make_dir_absolute(save_dir_path)
	save_dir_access = DirAccess.open(save_dir_path)
	
func save_game() -> void:
	_process_handler = get_node(GlobalRef.get_handler(GlobalRef._handlers_enum.process_handler))
	var save_file = FileAccess.open(save_dir_path + "/save_" + str(Time.get_datetime_string_from_system()), FileAccess.WRITE)
	save_file.store_string(JSON.stringify(_process_handler.time))
	save_file.close()
