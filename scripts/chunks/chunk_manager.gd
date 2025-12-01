@icon("res://textures/editor_icons/wireframe-globe.svg")
extends Node
class_name ChunkManager

@export var cam : Camera2D
@export var chunk_scene : PackedScene
var chunks : Dictionary[Vector2i, Node]
var load_queue : Array[Vector2i]
var unload_queue : Array[Vector2i]
var current_chunk : Vector2i
var old_chunk : Vector2i
var world_seed = randi()
var tilemap : TileMap

const CHUNK_SIZE = 16
@export var render_distance : int = 10

signal current_chunk_changed(new_chunk_coords : Vector2i)

class Chunk:
	var ground_layer : Array
	var terrain_layer : Array
	var wall_layer : Array
	var terrain_queued_layer : Array
	var wall_queued_layer : Array
	var terrain_queued_d_layer : Array
	var wall_queued_d_layer : Array

func generate_new_layer(coords : Vector2i, layer : GlobalRef.tilemap_layers_enum, _seed : int) -> Array: #CRITICAL WIP
	var tile_array : Array = []
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

func generate_new_chunk(coords : Vector2i, _seed : int) -> Chunk:
	var chunk = Chunk.new()
	chunk.ground_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.ground, _seed)
	chunk.terrain_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.terrain, _seed)
	chunk.wall_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.walls, _seed)
	chunk.terrain_queued_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.terrain_queued, _seed)
	chunk.wall_queued_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.walls_queued, _seed)
	chunk.terrain_queued_d_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.terrain_queued_d, _seed)
	chunk.wall_queued_d_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.walls_queued_d, _seed)
	return chunk

func instantiate_chunk(coords : Vector2i, _seed : int) -> void:
	var new_chunk : Chunk
	var chunk_node : Node2D
	new_chunk = generate_new_chunk(coords, _seed)
	chunk_node = chunk_scene.instantiate()
	tilemap.add_child(chunk_node)
	chunks[coords] = chunk_node
	chunk_node.position = (coords) * CHUNK_SIZE * 32 + Vector2i(16,16)
	GlobalRef.add_chunk(coords, chunk_node)

	@warning_ignore("integer_division")
	for i in CHUNK_SIZE:
		for j in CHUNK_SIZE:
			chunk_node.set_cell(new_chunk.ground_layer[i][j], Vector2i(i, j), false, true)
			chunk_node.set_cell(new_chunk.terrain_layer[i][j], Vector2i(i, j), false, true)
			chunk_node.set_cell(new_chunk.wall_layer[i][j], Vector2i(i, j), false, true)
			chunk_node.set_cell(new_chunk.terrain_queued_layer[i][j], Vector2i(i, j), false, true)
			chunk_node.set_cell(new_chunk.wall_queued_layer[i][j], Vector2i(i, j), false, true)
			chunk_node.set_cell(new_chunk.terrain_queued_d_layer[i][j], Vector2i(i, j), false, true)
			chunk_node.set_cell(new_chunk.wall_queued_d_layer[i][j], Vector2i(i, j), false, true)

