@icon("res://textures/editor_icons/wireframe-globe.svg")
extends Node
class_name ChunkManager

@export var cam : Camera2D
@export var chunk_scene : PackedScene
var chunks : Dictionary[Vector2i, Node]
var load_queue : Array[Vector2i]
var current_chunk : Vector2i
var old_chunk : Vector2i
var world_seed = randi()
var tilemap : TileMap

const CHUNK_SIZE = 16
@export var render_distance : int = 16

signal current_chunk_changed(new_chunk_coords : Vector2i)

class Chunk:
	var ground_layer : Array
	var terrain_layer : Array
	var wall_layer : Array
	var terrain_queued_layer : Array
	var wall_queued_layer : Array
	var terrain_queued_d_layer : Array
	var wall_queued_d_layer : Array

class Tile:
	var sid : int
	var acoords : Vector2i
	
	func _init(sid : int, acoords : Vector2i) -> void:
		self.sid = sid
		self.acoords = acoords

func generate_new_layer(coords : Vector2i, layer : GlobalRef.tilemap_layers_enum, seed : int) -> Array: #CRITICAL WIP
	var tile_array : Array = []
	tile_array.resize(CHUNK_SIZE)
	if layer == GlobalRef.tilemap_layers_enum.ground:
		for i in CHUNK_SIZE:
			tile_array[i] = []
			for j in CHUNK_SIZE:
				tile_array[i].resize(CHUNK_SIZE)
				tile_array[i][j] = Tile.new(3, Vector2i(0,0)) #CRITICAL WIP REPLACE PLEASE
	else:
		for i in CHUNK_SIZE:
			tile_array[i] = []
			for j in CHUNK_SIZE:
				tile_array[i].resize(CHUNK_SIZE)
				tile_array[i][j] = Tile.new(-1, Vector2i(-1, -1))
	return tile_array

func generate_new_chunk(coords : Vector2i, seed) -> Chunk:
	var chunk = Chunk.new()
	chunk.ground_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.ground, seed)
	chunk.terrain_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.terrain, seed)
	chunk.wall_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.walls, seed)
	chunk.terrain_queued_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.terrain_queued, seed)
	chunk.wall_queued_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.walls_queued, seed)
	chunk.terrain_queued_d_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.terrain_queued_d, seed)
	chunk.wall_queued_d_layer = generate_new_layer(coords, GlobalRef.tilemap_layers_enum.walls_queued_d, seed)
	return chunk

func _ready() -> void:
	tilemap = get_node(GlobalRef.get_game_node_path(GlobalRef.game_nodes_enum.tilemap))

var gen_chunk_x := 0
var gen_chunk_y := 0
var coord_x := 0
var coord_y := 0
var new_chunk : Chunk
var chunk_node : Node2D

func _process(delta: float) -> void:
	if gen_chunk_x != render_distance and gen_chunk_y != render_distance:
		if not new_chunk and not chunks.has(Vector2i(gen_chunk_x, gen_chunk_y)):
			new_chunk = generate_new_chunk(Vector2i(gen_chunk_x, gen_chunk_y), world_seed)
			chunk_node = chunk_scene.instantiate()
			tilemap.add_child(chunk_node)
			chunks[Vector2i(gen_chunk_x, gen_chunk_y)] = chunk_node
			chunk_node.position = (Vector2i(gen_chunk_x, gen_chunk_y) + current_chunk) * CHUNK_SIZE * 32

			for i in int(8000/render_distance):
				chunk_node.ground_layer.set_cell(Vector2i(coord_x, coord_y), new_chunk.ground_layer[coord_x][coord_y].sid, new_chunk.ground_layer[coord_x][coord_y].acoords)
				chunk_node.terrain_layer.set_cell(Vector2i(coord_x, coord_y), new_chunk.terrain_layer[coord_x][coord_y].sid, new_chunk.terrain_layer[coord_x][coord_y].acoords)
				chunk_node.walls_layer.set_cell(Vector2i(coord_x, coord_y), new_chunk.wall_layer[coord_x][coord_y].sid, new_chunk.wall_layer[coord_x][coord_y].acoords)
				chunk_node.terrain_q_layer.set_cell(Vector2i(coord_x, coord_y), new_chunk.terrain_queued_layer[coord_x][coord_y].sid, new_chunk.terrain_queued_layer[coord_x][coord_y].acoords)
				chunk_node.walls_q_layer.set_cell(Vector2i(coord_x, coord_y), new_chunk.wall_queued_layer[coord_x][coord_y].sid, new_chunk.wall_queued_layer[coord_x][coord_y].acoords)
				chunk_node.terrain_q_d_layer.set_cell(Vector2i(coord_x, coord_y), new_chunk.terrain_queued_d_layer[coord_x][coord_y].sid, new_chunk.terrain_queued_d_layer[coord_x][coord_y].acoords)
				chunk_node.walls_q_d_layer.set_cell(Vector2i(coord_x, coord_y), new_chunk.wall_queued_d_layer[coord_x][coord_y].sid, new_chunk.wall_queued_d_layer[coord_x][coord_y].acoords)

				if coord_x + 1 == CHUNK_SIZE:
					coord_x = 0
					coord_y += 1
					if coord_y == CHUNK_SIZE:
						coord_x = 0
						coord_y = 0
						new_chunk = null
						GlobalRef.add_chunk_path(Vector2i(gen_chunk_x, gen_chunk_y), chunk_node)
						if gen_chunk_x + 1 == render_distance:
							gen_chunk_x = 0
							gen_chunk_y += 1
						else:
							gen_chunk_x += 1
						return
				else:
					coord_x += 1
		else:
			new_chunk = null
			set_process(false)

func _physics_process(_delta: float) -> void:
	current_chunk = (Vector2(cam.position)/(CHUNK_SIZE * 32)).floor()
	if old_chunk == null or old_chunk != current_chunk:
		current_chunk_changed.emit(current_chunk)
		set_process(true)
		gen_chunk_x = current_chunk.x
		gen_chunk_y = current_chunk.y
		old_chunk = current_chunk

func chunk_coord_to_world_coord(chunk_coords : Vector4i) -> Vector2i:
	return Vector2i(
		chunk_coords.x * CHUNK_SIZE + chunk_coords.z,
		chunk_coords.y * CHUNK_SIZE + chunk_coords.w
	)

func world_coord_to_chunk_coord(coord : Vector2i) -> Vector4i:
	return Vector4i(
		coord.x / CHUNK_SIZE,
		coord.y / CHUNK_SIZE,
		coord.x % CHUNK_SIZE,
		coord.y % CHUNK_SIZE
	)
