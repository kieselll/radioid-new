extends Node
class_name Saver

## Autoload responsible for persisting save slots, chunk data, entity state, and
## pathfinding navigation caches.
##
## World chunk data is written in an append-only binary format. Recent chunk
## changes are first queued in memory, then periodically flushed to disk and
## mirrored into an index so chunks can be loaded back by coordinate.

#region vars
## Absolute path of the save slot currently opened for reading/writing.
var _current_save_path : String = ""
## Metadata for the currently active save slot.
var current_save : SaveMeta
## Binary data file that stores serialized chunk payloads.
var _current_world_file : FileAccess
## Index file mapping chunk coordinates to offsets inside [member _current_world_file].
var _current_world_index_file : FileAccess
## Small file storing the next entity ID for the save.
var _current_entity_index_file : FileAccess
## Root directory that contains all save slot folders.
@export var _save_dir_path : String = "user://game/saves/"
## Root game directory used by related save systems.
@export var _game_dir_path : String = "user://game/"
## Runtime reference to the global pathfinder used for nav graph persistence.
@onready var pathfinder : GlobalPathfinder

## Timer that batches disk writes instead of writing every chunk immediately.
var write_timer : Timer = Timer.new()
## In-memory queue of dirty chunks waiting to be flushed to disk.
var _chunks_to_save : Array = []
## Map of chunk coordinate to byte offset inside [member _current_world_file].
var data_indices : Dictionary[Vector2i, int]
#endregion

#region classes
## Lightweight container for user-facing save metadata stored in [code]meta.json[/code].
class SaveMeta:
	## Timestamp captured when the save slot was first created.
	var creation_date : Dictionary
	## Timestamp updated when the slot is modified.
	var modified_date : Dictionary
	## Name shown in the save selection UI.
	var display_name : String
	## Total accumulated playtime for the slot, in seconds.
	var playtime : int
	## Seed used to generate the world for this slot.
	var world_seed : int
	## Game version that created or last updated the slot.
	var version : String

	## Initializes metadata with the current system time and project version.
	@warning_ignore("shadowed_variable")
	func _init():
		creation_date = Time.get_datetime_dict_from_system()
		modified_date = creation_date
		version = ProjectSettings.get_setting("application/config/version")
		playtime = 0

	## Serializes this metadata object into the JSON string stored on disk.
	func jsonify() -> String:
		return JSON.stringify({
			"creation_date" : creation_date,
			"modified_date" : modified_date,
			"display_name" : display_name,
			"playtime": playtime,
			"world_seed": world_seed,
			"version": version
			})

	## Populates this metadata object from a previously serialized JSON string.
	func dejsonify(json_string : String) -> void:
		var dict = JSON.parse_string(json_string)
		if not dict: return
		creation_date = dict["creation_date"]
		modified_date = dict["modified_date"]
		display_name = dict["display_name"]
		playtime = dict["playtime"]
		world_seed = dict["world_seed"]
		version = dict["version"]
#endregion


#region save slots
## Returns the directory names of all save slots currently present on disk.
func get_saves_list() -> Array:
	return DirAccess.open(_save_dir_path).get_directories()

## Creates or overwrites the active save slot and opens its core data files.
##
## This prepares the world, chunk-index, and entity-index files so subsequent
## save operations can append data without reopening everything each time.
func write_save(dirname : String, display_name : String, world_seed : int) -> void:
	current_save = SaveMeta.new()
	current_save.display_name = display_name
	current_save.world_seed = world_seed
	_current_save_path = _save_dir_path + dirname
	if not DirAccess.dir_exists_absolute(_current_save_path):
		DirAccess.make_dir_recursive_absolute(_current_save_path)
	if not DirAccess.dir_exists_absolute(_current_save_path + "/navigation"):
		DirAccess.make_dir_recursive_absolute(_current_save_path + "/navigation")
	if not DirAccess.dir_exists_absolute(_current_save_path + "/entities"):
		DirAccess.make_dir_recursive_absolute(_current_save_path + "/entities")
	_current_world_file = _open_file(_current_save_path + "/world.dat")
	_current_world_index_file = _open_file(_current_save_path + "/index.dat")
	_current_entity_index_file = _open_file(_current_save_path + "/entities/index.dat")
	var _meta_file = FileAccess.open(_current_save_path + "/meta.json", FileAccess.WRITE)
	_meta_file.store_string(current_save.jsonify())

## Opens an existing save slot, rebuilds the in-memory chunk index, and returns
## its metadata for UI/gameplay consumption.
func load_save(dirname : String) -> SaveMeta:
	_current_save_path = _save_dir_path + dirname
	var _new_save = get_save_meta(dirname)
	_current_world_file = _open_file(_current_save_path + "/world.dat")
	_current_world_index_file = _open_file(_current_save_path + "/index.dat")
	_current_entity_index_file = _open_file(_current_save_path + "/entities/index.dat")
	_current_world_index_file.seek(0)
	while _current_world_index_file.get_position() + 16 < _current_world_index_file.get_length():
		var buf = _current_world_index_file.get_buffer(24)
		if buf.size() < 24:
			printerr("Index buffer too small! Skipping.")
			return
		var x = buf.decode_s64(0)
		var y = buf.decode_s64(8)
		var index = buf.decode_u64(16)
		data_indices[Vector2i(x, y)] = index
	return _new_save

## Moves the given save slot to the operating system trash.
func delete_save(dirname : String) -> void:
	OS.move_to_trash(ProjectSettings.globalize_path(_save_dir_path.path_join(dirname)))
	GlobalLogger.write_to_logs(self, "Deleted save %s" % dirname)

