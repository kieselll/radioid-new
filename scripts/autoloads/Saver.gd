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
var data_indices : Dictionary[Vector2i, int]

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
	_current_index_file.seek(0)
	while _current_index_file.get_position() + 16 < _current_index_file.get_length():
		var buf = _current_index_file.get_buffer(16)
		if buf.size() < 16:
				return
		var x = buf.decode_s32(0)
		var y = buf.decode_s32(4)
		var index = buf.decode_u64(8)
		data_indices[Vector2i(x, y)] = index
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

## Function that searches for the given coords in the index file, reading from end to start because of the append-only architecture,
## and then returning the raw buffer representing the RLE encoded chunk data. Returns [null] if no chunk with such coords is found. [br][br]
## [color=red] NEED TO ADD DATA VALIDATION AND SKIPPING LATER!!![/color]
func read_chunk(coords : Vector2i):
	# We try to find the chunk in memory
	var memory_chunk = _chunks_to_save.find_custom(func(element): return element.coords == coords)
	# If there is one, we return it
	if memory_chunk != -1:
		return bytes_to_var(_chunks_to_save[memory_chunk].data)
	# If the chunk wasn't found in the memory, we search for it on the disk
	if not _current_world_file or not data_indices.has(coords): return null
	_current_world_file.seek(data_indices[coords])
	print("Reading chunk ", coords, " at offset ", data_indices[coords], " file size: ", _current_world_file.get_length())
	# Read the buffer size from the chunk header
	var buffer_size = _current_world_file.get_buffer(8).decode_u64(0)
	# And then return the BINARY chunk
	return bytes_to_var(_current_world_file.get_buffer(buffer_size))

func update_chunk_index(coords: Vector2i, new_position: int) -> void:
	data_indices[coords] = new_position

func save_nav_data(portals_by_id : Dictionary, portal_nodes : Dictionary[int, Array]):
	var mode
	var index_data : PackedByteArray = []
	var data : PackedByteArray = []

	if not FileAccess.file_exists(_save_dir_path + "/navigation/index.dat"):
		mode = FileAccess.WRITE
	else:
		mode = FileAccess.READ_WRITE
	var index_file = FileAccess.open(_save_dir_path + "/navigation/index.dat", mode)

	if not FileAccess.file_exists(_save_dir_path + "/navigation/data.dat"):
		mode = FileAccess.WRITE
	else:
		mode = FileAccess.READ_WRITE
	var data_file = FileAccess.open(_save_dir_path + "/navigation/data.dat", mode)

	data_file.seek_end()

	for i in portal_nodes:
		index_data.resize(portal_nodes[i].size())
		for j in portal_nodes[i]:
			var encoded_data = portals_by_id[j].encode()
			data.append_array(encoded_data)
			index_data.encode_u64(index_data.size(), encoded_data.size() + data_file.get_position())

	data_file.store_buffer(data)
	index_file.store_buffer(index_data)


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
		update_chunk_index(i.coords, pos)
		pos += i.data.size() + 8
	if not data.is_empty():
		_current_world_file.store_buffer(data)
		_chunks_to_save.clear()

func _open_file(path : String) -> FileAccess:
	return FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE_READ)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		for i in GlobalRef.chunks.keys():
			if GlobalRef.get_chunk(i) and GlobalRef.get_chunk(i).dirty:
				save_chunk(i)
		_on_write_timer_timeout()
		get_tree().quit()
