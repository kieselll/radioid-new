@icon("res://textures/editor_icons/wireframe-globe.svg")
extends Node
class_name ChunkManager

#region Private Vars

var chunks: Dictionary[Vector2i, Chunk]
var chunk_cam_coords: Vector4i = Vector4i.ZERO
var load_queue: Array[Vector2i]
var unload_queue: Array[Vector2i]

var current_chunk: Vector2i
var old_chunk: Vector2i
var _stream_center_initialized := false

var world_seed: int
var tilemap: TileMap

var render_distance: int

#endregion

#region Public Exported Fields

@export var cam: Camera2D
@export var chunk_scene: PackedScene

#endregion

#region Constants

const CHUNK_SIZE = 16

#endregion

#region Private Classes

class ChunkData:
	var ground_layer: Array = []
	var terrain_layer: Array = []
	var wall_layer: Array = []
	var terrain_queued_layer: Array = []
	var wall_queued_layer: Array = []
	var terrain_queued_d_layer: Array = []
	var wall_queued_d_layer: Array = []

#endregion

#region Signals

signal current_chunk_changed(new_chunk_coords: Vector2i)
signal chunk_deleted(coords: Vector2i)
signal chunk_generated(coords: Vector2i)

#endregion

#region Lifecycle

func _ready() -> void:
	@warning_ignore("unsafe_call_argument")
	render_distance = int(GlobalCfg.get_setting("graphics", "render_distance", render_distance))
	world_seed = GlobalSaver.current_save.world_seed if GlobalSaver.current_save else randi()

func _process(_delta: float) -> void:
	if not unload_queue.is_empty():
		var unload_coords: Vector2i = unload_queue.pop_back()
		if chunks.has(unload_coords):
			var chunk: Chunk = chunks[unload_coords]
			if is_instance_valid(chunk):
				if chunk.dirty:
					GlobalSaver.save_chunk(unload_coords)
				chunk.queue_free()
			chunk_deleted.emit(unload_coords)
			chunks.erase(unload_coords)

	if not load_queue.is_empty():
		var loaded_chunk: Variant = GlobalSaver.read_chunk(load_queue[-1])
		if not loaded_chunk:
			instantiate_chunk(generate_new_chunk(load_queue[-1], world_seed), load_queue[-1])
		elif loaded_chunk is Array:
			instantiate_chunk(decompress_chunk(loaded_chunk as Array), load_queue[-1])
		var entities : Dictionary = GlobalSaver.read_chunk_entities(load_queue[-1])
		var entity_manager : EntityManager = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.entity_manager))
		for entity: Dictionary in entities.values():
			entity_manager.deserialize_entity(entity)
		load_queue.remove_at(-1)
		return

	# Rapid center changes can invalidate work between physics frames. Before
	# sleeping, reconcile the final render rectangle so stationary cameras cannot
	# retain holes left by superseded queue contents.
	if _queue_missing_visible_chunks():
		return
	set_process(false)


func _physics_process(_delta: float) -> void:
	chunk_cam_coords = GridUtils.world_coord_to_chunk_coord(cam.position)
	current_chunk = Vector2i(chunk_cam_coords.x, chunk_cam_coords.y)

	if not _stream_center_initialized or old_chunk != current_chunk:
		current_chunk_changed.emit(current_chunk)
		old_chunk = current_chunk
		_stream_center_initialized = true

		# Rebuild rather than append: an old queued chunk may have become visible
		# again before its unload job ran.
		unload_queue.clear()
		for i: Vector2i in chunks:
			@warning_ignore("integer_division")
			if not (
				Rect2i(
					current_chunk - Vector2i(render_distance / 2, render_distance / 2),
					Vector2i(render_distance, render_distance)
				)
				. has_point(i)
			):
				unload_queue.append(i)

		load_queue.clear()
		_queue_missing_visible_chunks()

		set_process(true)


func _queue_missing_visible_chunks() -> bool:
	var queued_any := false
	for i: int in render_distance:
		for j: int in render_distance:
			@warning_ignore("integer_division")
			var coords := (
				Vector2i(i, j)
				+ current_chunk
				- Vector2i(render_distance / 2, render_distance / 2)
			)
			var has_live_chunk := chunks.has(coords) and is_instance_valid(chunks[coords])
			if has_live_chunk or load_queue.has(coords):
				continue
			if chunks.has(coords):
				chunks.erase(coords)
			load_queue.append(coords)
			queued_any = true

	if queued_any:
		load_queue.sort_custom(
			func(a: Vector2i, b: Vector2i) -> bool:
				return (
					abs(current_chunk.x - a.x) + abs(current_chunk.y - a.y)
					> abs(current_chunk.x - b.x) + abs(current_chunk.y - b.y)
				)
		)
	return queued_any

