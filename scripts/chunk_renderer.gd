extends Node2D
class_name ChunkRenderer

## Renders the visual content belonging to a [Chunk].
##
## Tile state remains owned by the parent chunk. This node owns only the
## generated [MultiMeshInstance2D] nodes and visual autotiling state.

## Base shader material duplicated for every rendered tile type and layer.
@export var base_material: ShaderMaterial

## Chunk whose logical tile state is represented by this renderer.
@onready var chunk: Chunk = get_parent() as Chunk

## Tile multimeshes keyed by tile ID and layer.
var _multimesh_instances: Dictionary[Vector2i, MultiMeshInstance2D] = {}

## Neighbor offsets ordered to match the autotile bitmask layout.
const OFFSETS: Array[Vector2i] = [
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(-1, 0),
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
]

## Shader selection colors keyed by logical tile layer.
const LAYER_COLORS: Dictionary[GlobalRef.tilemap_layers_enum, Color] = {
	GlobalRef.tilemap_layers_enum.ground: Color.WHITE,
	GlobalRef.tilemap_layers_enum.terrain: Color.WHITE,
	GlobalRef.tilemap_layers_enum.walls: Color.WHITE,
	GlobalRef.tilemap_layers_enum.terrain_queued: Color(0.418, 0.72, 0.705, 0.702),
	GlobalRef.tilemap_layers_enum.walls_queued: Color(0.418, 0.72, 0.705, 0.702),
	GlobalRef.tilemap_layers_enum.terrain_queued_d: Color(0.69, 0.276, 0.276, 0.7),
	GlobalRef.tilemap_layers_enum.walls_queued_d: Color(0.69, 0.276, 0.276, 0.7),
}


## Displays a tile and refreshes its visual autotile neighborhood.
func render_cell(
	id: int,
	layer: GlobalRef.tilemap_layers_enum,
	coords: Vector2i,
) -> void:
	var multimesh_key := Vector2i(id, layer)
	if not _multimesh_instances.has(multimesh_key):
		_create_multimesh(id, layer)

	var instance: MultiMeshInstance2D = _multimesh_instances[multimesh_key]
	var index := coords.y * Chunk.CHUNK_SIZE + coords.x
	instance.multimesh.set_instance_transform_2d(
		index,
		Transform2D(PI, 32 * coords),
	)
	_set_tile_region(layer, coords)


## Hides a tile instance and refreshes the remaining neighboring visuals.
func erase_cell(
	id: int,
	layer: GlobalRef.tilemap_layers_enum,
	coords: Vector2i,
) -> void:
	var multimesh_key := Vector2i(id, layer)
	if _multimesh_instances.has(multimesh_key):
		var instance: MultiMeshInstance2D = _multimesh_instances[multimesh_key]
		var index := coords.y * Chunk.CHUNK_SIZE + coords.x
		instance.multimesh.set_instance_transform_2d(index, Transform2D(PI, Vector2.ZERO))
		instance.multimesh.set_instance_custom_data(index, Color(0.0, 0.0, 0.0, 0.0))

	_refresh_neighbor_regions(layer, coords)


## Creates the tile multimesh for the indicated tile ID and layer.
func _create_multimesh(id: int, layer: GlobalRef.tilemap_layers_enum) -> void:
	assert(base_material != null, "ChunkRenderer requires a base material.")
	var instance := MultiMeshInstance2D.new()
	instance.texture = BuildableDB.get_tile(id).texture_params.texture

	instance.multimesh = MultiMesh.new()
	instance.multimesh.use_custom_data = true
	instance.multimesh.instance_count = Chunk.CHUNK_SIZE * Chunk.CHUNK_SIZE

	var material: ShaderMaterial = base_material.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	material.set_shader_parameter("selection_color", LAYER_COLORS[layer])
	instance.material = material

	var mesh := QuadMesh.new()
	mesh.size = BuildableDB.get_tile(id).texture_params.cell_size
	instance.multimesh.mesh = mesh

	_multimesh_instances[Vector2i(id, layer)] = instance
	add_child(instance)


