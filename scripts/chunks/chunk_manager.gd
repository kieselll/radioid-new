@icon("res://textures/editor_icons/wireframe-globe.svg")
extends Node
class_name ChunkManager

#region Private Vars

var chunks: Dictionary[Vector2i, Node]
var chunk_cam_coords: Vector4i = Vector4i.ZERO
var load_queue: Array[Vector2i]
var unload_queue: Array[Vector2i]

var current_chunk: Vector2i
var old_chunk: Vector2i

var world_seed
var tilemap: TileMap

#endregion

#region Public Exported Fields

@export var cam: Camera2D
@export var chunk_scene: PackedScene
@export var render_distance: int = 10

#endregion

#region Constants

const CHUNK_SIZE = 16

#endregion

#region Private Classes

class ChunkData:
	var ground_layer: Array
	var terrain_layer: Array
	var wall_layer: Array
	var terrain_queued_layer: Array
	var wall_queued_layer: Array
	var terrain_queued_d_layer: Array
	var wall_queued_d_layer: Array

#endregion

#region Signals

signal current_chunk_changed(new_chunk_coords: Vector2i)
signal chunk_deleted(coords: Vector2i)
signal chunk_generated(coords: Vector2i)

#endregion

#region Lifecycle

func _ready() -> void:
	world_seed = GlobalSaver.current_save.world_seed if GlobalSaver.current_save else randi()
	GlobalItems.bind_chunk_manager(self)

func _process(_delta: float) -> void:
	if (
		not unload_queue.is_empty()
		and chunks.has(unload_queue[-1])
		and is_instance_valid(chunks[unload_queue[-1]])
	):
		if chunks[unload_queue[-1]].dirty:
			GlobalSaver.save_chunk(unload_queue[-1])
		chunks[unload_queue[-1]].queue_free()
		chunk_deleted.emit(unload_queue[-1])
		chunks.erase(unload_queue[-1])
		unload_queue.remove_at(-1)

	if not load_queue.is_empty():
		var loaded_chunk = GlobalSaver.read_chunk(load_queue[-1])
		if not loaded_chunk:
			instantiate_chunk(generate_new_chunk(load_queue[-1], world_seed), load_queue[-1])
		else:
			instantiate_chunk(decompress_chunk(loaded_chunk), load_queue[-1])
		var entities : Dictionary = GlobalSaver.read_chunk_entities(load_queue[-1])
		var entity_manager : EntityManager = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.entity_manager))
		for entity in entities.values():
			entity_manager.deserialize_entity(entity)
		load_queue.remove_at(-1)
		return
	set_process(false)


func _physics_process(_delta: float) -> void:
	chunk_cam_coords = GridUtils.world_coord_to_chunk_coord(cam.position)
	current_chunk = Vector2i(chunk_cam_coords.x, chunk_cam_coords.y)

	if old_chunk == null or old_chunk != current_chunk:
		current_chunk_changed.emit(current_chunk)
		old_chunk = current_chunk

		# Mark chunks for unload
		for i in chunks.keys():
			@warning_ignore("integer_division")
			if not (
				Rect2i(
					current_chunk - Vector2i(render_distance / 2, render_distance / 2),
					Vector2i(render_distance, render_distance)
				)
				. has_point(i)
			):
				unload_queue.append(i)

		var temp_load: Array[Vector2i] = []
		# Mark chunks for load
		for i in render_distance:
			for j in render_distance:
				@warning_ignore("integer_division")
				var coords := (
					Vector2i(i, j)
					+ current_chunk
					- Vector2i(render_distance / 2, render_distance / 2)
				)

				if not chunks.has(coords) and not load_queue.has(coords):
					@warning_ignore("integer_division")
					temp_load.append(coords)
		temp_load.sort_custom(
			func(a, b):
				return (
					abs(current_chunk.x - a.x) + abs(current_chunk.y - a.y)
					> abs(current_chunk.x - b.x) + abs(current_chunk.y - b.y)
				)
		)
		load_queue = temp_load

		set_process(true)

#endregion

#region Chunk Data

func generate_new_layer(
	coords: Vector2i, layer: GlobalRef.tilemap_layers_enum, _seed: int
) -> Array:  # CRITICAL WIP
	var tile_array: Array = []
	tile_array.resize(CHUNK_SIZE)

	if layer == GlobalRef.tilemap_layers_enum.ground:
		for i in CHUNK_SIZE:
			tile_array[i] = []
			for j in CHUNK_SIZE:
				tile_array[i].resize(CHUNK_SIZE)
				tile_array[i][j] = 4
	else:
		for i in CHUNK_SIZE:
			tile_array[i] = []
			for j in CHUNK_SIZE:
				tile_array[i].resize(CHUNK_SIZE)
				tile_array[i][j] = -1

	return tile_array


