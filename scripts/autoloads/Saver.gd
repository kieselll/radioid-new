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
	_current_save_path = _save_dir_path + dirname
	if not DirAccess.dir_exists_absolute(_current_save_path):
		DirAccess.make_dir_recursive_absolute(_current_save_path)
	if not DirAccess.dir_exists_absolute(_current_save_path + "/navigation"):
		DirAccess.make_dir_recursive_absolute(_current_save_path + "/navigation")
	_current_world_file = _open_file(_current_save_path + "/world.dat")
	_current_index_file = _open_file(_current_save_path + "/index.dat")
	var _meta_file = FileAccess.open(_current_save_path + "/meta.json", FileAccess.WRITE)
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
	# Read the buffer size from the chunk header
	var buffer_size = _current_world_file.get_buffer(8).decode_u64(0)
	# And then return the BINARY chunk
	return bytes_to_var(_current_world_file.get_buffer(buffer_size))

func update_chunk_index(coords: Vector2i, new_position: int) -> void:
	data_indices[coords] = new_position

func save_nav_data(portals_by_id : Dictionary[String, GlobalPathfinder.ChunkPortal], portal_connections : Dictionary):
	var index_data : PackedByteArray = []
	var data : PackedByteArray = []

	var index_file = _open_file(_current_save_path + "/navigation/index.dat")

	var data_file = _open_file(_current_save_path + "/navigation/data.dat")

	data_file.seek_end()
	index_file.seek_end()

	for portal in portals_by_id.values():
		var ascii_id : PackedByteArray = portal.id.to_ascii_buffer()
		index_data.resize(index_data.size() + 1)
		index_data.encode_u8(index_data.size() - 1, ascii_id.size())
		index_data.append_array(ascii_id)
		index_data.resize(index_data.size() + 8)
		index_data.encode_u64(index_data.size() - 8, data_file.get_position() + data.size())
		# Is always 12 bytes long
		data.append_array(portal.encode())
		# Number of portal connections
		data.resize(data.size() + 1)
		data.encode_u8(data.size() - 1, portal_connections[portal.id].size())
		for i in portal_connections[portal.id]:
			# ID length
			data.resize(data.size() + 1)
			data.encode_u8(data.size(), i.id.to_ascii_buffer().size())
			# Actual ID
			data.append_array(i.id.to_ascii_buffer())
			# Number of connections
			data.resize(data.size() + 1)
			data.encode_u8(data.size() - 1, portal_connections[portal.id][i].size())
			for j in portal_connections[portal.id][i]:
				data.resize(data.size() + 8)
				# 8 bytes in total, per connection
				data.encode_u8(data.size() - 8, j["root"].x)
				data.encode_u8(data.size() - 7, j["root"].y)
				data.encode_u8(data.size() - 6, j["coords"].x)
				data.encode_u8(data.size() - 5, j["coords"].y)
				data.encode_float(data.size() - 4, j["weight"])

	data_file.store_buffer(data)
	index_file.store_buffer(index_data)
	data_file.close()
	index_file.close()


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
		var data_indices_buffer : PackedByteArray = []
		for i in data_indices.size():
			var key = data_indices.keys()[i]
			data_indices_buffer.encode_s64(24*i, key.x)
			data_indices_buffer.encode_s64(24*i + 8, key.y)
			data_indices_buffer.encode_u64(24*i + 16, data_indices[key])

		_current_index_file.store_buffer(data_indices_buffer)
		get_tree().quit()
