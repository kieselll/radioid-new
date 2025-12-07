@icon("res://textures/editor_icons/wireframe-globe.svg")
extends Node
class_name ChunkManager

#				 /$$$$$$$              /$$                           /$$
#				| $$__  $$            |__/                          | $$
#				| $$  \ $$   /$$$$$$   /$$  /$$    /$$   /$$$$$$   /$$$$$$     /$$$$$$
#				| $$$$$$$/  /$$__  $$ | $$ |  $$  /$$/  |____  $$ |_  $$_/    /$$__  $$
#				| $$____/  | $$  \__/ | $$  \  $$/$$/    /$$$$$$$   | $$     | $$$$$$$$
#				| $$       | $$       | $$   \  $$$/    /$$__  $$   | $$ /$$ | $$_____/
#				| $$       | $$       | $$    \  $/    |  $$$$$$$   |  $$$$/ |  $$$$$$$
#				|__/       |__/       |__/     \_/      \_______/    \___/    \_______/

#				 /$$    /$$   /$$$$$$    /$$$$$$    /$$$$$$$
#				|  $$  /$$/  |____  $$  /$$__  $$  /$$_____/
#				 \  $$/$$/    /$$$$$$$ | $$  \__/ |  $$$$$$
#				  \  $$$/    /$$__  $$ | $$        \____  $$
#				   \  $/    |  $$$$$$$ | $$        /$$$$$$$/
#				    \_/      \_______/ |__/       |_______/

var chunks: Dictionary[Vector2i, Node]
var load_queue: Array[Vector2i]
var unload_queue: Array[Vector2i]

var current_chunk: Vector2i
var old_chunk: Vector2i

var world_seed = randi()
var tilemap: TileMap

#				 /$$$$$$$              /$$        /$$  /$$
#				| $$__  $$            | $$       | $$ |__/
#				| $$  \ $$  /$$   /$$ | $$$$$$$  | $$  /$$   /$$$$$$$
#				| $$$$$$$/ | $$  | $$ | $$__  $$ | $$ | $$  /$$_____/
#				| $$____/  | $$  | $$ | $$  \ $$ | $$ | $$ | $$
#				| $$       | $$  | $$ | $$  | $$ | $$ | $$ | $$
#				| $$       |  $$$$$$/ | $$$$$$$/ | $$ | $$ |  $$$$$$$
#				|__/        \______/  |_______/  |__/ |__/  \_______/

#				 /$$    /$$   /$$$$$$    /$$$$$$    /$$$$$$$
#				|  $$  /$$/  |____  $$  /$$__  $$  /$$_____/
#				 \  $$/$$/    /$$$$$$$ | $$  \__/ |  $$$$$$
#				  \  $$$/    /$$__  $$ | $$        \____  $$
#				   \  $/    |  $$$$$$$ | $$        /$$$$$$$/
#				    \_/      \_______/ |__/       |_______/

@export var cam: Camera2D
@export var chunk_scene: PackedScene
@export var render_distance: int = 10

const CHUNK_SIZE = 16


class Chunk:
	var ground_layer: Array
	var terrain_layer: Array
	var wall_layer: Array
	var terrain_queued_layer: Array
	var wall_queued_layer: Array
	var terrain_queued_d_layer: Array
	var wall_queued_d_layer: Array


#				  /$$$$$$   /$$                                   /$$
#				 /$$__  $$ |__/                                  | $$
#				| $$  \__/  /$$   /$$$$$$   /$$$$$$$    /$$$$$$  | $$   /$$$$$$$
#				|  $$$$$$  | $$  /$$__  $$ | $$__  $$  |____  $$ | $$  /$$_____/
#				 \____  $$ | $$ | $$  \ $$ | $$  \ $$   /$$$$$$$ | $$ |  $$$$$$
#				 /$$  \ $$ | $$ | $$  | $$ | $$  | $$  /$$__  $$ | $$  \____  $$
#				|  $$$$$$/ | $$ |  $$$$$$$ | $$  | $$ |  $$$$$$$ | $$  /$$$$$$$/
#				 \______/  |__/  \____  $$ |__/  |__/  \_______/ |__/ |_______/
#				                 /$$  \ $$
#				                |  $$$$$$/
#				                 \______/

