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
	func _init():
		creation_date = Time.get_datetime_dict_from_system()
		modified_date = creation_date
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
	var _new_save = get_save_meta(dirname)
	_current_world_file = _open_file(_current_save_path + "/world.dat")
	_current_index_file = _open_file(_current_save_path + "/index.dat")
	return _new_save

func get_save_meta(dirname : String) -> SaveMeta:
	var _new_save = SaveMeta.new()
	var save_path = _save_dir_path + dirname
	var fileacc = FileAccess.open(save_path + "/meta.json", FileAccess.READ_WRITE)
	_new_save.dejsonify(fileacc.get_as_text())
	return _new_save

func save_chunk(coords : Vector2i):
	var chunk = GlobalRef.get_chunk(coords)
	_chunks_to_save.append({"coords" = coords, "data" = var_to_bytes(chunk.get_cells_rle())})

func read_chunk(coords : Vector2i):
	var memory_chunk = _chunks_to_save.find_custom(func(element): return element.coords == coords)
	if memory_chunk != -1:
		return bytes_to_var(_chunks_to_save[memory_chunk].data)
	_current_index_file.seek(0)
	var position : int = 0
	while _current_index_file.get_position() + 16 <= _current_index_file.get_length():
		var buffer = _current_index_file.get_buffer(16)
		if not buffer or buffer.size() < 16: return null
		var read_coords := Vector2i(buffer.decode_s32(0), buffer.decode_s32(4))
		position = buffer.decode_s64(8)
		if read_coords == coords:
			_current_world_file.seek(position)
			var buffer_size = _current_world_file.get_buffer(8).decode_u64(0)
			return bytes_to_var(_current_world_file.get_buffer(buffer_size))
	return null

func update_index(coords: Vector2i, new_position: int) -> void:
		_current_index_file.seek(0)
		while _current_index_file.get_position() < _current_index_file.get_length():
				var entry_pos = _current_index_file.get_position()
				var buf = _current_index_file.get_buffer(16)
				if buf.size() < 16:
						return
				var x = buf.decode_s32(0)
				var y = buf.decode_s32(4)
				if coords == Vector2i(x, y):
						_current_index_file.seek(entry_pos + 8)
						var pos_buf = PackedByteArray()
						pos_buf.resize(8)
						pos_buf.encode_s64(0, new_position)
						_current_index_file.store_buffer(pos_buf)
						return
		var entry = PackedByteArray()
		entry.resize(16)
		entry.encode_s32(0, coords.x)
		entry.encode_s32(4, coords.y)
		entry.encode_s64(8, new_position)
		_current_index_file.store_buffer(entry)


func _ready() -> void:
	add_child(write_timer)
	write_timer.start(2)
	write_timer.connect("timeout", _on_write_timer_timeout)
	if OS.has_feature("editor"):
		load_save("test_save")

func _on_write_timer_timeout():
	if get_tree().current_scene and get_tree().current_scene.name != "GameRoot": return
	var data : PackedByteArray = []
	var pos = _current_world_file.get_length()
	_current_world_file.seek(pos)
	for i in _chunks_to_save:
		var header = PackedByteArray([])
		header.resize(8)
		header.encode_u64(0, i.data.size())
		data.append_array(header)
		data.append_array(i.data)
		update_index(i.coords, pos)
		pos += i.data.size() + 8
	if not data.is_empty():
		_current_world_file.store_buffer(data)
		_chunks_to_save.clear()

func _open_file(path : String) -> FileAccess:
	return FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		for i in GlobalRef.chunks.keys():
			if GlobalRef.get_chunk(i) and GlobalRef.get_chunk(i).dirty:
				save_chunk(i)
		_on_write_timer_timeout()
		get_tree().quit()
