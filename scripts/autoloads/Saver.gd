extends Node
class_name Saver

var _current_save_path : String = ""
var _current_save : SaveMeta
var _current_world_file : FileAccess
var _current_index_file : FileAccess
@export var _save_dir_path : String = "user://game/saves/"
@export var _game_dir_path : String = "user://game/"

var write_timer : Timer = Timer.new()
var _chunks_to_save : Array = []

class SaveMeta:
	var creation_date : Dictionary
	var modified_date : Dictionary
	var display_name : String
	var playtime : int
	var world_seed : int
	var version : String

	@warning_ignore("shadowed_variable")
	func _init(display_name: String, world_seed: int):
		creation_date = Time.get_datetime_dict_from_system()
		modified_date = creation_date
		self.display_name = display_name
		self.world_seed = world_seed
		version = ProjectSettings.get_setting("application/config/version")
		playtime = 0

	func jsonify() -> String:
		return JSON.stringify({
			"creation_date" : creation_date,
			"modified_date" : modified_date,
			"display_name" : display_name,
			"playtime": playtime,
			"world_seed": world_seed,
			"version": version
			})

	func dejsonify(json_string : String) -> void:
		var dict = JSON.parse_string(json_string)
		creation_date = dict["creation_date"]
		modified_date = dict["modified_date"]
		display_name = dict["display_name"]
		playtime = dict["playtime"]
		world_seed = dict["world_seed"]
		version = dict["version"]

func get_saves_list() -> Array:
	return DirAccess.open(_save_dir_path).get_directories()

func write_save(dirname : String) -> void:
	var _write_save_path = _save_dir_path + dirname
	if not DirAccess.dir_exists_absolute(_write_save_path):
		DirAccess.make_dir_recursive_absolute(_write_save_path)
	_current_world_file = _open_file(_write_save_path + "/world.dat")
	_current_index_file = _open_file(_write_save_path + "/index.dat")
	var _meta_file = FileAccess.open(_write_save_path + "/meta.json", FileAccess.WRITE)
	_meta_file.store_string(_current_save.jsonify())

func load_save(dirname : String) -> SaveMeta:
	_current_save_path = _save_dir_path + dirname
	var _new_save = SaveMeta.new("",0)
	var fileacc = FileAccess.open(_current_save_path + "/meta.json", FileAccess.READ_WRITE)
	_new_save.dejsonify(fileacc.get_as_text())
	_current_world_file = _open_file(_current_save_path + "/world.dat")
	return _new_save

func save_chunk(coords : Vector2i):
	var chunk = GlobalRef.get_chunk(coords)
	_chunks_to_save.append(chunk.get_cells())

func _ready() -> void:
	_current_save = SaveMeta.new("test_save", 1234)
	load_save("test_save")
	add_child(write_timer)
	write_timer.start(2)
	write_timer.connect("timeout", _on_write_timer_timeout)

func _on_write_timer_timeout():
	for i in _chunks_to_save:
		_current_world_file.store_var(i)
		print("stored")
	_chunks_to_save.clear()

func _open_file(path : String) -> FileAccess:
	return FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