signal current_chunk_changed(new_chunk_coords: Vector2i)

#				 /$$        /$$   /$$$$$$                                               /$$
#				| $$       |__/  /$$__  $$                                             | $$
#				| $$        /$$ | $$  \__/   /$$$$$$    /$$$$$$$  /$$   /$$   /$$$$$$$ | $$   /$$$$$$
#				| $$       | $$ | $$$$      /$$__  $$  /$$_____/ | $$  | $$  /$$_____/ | $$  /$$__  $$
#				| $$       | $$ | $$_/     | $$$$$$$$ | $$       | $$  | $$ | $$       | $$ | $$$$$$$$
#				| $$       | $$ | $$       | $$_____/ | $$       | $$  | $$ | $$       | $$ | $$_____/
#				| $$$$$$$$ | $$ | $$       |  $$$$$$$ |  $$$$$$$ |  $$$$$$$ |  $$$$$$$ | $$ |  $$$$$$$
#				|________/ |__/ |__/        \_______/  \_______/  \____  $$  \_______/ |__/  \_______/
#				                                                  /$$  | $$
#				                                                 |  $$$$$$/
#				                                                  \______/


func _ready() -> void:
	tilemap = get_node(GlobalRef.get_game_node_path(GlobalRef.game_nodes_enum.tilemap))


func _temp_saver():
	for i in GlobalRef.chunks:
		GlobalSaver.save_chunk(Vector2i(i))


func _process(_delta: float) -> void:
	if (
		not unload_queue.is_empty()
		and chunks.has(unload_queue[-1])
		and is_instance_valid(chunks[unload_queue[-1]])
	):
		if chunks[unload_queue[-1]].dirty:
			GlobalSaver.save_chunk(unload_queue[-1])
		chunks[unload_queue[-1]].queue_free()
		chunks.erase(unload_queue[-1])
		unload_queue.remove_at(-1)

	if not load_queue.is_empty():
		instantiate_chunk(load_queue[-1], world_seed)
		load_queue.remove_at(-1)
		return

	set_process(false)


func _physics_process(_delta: float) -> void:
	var chunk_cam_coords: Vector4i = world_coord_to_chunk_coord(
		get_node(GlobalRef.get_game_node_path(GlobalRef.game_nodes_enum.tilemap)).local_to_map(
			cam.position
		)
	)
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
					load_queue.append(coords)

		set_process(true)


#				 /$$$$$$$              /$$        /$$  /$$
#				| $$__  $$            | $$       | $$ |__/
#				| $$  \ $$  /$$   /$$ | $$$$$$$  | $$  /$$   /$$$$$$$
#				| $$$$$$$/ | $$  | $$ | $$__  $$ | $$ | $$  /$$_____/
#				| $$____/  | $$  | $$ | $$  \ $$ | $$ | $$ | $$
#				| $$       | $$  | $$ | $$  | $$ | $$ | $$ | $$
#				| $$       |  $$$$$$/ | $$$$$$$/ | $$ | $$ |  $$$$$$$
#				|__/        \______/  |_______/  |__/ |__/  \_______/

#				  /$$$$$$
#				 /$$__  $$
#				| $$  \__/ /$$   /$$  /$$$$$$$    /$$$$$$$   /$$$$$$$
#				| $$$$    | $$  | $$ | $$__  $$  /$$_____/  /$$_____/
#				| $$_/    | $$  | $$ | $$  \ $$ | $$       |  $$$$$$
#				| $$      | $$  | $$ | $$  | $$ | $$        \____  $$
#				| $$      |  $$$$$$/ | $$  | $$ |  $$$$$$$  /$$$$$$$/
#				|__/       \______/  |__/  |__/  \_______/ |_______/


