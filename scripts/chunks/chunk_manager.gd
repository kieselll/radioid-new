@icon("res://textures/editor_icons/wireframe-globe.svg")
extends Node
class_name ChunkManager

@export var cam : Camera2D
var chunks : Dictionary[Vector2i, Chunk] = {}
var current_chunk : Vector2i

const CHUNK_SIZE = 16
@export var render_distance = 16
@export var world_size = 1

class Chunk:
	var ground_layer : Array
	var terrain_layer : Array
	var wall_layer : Array
	var terrain_queued_layer : Array
	var wall_queued_layer : Array
	var terrain_queued_d_layer : Array
	var wall_queued_d_layer : Array

func generate_new_layer(coords : Vector2i, layer : GlobalRef.tilemap_layers_enum, seed : int) -> Array: #CRITICAL WIP
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
				tile_array[i][j] = 0
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
	var world_seed = randi()
	for i in world_size:
		for j in world_size:
			chunks[Vector2i(i,j)] = generate_new_chunk(Vector2i(i,j), world_seed)

func _physics_process(delta: float) -> void:
	current_chunk = (Vector2(cam.position)/(CHUNK_SIZE * 32)).floor()
	print(current_chunk)
