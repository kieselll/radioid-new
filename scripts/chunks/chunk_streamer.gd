@icon("res://textures/editor_icons/rss.svg")
extends Node
class_name ChunkStreamer

@export var chunk_manager: ChunkManager
@export var render_distance = 16


func _ready() -> void:
	chunk_manager.current_chunk_changed.connect(_on_current_chunk_changed)


func _on_current_chunk_changed(new_chunk_coords: Vector2i):
	for x in range(new_chunk_coords.x - render_distance, new_chunk_coords.x + render_distance):
		for y in range(new_chunk_coords.y - render_distance, new_chunk_coords.y + render_distance):
			if (
				new_chunk_coords.distance_squared_to(Vector2i(x, y)) < pow(render_distance, 2)
				and not new_chunk_coords in chunk_manager.chunks.keys()
			):
				_load_chunk(Vector2i(x, y), chunk_manager.generate_new_chunk(Vector2i(x, y), 0))


func _load_chunk(coords: Vector2i, chunk: ChunkManager.Chunk):
	pass


func unload_chunk(coord: Vector2i):
	pass
