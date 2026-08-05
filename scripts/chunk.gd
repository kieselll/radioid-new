extends Node2D
class_name Chunk

#region Private_Fields

var _new_cells: Array[NewCell] = []  # Queue of cell updates
var _cells: Array[Array] = []  # 3D tile storage
var dirty: bool
var _chunk_manager: ChunkManager

## Renderer responsible for this chunk's tile visuals.
@onready var _renderer: ChunkRenderer = $ChunkRenderer

signal cells_updated

const LAYER_COUNT: int = 7
const CHUNK_SIZE: int = 16

#endregion

#region Private_Classes


## Stores a pending tile update entry.
class NewCell:
	var id: int
	var coords: Vector2i
	var layer: GlobalRef.tilemap_layers_enum

	@warning_ignore("shadowed_variable")
	func _init(id: int, coords: Vector2i, layer: GlobalRef.tilemap_layers_enum) -> void:
		self.id = id
		self.coords = coords
		self.layer = layer


#endregion

#region Lifecycle


func _ready() -> void:
	_init_cells()
	_chunk_manager = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.chunk_manager))


func _process(_delta: float) -> void:
	_update()
	set_process(false)


#endregion

#region Public_API


## Queues a tile for placement or replacement.
func set_cell(id: int, coords: Vector2i, layer: GlobalRef.tilemap_layers_enum) -> void:
	_new_cells.append(NewCell.new(id, coords, layer))
	dirty = true
	set_process(true)

func erase_cell(coords: Vector2i, layer: GlobalRef.tilemap_layers_enum) -> void:
	_new_cells.append(NewCell.new(-1, coords, layer))
	dirty = true
	set_process(true)

#endregion

#region Public_Helpers


func get_cells() -> Array:
	return _cells


func get_cells_rle() -> Array:
	var result: Array = []

	for layer in _cells.size():
		var layer_data: Array[Vector2i] = []
		var first_tile: bool = true
		var last_id: int
		var run_length: int = 0

		for y in CHUNK_SIZE:
			for x in CHUNK_SIZE:
				var id: int = _cells[layer][y][x]

				if first_tile:
					last_id = id
					run_length = 1
					first_tile = false
				elif id == last_id:
					run_length += 1
				else:
					layer_data.append(Vector2i(last_id, run_length))
					last_id = id
					run_length = 1

		layer_data.append(Vector2i(last_id, run_length))

		result.append([])
		result[layer] = layer_data

	return result


## Returns tile at given coords.
func get_cell(layer: GlobalRef.tilemap_layers_enum, coords: Vector2i) -> int:
	return _cells[layer][coords.x][coords.y]


#endregion

#region Private_Init


## Initializes the internal tile grid.
func _init_cells() -> void:
	_cells.resize(LAYER_COUNT)

	for layer in LAYER_COUNT:
		_cells[layer] = []
		_cells[layer].resize(CHUNK_SIZE)

		for x in CHUNK_SIZE:
			_cells[layer][x] = []
			@warning_ignore("unsafe_method_access")
			_cells[layer][x].resize(CHUNK_SIZE)

			for y in CHUNK_SIZE:
				_cells[layer][x][y] = -1  # Fill with empty


#endregion

#region Private_Update


## Applies queued cell updates.
func _update() -> void:
	for i in _new_cells:
		if i.id == -1:
			var previous_id: int = _cells[i.layer][i.coords.x][i.coords.y]
			if previous_id != -1:
				_cells[i.layer][i.coords.x][i.coords.y] = -1
				_renderer.erase_cell(previous_id, i.layer, i.coords)
			_refresh_pathfinding_solid(i.coords)
			continue

		var existing_id: int = _cells[i.layer][i.coords.x][i.coords.y]
		if existing_id != -1 and existing_id != i.id:
			_renderer.erase_cell(existing_id, i.layer, i.coords)
		_cells[i.layer][i.coords.x][i.coords.y] = i.id
		_renderer.render_cell(i.id, i.layer, i.coords)
		_refresh_pathfinding_solid(i.coords)

	_new_cells.clear()
	cells_updated.emit()


## Updates collision from the real world layers only. Queued build previews are
## visual reservations and must remain walkable so builders can reach a tile
## adjacent to another queued build job.
func _refresh_pathfinding_solid(coords: Vector2i) -> void:
	var solid := false
	for layer: GlobalRef.tilemap_layers_enum in [
		GlobalRef.tilemap_layers_enum.ground,
		GlobalRef.tilemap_layers_enum.terrain,
		GlobalRef.tilemap_layers_enum.walls,
	]:
		var tile_id := get_cell(layer, coords)
		if tile_id != -1 and not BuildableDB.get_tile(tile_id).passable:
			solid = true
			break

	var self_position := GridUtils.world_coord_to_chunk_coord(position)
	var pathfinder: GlobalPathfinder = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.pathfinder))
	pathfinder.mark_tile_solid(
		Vector4i(self_position.x, self_position.y, coords.x, coords.y), solid
	)


#endregion