func _ready() -> void:
	var gen_chunk_x := 0
	var gen_chunk_y := 0
	var coord_x := 0
	var coord_y := 0
	var new_chunk : Chunk = null
	var chunk_node : Node2D
	tilemap = get_node(GlobalRef.get_game_node_path(GlobalRef.game_nodes_enum.tilemap))

	while gen_chunk_x != render_distance and gen_chunk_y != render_distance:
		if not new_chunk and not chunks.has(Vector2i(gen_chunk_x, gen_chunk_y)):
			new_chunk = generate_new_chunk(Vector2i(gen_chunk_x, gen_chunk_y), world_seed)
			chunk_node = chunk_scene.instantiate()
			tilemap.add_child(chunk_node)
			chunks[Vector2i(gen_chunk_x, gen_chunk_y)] = chunk_node
			chunk_node.position = (Vector2i(gen_chunk_x, gen_chunk_y) + current_chunk) * CHUNK_SIZE * 32 + Vector2i(16,16)

			@warning_ignore("integer_division")
			for i in CHUNK_SIZE*CHUNK_SIZE:
				chunk_node.set_cell(new_chunk.ground_layer[coord_x][coord_y], Vector2i(coord_x, coord_y), false, true)
				chunk_node.set_cell(new_chunk.terrain_layer[coord_x][coord_y], Vector2i(coord_x, coord_y), false, true)
				chunk_node.set_cell(new_chunk.wall_layer[coord_x][coord_y], Vector2i(coord_x, coord_y), false, true)
				chunk_node.set_cell(new_chunk.terrain_queued_layer[coord_x][coord_y], Vector2i(coord_x, coord_y), false, true)
				chunk_node.set_cell(new_chunk.wall_queued_layer[coord_x][coord_y], Vector2i(coord_x, coord_y), false, true)
				chunk_node.set_cell(new_chunk.terrain_queued_d_layer[coord_x][coord_y], Vector2i(coord_x, coord_y), false, true)
				chunk_node.set_cell(new_chunk.wall_queued_d_layer[coord_x][coord_y], Vector2i(coord_x, coord_y), false, true)

				if coord_x + 1 == CHUNK_SIZE:
					coord_x = 0
					coord_y += 1
					if coord_y == CHUNK_SIZE:
						coord_x = 0
						coord_y = 0
						new_chunk = null
						GlobalRef.add_chunk(Vector2i(gen_chunk_x, gen_chunk_y), chunk_node)
						print(gen_chunk_x, " ", gen_chunk_y)
						if gen_chunk_x + 1 == render_distance:
							gen_chunk_x = 0
							gen_chunk_y += 1
						else:
							gen_chunk_x += 1
				else:
					coord_x += 1
	new_chunk = null

func _process(_delta: float) -> void:
	if not unload_queue.is_empty() and chunks.has(unload_queue[-1]) and is_instance_valid(chunks[unload_queue[-1]]):
		chunks[unload_queue[-1]].queue_free()
		chunks.erase(unload_queue[-1])
		unload_queue.remove_at(-1)
	if not load_queue.is_empty():
		instantiate_chunk(load_queue[-1], world_seed)
		load_queue.remove_at(-1)
		return
	set_process(false)

func _physics_process(_delta: float) -> void:
	var chunk_cam_coords : Vector4i = world_coord_to_chunk_coord(get_node(GlobalRef.get_game_node_path(GlobalRef.game_nodes_enum.tilemap)).local_to_map(cam.position))
	current_chunk = Vector2i(chunk_cam_coords.x, chunk_cam_coords.y)
	if old_chunk == null or old_chunk != current_chunk:
		current_chunk_changed.emit(current_chunk)
		old_chunk = current_chunk
		for i in chunks.keys():
			@warning_ignore("integer_division")
			if not Rect2i(current_chunk - Vector2i(render_distance/2, render_distance/2), Vector2i(render_distance, render_distance)).has_point(i):
				unload_queue.append(i)
		for i in render_distance:
			for j in render_distance:
				@warning_ignore("integer_division")
				if not chunks.has(Vector2i(i, j) + current_chunk - Vector2i(render_distance/2, render_distance/2)) and not load_queue.has(Vector2i(i, j) + current_chunk - Vector2i(render_distance/2, render_distance/2)):
					@warning_ignore("integer_division")
					load_queue.append(Vector2i(i, j) + current_chunk - Vector2i(render_distance/2, render_distance/2))
		set_process(true)

func chunk_coord_to_world_coord(chunk_coords : Vector4i) -> Vector2i:
	return Vector2i(
		chunk_coords.x * CHUNK_SIZE + chunk_coords.z,
		chunk_coords.y * CHUNK_SIZE + chunk_coords.w
	)

func world_coord_to_chunk_coord(coord : Vector2i) -> Vector4i:
	@warning_ignore("integer_division")
	return Vector4i(
		coord.x / CHUNK_SIZE,
		coord.y / CHUNK_SIZE,
		coord.x % CHUNK_SIZE,
		coord.y % CHUNK_SIZE
	)