func chunk_coord_to_world_coord(chunk_coords: Vector4i) -> Vector2i:
	return Vector2i(
		chunk_coords.x * CHUNK_SIZE + chunk_coords.z, chunk_coords.y * CHUNK_SIZE + chunk_coords.w
	)


func world_coord_to_chunk_coord(coord: Vector2i) -> Vector4i:
	@warning_ignore("integer_division")
	var result = Vector4i(
		coord.x / CHUNK_SIZE, coord.y / CHUNK_SIZE, coord.x % CHUNK_SIZE, coord.y % CHUNK_SIZE
	)
	if result.z < 0:
		result.z = CHUNK_SIZE + result.z
		result.x -= 1
	if result.w < 0:
		result.w = CHUNK_SIZE + result.w
		result.y -= 1
	return result


#				 /$$$$$$$              /$$                           /$$
#				| $$__  $$            |__/                          | $$
#				| $$  \ $$   /$$$$$$   /$$  /$$    /$$   /$$$$$$   /$$$$$$     /$$$$$$
#				| $$$$$$$/  /$$__  $$ | $$ |  $$  /$$/  |____  $$ |_  $$_/    /$$__  $$
#				| $$____/  | $$  \__/ | $$  \  $$/$$/    /$$$$$$$   | $$     | $$$$$$$$
#				| $$       | $$       | $$   \  $$$/    /$$__  $$   | $$ /$$ | $$_____/
#				| $$       | $$       | $$    \  $/    |  $$$$$$$   |  $$$$/ |  $$$$$$$
#				|__/       |__/       |__/     \_/      \_______/    \___/    \_______/

#				 /$$                   /$$
#				| $$                  | $$
#				| $$$$$$$    /$$$$$$  | $$   /$$$$$$    /$$$$$$    /$$$$$$    /$$$$$$$
#				| $$__  $$  /$$__  $$ | $$  /$$__  $$  /$$__  $$  /$$__  $$  /$$_____/
#				| $$  \ $$ | $$$$$$$$ | $$ | $$  \ $$ | $$$$$$$$ | $$  \__/ |  $$$$$$
#				| $$  | $$ | $$_____/ | $$ | $$  | $$ | $$_____/ | $$        \____  $$
#				| $$  | $$ |  $$$$$$$ | $$ | $$$$$$$/ |  $$$$$$$ | $$        /$$$$$$$/
#				|__/  |__/  \_______/ |__/ | $$____/   \_______/ |__/       |_______/
#				                           | $$
#				                           | $$
#				                           |__/


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


func generate_new_chunk(coords: Vector2i, _seed: int) -> Chunk:
	var chunk = Chunk.new()

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


func instantiate_chunk(coords: Vector2i, _seed: int) -> void:
	var new_chunk: Chunk
	var chunk_node: Node2D

	new_chunk = generate_new_chunk(coords, _seed)
	chunk_node = chunk_scene.instantiate()

	tilemap.add_child(chunk_node)
	chunks[coords] = chunk_node

	chunk_node.position = coords * CHUNK_SIZE * 32 + Vector2i(16, 16)
	GlobalRef.add_chunk(coords, chunk_node)

	@warning_ignore("integer_division")
	for i in CHUNK_SIZE:
		for j in CHUNK_SIZE:
			chunk_node.set_cell(new_chunk.ground_layer[i][j], Vector2i(i, j), false)
			chunk_node.set_cell(new_chunk.terrain_layer[i][j], Vector2i(i, j), false)
			chunk_node.set_cell(new_chunk.wall_layer[i][j], Vector2i(i, j), false)
			chunk_node.set_cell(new_chunk.terrain_queued_layer[i][j], Vector2i(i, j), false)
			chunk_node.set_cell(new_chunk.wall_queued_layer[i][j], Vector2i(i, j), false)
			chunk_node.set_cell(new_chunk.terrain_queued_d_layer[i][j], Vector2i(i, j), false)
			chunk_node.set_cell(new_chunk.wall_queued_d_layer[i][j], Vector2i(i, j), false)
