extends Node
class_name Saver

var _current_save_path : String = ""
var _current_save : SaveMeta
var _current_world_file : FileAccess
var _current_index_file : FileAccess
@export var _save_dir_path : String = "user://game/saves/"
@export var _game_dir_path : String = "user://game/"
@onready var pathfinder : GlobalPathfinder = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.pathfinder))

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
		if not dict: return
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
	#_meta_file.store_string(_current_save.jsonify()) DEBUG CRITICAL

func load_save(dirname : String) -> SaveMeta:
	_current_save_path = _save_dir_path + dirname
	var _new_save = get_save_meta(dirname)
	_current_world_file = _open_file(_current_save_path + "/world.dat")
	_current_index_file = _open_file(_current_save_path + "/index.dat")
	_current_index_file.seek(0)
	while _current_index_file.get_position() + 16 < _current_index_file.get_length():
		var buf = _current_index_file.get_buffer(24)
		if buf.size() < 24:
			printerr("Index buffer too small! Skipping.")
			return
		var x = buf.decode_s64(0)
		var y = buf.decode_s64(8)
		var index = buf.decode_u64(16)
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

func _encode_portal_coords(portal: Vector4i) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(18)
	result.encode_s64(0, portal.x)
	result.encode_s64(8, portal.y)
	result.encode_u8(16, portal.z)
	result.encode_u8(17, portal.w)
	return result


func save_nav_data(portals: Array[Vector4i], portal_connections: Dictionary):
	var index_data : PackedByteArray = []
	var data : PackedByteArray = []

	var index_file = _open_file(_current_save_path + "/navigation/index.dat")

	var data_file = _open_file(_current_save_path + "/navigation/data.dat")

	data_file.seek_end()
	index_file.seek_end()

	for portal in portals:
		if not portal_connections.has(portal):
			continue

		var target_portals: Array = []
		for target_portal in portal_connections[portal]:
			if target_portal is Vector4i:
				target_portals.append(target_portal)
		if target_portals.is_empty():
			continue

		var encoded_portal := _encode_portal_coords(portal)
		index_data.append_array(encoded_portal)
		index_data.resize(index_data.size() + 8)
		index_data.encode_u64(index_data.size() - 8, data_file.get_position() + data.size())
		data.append_array(encoded_portal)
		# Number of portal connections
		data.resize(data.size() + 1)
		data.encode_u8(data.size() - 1, target_portals.size())
		for target_portal in target_portals:
			data.append_array(_encode_portal_coords(target_portal))
			# Number of connections
			data.resize(data.size() + 1)
			data.encode_u8(data.size() - 1, portal_connections[portal][target_portal].size())
			for j in portal_connections[portal][target_portal]:
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
	var data_indices_buffer : PackedByteArray = []
	var pos = _current_world_file.get_length()
	_current_world_file.seek(pos)
	for i in _chunks_to_save:
		update_chunk_index(i.coords, pos)
		var header = PackedByteArray([])
		header.resize(8)
		header.encode_u64(0, i.data.size())
		data.append_array(header)
		data.append_array(i.data)
		pos += i.data.size() + 8

	for i in data_indices.size():
		var key = data_indices.keys()[i]
		data_indices_buffer.resize(data_indices_buffer.size() + 24)
		data_indices_buffer.encode_s64(24*i, key.x)
		data_indices_buffer.encode_s64(24*i + 8, key.y)
		data_indices_buffer.encode_u64(24*i + 16, data_indices[key])

	# Clear the index file to prevent confusion between old and new data
	FileAccess.open(_current_save_path + "/index.dat", FileAccess.WRITE).close()
	_current_index_file.store_buffer(data_indices_buffer)

	if not data.is_empty():
		_current_world_file.store_buffer(data)
		_chunks_to_save.clear()

func _open_file(path : String) -> FileAccess:
	return FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE_READ)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if get_tree().current_scene.name == "game":
			for i in GlobalRef.chunks.keys():
				if GlobalRef.get_chunk(i) and GlobalRef.get_chunk(i).dirty:
					save_chunk(i)
			_on_write_timer_timeout()

			save_nav_data(pathfinder.portals, pathfinder.portal_connections)

		get_tree().quit()