#endregion

#region Chunk Data

func generate_new_layer(
	_coords: Vector2i, layer: GlobalRef.tilemap_layers_enum, _seed: int
) -> Array:  # CRITICAL WIP
	var tile_array: Array = []
	tile_array.resize(CHUNK_SIZE)
	var default_id := 4 if layer == GlobalRef.tilemap_layers_enum.ground else -1
	for x in CHUNK_SIZE:
		var row: Array[int] = []
		row.resize(CHUNK_SIZE)
		row.fill(default_id)
		tile_array[x] = row

	return tile_array


func decompress_chunk(compressed_chunk: Array) -> ChunkData:
	var chunk := ChunkData.new()
	var ground_data: Array = compressed_chunk[GlobalRef.tilemap_layers_enum.ground]
	var terrain_data: Array = compressed_chunk[GlobalRef.tilemap_layers_enum.terrain]
	var wall_data: Array = compressed_chunk[GlobalRef.tilemap_layers_enum.walls]
	chunk.ground_layer = decompress_layer(ground_data)
	chunk.terrain_layer = decompress_layer(terrain_data)
	chunk.wall_layer = decompress_layer(wall_data)
	var terrain_queued_data: Array = compressed_chunk[GlobalRef.tilemap_layers_enum.terrain_queued]
	chunk.terrain_queued_layer = decompress_layer(
		terrain_queued_data
	)
	var wall_queued_data: Array = compressed_chunk[GlobalRef.tilemap_layers_enum.walls_queued]
	chunk.wall_queued_layer = decompress_layer(
		wall_queued_data
	)
	var terrain_delete_data: Array = compressed_chunk[GlobalRef.tilemap_layers_enum.terrain_queued_d]
	chunk.terrain_queued_d_layer = decompress_layer(
		terrain_delete_data
	)
	var wall_delete_data: Array = compressed_chunk[GlobalRef.tilemap_layers_enum.walls_queued_d]
	chunk.wall_queued_d_layer = decompress_layer(
		wall_delete_data
	)
	return chunk


func decompress_layer(compressed_layer: Array) -> Array:
	var result: Array = []
	result.resize(CHUNK_SIZE)
	for x: int in CHUNK_SIZE:
		var row: Array[int] = []
		row.resize(CHUNK_SIZE)
		result[x] = row
	var intermediate_result: Array = []
	for i: Vector2i in compressed_layer:
		var array_insert: Array = []
		array_insert.resize(i.y)
		array_insert.fill(i.x)
		intermediate_result.append_array(array_insert)
	for i: int in intermediate_result.size():
		@warning_ignore("integer_division")
		var row: Array = result[i / CHUNK_SIZE]
		row[i % CHUNK_SIZE] = intermediate_result[i]
	return result


func generate_new_chunk(coords: Vector2i, _seed: int) -> ChunkData:
	var chunk := ChunkData.new()

	chunk.ground_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.ground, _seed)
	# All other layers are currently empty for a fresh chunk. Chunk initializes
	# every omitted layer to -1, avoiding six redundant grids. When procedural
	# terrain or walls are added, only generate those populated layers here.

	return chunk


func instantiate_chunk(new_chunk: ChunkData, coords: Vector2i) -> void:
	var chunk_node := chunk_scene.instantiate() as Chunk
	assert(chunk_node != null, "Chunk scene must instantiate a Chunk.")

	add_child(chunk_node)
	chunks[coords] = chunk_node

	chunk_node.position = coords * CHUNK_SIZE * 32 + Vector2i(16, 16)
	GlobalRef.add_chunk(coords, chunk_node)

	chunk_node.initialize_cells(
		[
			new_chunk.ground_layer,
			new_chunk.terrain_layer,
			new_chunk.wall_layer,
			new_chunk.terrain_queued_layer,
			new_chunk.wall_queued_layer,
			new_chunk.terrain_queued_d_layer,
			new_chunk.wall_queued_d_layer,
		]
	)

	chunk_generated.emit(coords)

#endregion


#region Public Helpers

func get_render_quad() -> Rect2i:
	@warning_ignore("integer_division")
	return Rect2i(
		chunk_cam_coords.x - render_distance / 2,
		chunk_cam_coords.y - render_distance / 2,
		render_distance,
		render_distance
	)

#endregion