## Reads and deserializes the metadata file for a single save slot.
func get_save_meta(dirname : String) -> SaveMeta:
	var _new_save = SaveMeta.new()
	var save_path = _save_dir_path + dirname
	var fileacc = FileAccess.open(save_path + "/meta.json", FileAccess.READ_WRITE)
	_new_save.dejsonify(fileacc.get_as_text())
	return _new_save
#endregion

#region world data
## Queues a chunk for saving and serializes its entities into a sidecar file.
##
## Chunk tile data is converted to bytes immediately, but the actual disk write
## happens later in [method _on_write_timer_timeout].
func save_chunk(coords : Vector2i):
	var chunk = GlobalRef.get_chunk(coords)
	_chunks_to_save.append({"coords" = coords, "data" = var_to_bytes(chunk.get_cells_rle())})
	var entity_manager : EntityManager = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.entity_manager))
	if entity_manager.serialize_chunk(coords).is_empty() and\
	not FileAccess.file_exists(_current_save_path + "/entities/" + str(coords) + ".json"): return
	elif FileAccess.file_exists(_current_save_path + "/entities/" + str(coords) + ".json") and\
	entity_manager.serialize_chunk(coords).is_empty():
		DirAccess.remove_absolute(_current_save_path + "/entities/" + str(coords) + ".json")
		print("deleted thing")
	else:
		var _entity_file_access = FileAccess.open(_current_save_path + "/entities/" + str(coords) + ".json", FileAccess.WRITE)
		_entity_file_access.store_string(JSON.stringify(entity_manager.serialize_chunk(coords)))

## Returns the decoded RLE cell payload for the chunk at [param coords].
##
## The method first checks the in-memory write queue so reads can see unsaved
## changes. If the chunk is not queued, it uses [member data_indices] to seek to
## the latest append-only record inside [member _current_world_file].
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

## Loads the serialized entity payload associated with the given chunk.
func read_chunk_entities(coords: Vector2i):
	if FileAccess.file_exists(_current_save_path + "/entities/" + str(coords) + ".json"):
		var entity_file = FileAccess.open(_current_save_path + "/entities/" + str(coords) + ".json", FileAccess.READ)
		return JSON.parse_string(entity_file.get_as_text())
	return {}

## Returns the next entity ID stored for the current save slot.
##
## A missing or uninitialized entity index falls back to [code]0[/code].
func load_current_entity_id() -> int:
	if _current_entity_index_file and FileAccess.get_size(_current_save_path + "/entities/index.dat") == 8:
		return _current_entity_index_file.get_64()
	return 0

## Updates the in-memory byte offset for a chunk inside [member data_indices].
func update_chunk_index(coords: Vector2i, new_position: int) -> void:
	data_indices[coords] = new_position

## Flushes queued chunks to disk and rewrites the chunk/entity indices.
##
## Each chunk is written as an 8-byte size header followed by the raw serialized
## payload. After the batch completes, the index file is regenerated from the
## current [member data_indices] map so only the latest offsets remain.
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
	_current_world_index_file.store_buffer(data_indices_buffer)

	if not data.is_empty():
		_current_world_file.store_buffer(data)
		_chunks_to_save.clear()

	_current_entity_index_file.close()
	_current_entity_index_file = FileAccess.open(_current_save_path + "/entities/index.dat", FileAccess.WRITE_READ)
	_current_entity_index_file.store_64(get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.entity_manager)).next_entity_id)
#endregion


#region navigation data
## Packs a portal coordinate into the compact 18-byte format used by nav caches.
func _encode_portal_coords(portal: Vector4i) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(18)
	result.encode_s64(0, portal.x)
	result.encode_s64(8, portal.y)
	result.encode_u8(16, portal.z)
	result.encode_u8(17, portal.w)
	return result


## Serializes portal connectivity data for the current world into navigation files.
##
## The index file stores each portal and the offset of its detailed record inside
## [code]navigation/data.dat[/code]. Each detailed record contains the portal,
## its reachable target portals, and the weighted connection steps between them.
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

	GlobalLogger.write_to_logs(self, "Saved nav data, closing files...")
	data_file.store_buffer(data)
	index_file.store_buffer(index_data)
	data_file.close()
	index_file.close()
#endregion


#region lifecycle
## Starts the periodic write timer used to batch save operations.
func _ready() -> void:
	add_child(write_timer)
	write_timer.start(2)
	write_timer.connect("timeout", _on_write_timer_timeout)

## Caches the live pathfinder once the world scene has been initialized.
func world_init():
	pathfinder = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.pathfinder))

## Ensures the current game state is saved before the application exits.
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()
		get_tree().quit()
#endregion


#region helpers
## Opens a file for both reading and writing, creating it first if needed.
func _open_file(path : String) -> FileAccess:
	return FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE_READ)
#endregion


#region API
## Saves all dirty runtime state for the active game session.
##
## Dirty chunks are queued, flushed immediately, and followed by navigation data
## persistence when the current scene is [code]GameRoot[/code].
func save():
	if get_tree().current_scene.name == "GameRoot":
		for i in GlobalRef.chunks.keys():
			if GlobalRef.get_chunk(i) and GlobalRef.get_chunk(i).dirty:
				save_chunk(i)
		_on_write_timer_timeout()
		save_nav_data(pathfinder.portals, pathfinder.portal_connections)
	GlobalLogger.write_to_logs(self, "Saved everything, quitting")
#endregion