func decompress_chunk(compressed_chunk: Array) -> ChunkData:
	var chunk = ChunkData.new()
	chunk.ground_layer = decompress_layer(compressed_chunk[GlobalRef.tilemap_layers_enum.ground])
	chunk.terrain_layer = decompress_layer(compressed_chunk[GlobalRef.tilemap_layers_enum.terrain])
	chunk.wall_layer = decompress_layer(compressed_chunk[GlobalRef.tilemap_layers_enum.walls])
	chunk.terrain_queued_layer = decompress_layer(
		compressed_chunk[GlobalRef.tilemap_layers_enum.terrain_queued]
	)
	chunk.wall_queued_layer = decompress_layer(
		compressed_chunk[GlobalRef.tilemap_layers_enum.walls_queued]
	)
	chunk.terrain_queued_d_layer = decompress_layer(
		compressed_chunk[GlobalRef.tilemap_layers_enum.terrain_queued_d]
	)
	chunk.wall_queued_d_layer = decompress_layer(
		compressed_chunk[GlobalRef.tilemap_layers_enum.walls_queued_d]
	)
	return chunk


func decompress_layer(compressed_layer: Array) -> Array:
	var result = []
	result.resize(CHUNK_SIZE)
	for x in CHUNK_SIZE:
		result[x] = []
		result[x].resize(CHUNK_SIZE)
	var intermediate_result: Array = []
	for i in compressed_layer:
		var array_insert: Array = []
		array_insert.resize(i.y)
		array_insert.fill(i.x)
		intermediate_result.append_array(array_insert)
	for i in intermediate_result.size():
		@warning_ignore("integer_division")
		result[i / CHUNK_SIZE][i % CHUNK_SIZE] = intermediate_result[i]
	return result


func generate_new_chunk(coords: Vector2i, _seed: int) -> ChunkData:
	var chunk = ChunkData.new()

	chunk.ground_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.ground, _seed)
	chunk.terrain_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.terrain, _seed)
	chunk.wall_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.walls, _seed)

	chunk.terrain_queued_layer = generate_new_layer(
		coords, GlobalRef.tilemap_layers_enum.terrain_queued, _seed
	)
	chunk.wall_queued_layer = generate_new_layer(
		coords, GlobalRef.tilemap_layers_enum.walls_queued, _seed
	)
	chunk.terrain_queued_d_layer = generate_new_layer(
		coords, GlobalRef.tilemap_layers_enum.terrain_queued_d, _seed
	)
	chunk.wall_queued_d_layer = generate_new_layer(
		coords, GlobalRef.tilemap_layers_enum.walls_queued_d, _seed
	)

	return chunk


func instantiate_chunk(new_chunk: ChunkData, coords: Vector2i) -> void:
	var chunk_node: Node2D

	chunk_node = chunk_scene.instantiate()

	add_child(chunk_node)
	chunks[coords] = chunk_node

	chunk_node.position = coords * CHUNK_SIZE * 32 + Vector2i(16, 16)
	GlobalRef.add_chunk(coords, chunk_node)

	@warning_ignore("integer_division")
	for i in CHUNK_SIZE:
		for j in CHUNK_SIZE:
			chunk_node.set_cell(
				new_chunk.ground_layer[i][j], Vector2i(i, j), GlobalRef.tilemap_layers_enum.ground
			)
			chunk_node.set_cell(
				new_chunk.terrain_layer[i][j], Vector2i(i, j), GlobalRef.tilemap_layers_enum.terrain
			)
			chunk_node.set_cell(
				new_chunk.wall_layer[i][j], Vector2i(i, j), GlobalRef.tilemap_layers_enum.walls
			)
			chunk_node.set_cell(
				new_chunk.terrain_queued_layer[i][j],
				Vector2i(i, j),
				GlobalRef.tilemap_layers_enum.terrain_queued
			)
			chunk_node.set_cell(
				new_chunk.wall_queued_layer[i][j],
				Vector2i(i, j),
				GlobalRef.tilemap_layers_enum.walls_queued
			)
			chunk_node.set_cell(
				new_chunk.terrain_queued_d_layer[i][j],
				Vector2i(i, j),
				GlobalRef.tilemap_layers_enum.terrain_queued_d
			)
			chunk_node.set_cell(
				new_chunk.wall_queued_d_layer[i][j],
				Vector2i(i, j),
				GlobalRef.tilemap_layers_enum.walls_queued_d
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