## Refreshes the autotile regions surrounding an erased cell.
func _refresh_neighbor_regions(
	layer: GlobalRef.tilemap_layers_enum,
	coords: Vector2i,
) -> void:
	for offset: Vector2i in OFFSETS:
		var location := _resolve_chunk_location(coords + offset)
		var neighbor_chunk: Chunk = location.chunk
		var neighbor_coords: Vector2i = location.coords
		if neighbor_chunk == null or neighbor_chunk.get_cell(layer, neighbor_coords) == -1:
			continue

		var renderer := neighbor_chunk.get_node_or_null("ChunkRenderer") as ChunkRenderer
		if renderer != null:
			renderer._set_tile_region(layer, neighbor_coords)


## Returns the autotile neighbor mask for a logical chunk cell.
func _detect_neighbors(layer: GlobalRef.tilemap_layers_enum, coords: Vector2i) -> int:
	var result: int = 0b000010000
	var target_id := chunk.get_cell(layer, coords)

	for index in OFFSETS.size():
		var location := _resolve_chunk_location(coords + OFFSETS[index])
		var neighbor_chunk: Chunk = location.chunk
		if neighbor_chunk != null and neighbor_chunk.get_cell(layer, location.coords) == target_id:
			result |= 1 << index

	if not ((result & (1 << 1)) and (result & (1 << 3))):
		result &= ~(1 << 0)
	if not ((result & (1 << 1)) and (result & (1 << 5))):
		result &= ~(1 << 2)
	if not ((result & (1 << 7)) and (result & (1 << 3))):
		result &= ~(1 << 6)
	if not ((result & (1 << 7)) and (result & (1 << 5))):
		result &= ~(1 << 8)

	return result


## Updates the texture region for a tile and any affected neighbors.
func _set_tile_region(layer: GlobalRef.tilemap_layers_enum, coords: Vector2i) -> void:
	var tile_id := chunk.get_cell(layer, coords)
	if tile_id == -1:
		return

	var offsets: Array[Vector2i] = OFFSETS
	if not BuildableDB.get_tile(tile_id).texture_params.can_autotile:
		offsets = [Vector2i.ZERO]
	for offset: Vector2i in offsets:
		var location := _resolve_chunk_location(coords + offset)
		var target_chunk: Chunk = location.chunk
		var target_coords: Vector2i = location.coords
		if target_chunk == null:
			continue

		var id := target_chunk.get_cell(layer, target_coords)
		if id == -1:
			continue

		var renderer := target_chunk.get_node_or_null("ChunkRenderer") as ChunkRenderer
		if renderer == null:
			continue

		var multimesh_key := Vector2i(id, layer)
		if not renderer._multimesh_instances.has(multimesh_key):
			continue

		var rect: Rect2 = BuildableDB.get_tile(id).texture_params.get_terrain_tile_rect(
			renderer._detect_neighbors(layer, target_coords)
		)
		var instance_index := target_coords.y * Chunk.CHUNK_SIZE + target_coords.x
		renderer._multimesh_instances[multimesh_key].multimesh.set_instance_custom_data(
			instance_index,
			Color(rect.position.x, rect.position.y, rect.size.x, rect.size.y),
		)


## Resolves potentially out-of-bounds local coordinates to a chunk and local cell.
func _resolve_chunk_location(coords: Vector2i) -> Dictionary:
	var resolved_coords := coords
	var chunk_position := Vector2i(
		GridUtils.world_coord_to_chunk_coord(chunk.position).x,
		GridUtils.world_coord_to_chunk_coord(chunk.position).y,
	)

	if resolved_coords.x < 0:
		chunk_position.x -= 1
		resolved_coords.x = Chunk.CHUNK_SIZE - 1
	elif resolved_coords.x >= Chunk.CHUNK_SIZE:
		chunk_position.x += 1
		resolved_coords.x = 0
	if resolved_coords.y < 0:
		chunk_position.y -= 1
		resolved_coords.y = Chunk.CHUNK_SIZE - 1
	elif resolved_coords.y >= Chunk.CHUNK_SIZE:
		chunk_position.y += 1
		resolved_coords.y = 0

	return {
		"chunk": GlobalRef.get_chunk(chunk_position),
		"coords": resolved_coords,
	}
