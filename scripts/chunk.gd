extends Node2D

#				 /$$$$$$$              /$$                           /$$
#				| $$__  $$            |__/                          | $$
#				| $$  \ $$   /$$$$$$   /$$  /$$    /$$   /$$$$$$   /$$$$$$     /$$$$$$
#				| $$$$$$$/  /$$__  $$ | $$ |  $$  /$$/  |____  $$ |_  $$_/    /$$__  $$
#				| $$____/  | $$  \__/ | $$  \  $$/$$/    /$$$$$$$   | $$     | $$$$$$$$
#				| $$       | $$       | $$   \  $$$/    /$$__  $$   | $$ /$$ | $$_____/
#				| $$       | $$       | $$    \  $/    |  $$$$$$$   |  $$$$/ |  $$$$$$$
#				|__/       |__/       |__/     \_/      \_______/    \___/    \_______/
#
#
#
#				 /$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$$
#				|_  $$_/ | $$$ | $$ |_  $$_/ |__  $$__/
#				  | $$   | $$$$| $$   | $$      | $$
#				  | $$   | $$ $$ $$   | $$      | $$
#				  | $$   | $$  $$$$   | $$      | $$
#				  | $$   | $$\  $$$   | $$      | $$
#				 /$$$$$$ | $$ \  $$  /$$$$$$    | $$
#				|______/ |__/  \__/ |______/    |__/

#region Private_Fields

var _new_cells: Array[NewCell] = []  # Queue of cell updates
var _cells: Array = []  # 3D tile storage
var dirty: bool
var _multimesh_instances: Dictionary[int, MultiMeshInstance2D] = {}  # Tile ID → MultiMeshInstance
var _chunk_manager: ChunkManager
var _tilemap: TileMap

const LAYER_COUNT = 7
const CHUNK_SIZE = 16

# Neighbor offsets for autotiling
const offsets: Array = [
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

const layer_colors: Dictionary[GlobalRef.tilemap_layers_enum, Color] = {
	GlobalRef.tilemap_layers_enum.ground: Color.WHITE,
	GlobalRef.tilemap_layers_enum.terrain: Color.WHITE,
	GlobalRef.tilemap_layers_enum.walls: Color.WHITE,
	GlobalRef.tilemap_layers_enum.terrain_queued: Color(0.418, 0.72, 0.705, 0.702),
	GlobalRef.tilemap_layers_enum.walls_queued: Color(0.418, 0.72, 0.705, 0.702),
	GlobalRef.tilemap_layers_enum.terrain_queued_d: Color(0.69, 0.276, 0.276, 0.7),
	GlobalRef.tilemap_layers_enum.walls_queued_d: Color(0.69, 0.276, 0.276, 0.7),
}
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

#				 /$$$$$$$              /$$        /$$  /$$
#				| $$__  $$            | $$       | $$ |__/
#				| $$  \ $$  /$$   /$$ | $$$$$$$  | $$  /$$   /$$$$$$$
#				| $$$$$$$/ | $$  | $$ | $$__  $$ | $$ | $$  /$$_____/
#				| $$____/  | $$  | $$ | $$  \ $$ | $$ | $$ | $$
#				| $$       | $$  | $$ | $$  | $$ | $$ | $$ | $$
#				| $$       |  $$$$$$/ | $$$$$$$/ | $$ | $$ |  $$$$$$$
#				|__/        \______/  |_______/  |__/ |__/  \_______/
#
#
#
#				 /$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$$
#				|_  $$_/ | $$$ | $$ |_  $$_/ |__  $$__/
#				  | $$   | $$$$| $$   | $$      | $$
#				  | $$   | $$ $$ $$   | $$      | $$
#				  | $$   | $$  $$$$   | $$      | $$
#				  | $$   | $$\  $$$   | $$      | $$
#				 /$$$$$$ | $$ \  $$  /$$$$$$    | $$
#				|______/ |__/  \__/ |______/    |__/

#region Public_Exported_Fields

@export var base_material: ShaderMaterial
@export var queued_material: ShaderMaterial
@export var queued_d_material: ShaderMaterial

#endregion

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

#region Lifecycle


func _ready() -> void:
	_init_cells()
	_chunk_manager = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.chunk_manager))


func _process(_delta: float) -> void:
	_update()
	set_process(false)


#endregion

#				 /$$$$$$$              /$$        /$$  /$$
#				| $$__  $$            | $$       | $$ |__/
#				| $$  \ $$  /$$   /$$ | $$$$$$$  | $$  /$$   /$$$$$$$
#				| $$$$$$$/ | $$  | $$ | $$__  $$ | $$ | $$  /$$_____/
#				| $$____/  | $$  | $$ | $$  \ $$ | $$ | $$ | $$
#				| $$       | $$  | $$ | $$  | $$ | $$ | $$ | $$
#				| $$       |  $$$$$$/ | $$$$$$$/ | $$ | $$ |  $$$$$$$
#				|__/        \______/  |_______/  |__/ |__/  \_______/
#
#
#
#				  /$$$$$$                                                     /$$$
#				 /$$__  $$                                                   /$$ $$
#				| $$  \__/  /$$   /$$  /$$$$$$$    /$$$$$$$   /$$$$$$$      |  $$$
#				| $$$$     | $$  | $$ | $$__  $$  /$$_____/  /$$_____/       /$$ $$/$$
#				| $$_/     | $$  | $$ | $$  \ $$ | $$       |  $$$$$$       | $$  $$_/
#				| $$       | $$  | $$ | $$  | $$ | $$        \____  $$      | $$\  $$
#				| $$       |  $$$$$$/ | $$  | $$ |  $$$$$$$  /$$$$$$$/      |  $$$$/$$
#				|__/        \______/  |__/  |__/  \_______/ |_______/        \____/\_/
#
#
#
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

#region Public_API


## Queues a tile for placement or replacement.
func set_cell(id: int, coords: Vector2i, layer: GlobalRef.tilemap_layers_enum) -> void:
	_new_cells.append(NewCell.new(id, coords, layer))
	dirty = true
	set_process(true)


#endregion

#region Public_Helpers


func get_cells() -> Array:
	return _cells


func get_cells_rle() -> Array:
	var result: Array = []

	for layer in _cells.size():
		var layer_data = []
		var last_id = null
		var run_length = 0

		for y in CHUNK_SIZE:
			for x in CHUNK_SIZE:
				var id = _cells[layer][y][x]

				if last_id == null:
					last_id = id
					run_length = 1
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

#				 /$$$$$$$              /$$                           /$$
#				| $$__  $$            |__/                          | $$
#				| $$  \ $$   /$$$$$$   /$$  /$$    /$$   /$$$$$$   /$$$$$$     /$$$$$$
#				| $$$$$$$/  /$$__  $$ | $$ |  $$  /$$/  |____  $$ |_  $$_/    /$$__  $$
#				| $$____/  | $$  \__/ | $$  \  $$/$$/    /$$$$$$$   | $$     | $$$$$$$$
#				| $$       | $$       | $$   \  $$$/    /$$__  $$   | $$ /$$ | $$_____/
#				| $$       | $$       | $$    \  $/    |  $$$$$$$   |  $$$$/ |  $$$$$$$
#				|__/       |__/       |__/     \_/      \_______/    \___/    \_______/
#
#
#
#				  /$$$$$$                                                     /$$$
#				 /$$__  $$                                                   /$$ $$
#				| $$  \__/  /$$   /$$  /$$$$$$$    /$$$$$$$   /$$$$$$$      |  $$$
#				| $$$$     | $$  | $$ | $$__  $$  /$$_____/  /$$_____/       /$$ $$/$$
#				| $$_/     | $$  | $$ | $$  \ $$ | $$       |  $$$$$$       | $$  $$_/
#				| $$       | $$  | $$ | $$  | $$ | $$        \____  $$      | $$\  $$
#				| $$       |  $$$$$$/ | $$  | $$ |  $$$$$$$  /$$$$$$$/      |  $$$$/$$
#				|__/        \______/  |__/  |__/  \_______/ |_______/        \____/\_/
#
#
#
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

#region Private_Init


## Initializes the internal tile grid.
func _init_cells() -> void:
	_cells.resize(LAYER_COUNT)

	for layer in LAYER_COUNT:
		_cells[layer] = []
		_cells[layer].resize(CHUNK_SIZE)

		for x in CHUNK_SIZE:
			_cells[layer][x] = []
			_cells[layer][x].resize(CHUNK_SIZE)

			for y in CHUNK_SIZE:
				_cells[layer][x][y] = -1  # Fill with empty


#endregion

#region Private_Update


## Applies queued cell updates.
func _update():
	for i in _new_cells:
		if i.id == -1:
			continue

		var layer = i.layer
		_cells[layer][i.coords.x][i.coords.y] = i.id

		# Create MultiMesh if needed
		if not _multimesh_instances.has(i.id):
			_create_multimesh(i)

		var inst = _multimesh_instances[i.id]

		var index = abs(i.coords.y) * CHUNK_SIZE + abs(i.coords.x)

		inst.multimesh.set_instance_transform_2d(index, Transform2D(PI, 32 * i.coords))

		_set_tile_region(layer, i.coords)

	_new_cells.clear()


#endregion

#				 /$$      /$$             /$$    /$$      /$$  /$$      /$$                        /$$
#				| $$$    /$$$            | $$   | $$     |__/ | $$$    /$$$                       | $$
#				| $$$$  /$$$$  /$$   /$$ | $$  /$$$$$$    /$$ | $$$$  /$$$$   /$$$$$$    /$$$$$$$ | $$$$$$$
#				| $$ $$/$$ $$ | $$  | $$ | $$ |_  $$_/   | $$ | $$ $$/$$ $$  /$$__  $$  /$$_____/ | $$__  $$
#				| $$  $$$| $$ | $$  | $$ | $$   | $$     | $$ | $$  $$$| $$ | $$$$$$$$ |  $$$$$$  | $$  \ $$
#				| $$\  $ | $$ | $$  | $$ | $$   | $$ /$$ | $$ | $$\  $ | $$ | $$_____/  \____  $$ | $$  | $$
#				| $$ \/  | $$ |  $$$$$$/ | $$   |  $$$$/ | $$ | $$ \/  | $$ |  $$$$$$$  /$$$$$$$/ | $$  | $$
#				|__/     |__/  \______/  |__/    \___/   |__/ |__/     |__/  \_______/ |_______/  |__/  |__/

#region Private_Multimesh


## Creates a multimesh instance for tile type.
func _create_multimesh(cell: NewCell):
	var mm = MultiMeshInstance2D.new()

	mm.texture = BuildableDB.get_tile(cell.id).texture_params.texture
	_multimesh_instances[cell.id] = mm

	mm.multimesh = MultiMesh.new()
	mm.multimesh.use_custom_data = true
	mm.material = base_material.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	mm.material.set_shader_parameter("selection_color", layer_colors[cell.layer])

	var mesh = QuadMesh.new()
	mesh.size = BuildableDB.get_tile(cell.id).texture_params.cell_size
	mm.multimesh.mesh = mesh

	mm.multimesh.instance_count = CHUNK_SIZE * CHUNK_SIZE
	add_child(mm)


#endregion

#				  /$$$$$$                /$$                   /$$      /$$  /$$
#				 /$$__  $$              | $$                  | $$     |__/ | $$
#				| $$  \ $$  /$$   /$$  /$$$$$$     /$$$$$$   /$$$$$$    /$$ | $$   /$$$$$$
#				| $$$$$$$$ | $$  | $$ |_  $$_/    /$$__  $$ |_  $$_/   | $$ | $$  /$$__  $$
#				| $$__  $$ | $$  | $$   | $$     | $$  \ $$   | $$     | $$ | $$ | $$$$$$$$
#				| $$  | $$ | $$  | $$   | $$ /$$ | $$  | $$   | $$ /$$ | $$ | $$ | $$_____/
#				| $$  | $$ |  $$$$$$/   |  $$$$/ |  $$$$$$/   |  $$$$/ | $$ | $$ |  $$$$$$$
#				|__/  |__/  \______/     \___/    \______/     \___/   |__/ |__/  \_______/

#region Private_Autotile


## Returns a bitmask of neighboring tiles for autotiling.
func _detect_neighbors(layer: GlobalRef.tilemap_layers_enum, coords: Vector2i):
	var result = 0
	var chunk = self

	for i in offsets.size():
		var o = coords + offsets[i]
		var chunk_pos = Vector2i(
			GridUtils.world_coord_to_chunk_coord(_tilemap.local_to_map(position)).x,
			GridUtils.world_coord_to_chunk_coord(_tilemap.local_to_map(position)).y
		)

		if o.x < 0:
			chunk_pos += Vector2i(-1, 0)
			o.x = CHUNK_SIZE - 1
		elif o.x >= CHUNK_SIZE:
			chunk_pos += Vector2i(1, 0)
			o.x = 0
		if o.y < 0:
			chunk_pos += Vector2i(0, -1)
			o.y = CHUNK_SIZE - 1
		elif o.y >= CHUNK_SIZE:
			chunk_pos += Vector2i(0, 1)
			o.y = 0
		chunk = GlobalRef.get_chunk(chunk_pos)

		if chunk == null:
			continue

		if chunk.get_cell(layer, o) == get_cell(layer, coords):
			result |= 1 << i

	# Remove invalid diagonals
	if not ((result & (1 << 1)) and (result & (1 << 3))):
		result &= ~(1 << 0)

	if not ((result & (1 << 1)) and (result & (1 << 5))):
		result &= ~(1 << 2)

	if not ((result & (1 << 7)) and (result & (1 << 3))):
		result &= ~(1 << 6)

	if not ((result & (1 << 7)) and (result & (1 << 5))):
		result &= ~(1 << 8)

	return result


## UV update for tile and neighbors
func _set_tile_region(layer: GlobalRef.tilemap_layers_enum, coords: Vector2i):
	var chunk = self
	for off in (
		offsets
		if BuildableDB.get_tile(get_cell(layer, coords)).texture_params.can_autotile
		else [Vector2i.ZERO]
	):
		var p = coords + off
		var chunk_pos = Vector2i(
			GridUtils.world_coord_to_chunk_coord(_tilemap.local_to_map(position)).x,
			GridUtils.world_coord_to_chunk_coord(_tilemap.local_to_map(position)).y
		)

		if p.x < 0:
			chunk_pos += Vector2i(-1, 0)
			p.x = CHUNK_SIZE - 1
		elif p.x >= CHUNK_SIZE:
			chunk_pos += Vector2i(1, 0)
			p.x = 0
		if p.y < 0:
			chunk_pos += Vector2i(0, -1)
			p.y = CHUNK_SIZE - 1
		elif p.y >= CHUNK_SIZE:
			chunk_pos += Vector2i(0, 1)
			p.y = 0
		chunk = GlobalRef.get_chunk(chunk_pos)

		if chunk == null:
			continue

		var id = chunk.get_cell(layer, p)
		if id == -1:
			continue

		var rect: Rect2 = BuildableDB.get_tile(id).texture_params.get_terrain_tile_rect(
			chunk._detect_neighbors(layer, p)
		)

		var index = abs(p.y) * CHUNK_SIZE + abs(p.x)

		chunk._multimesh_instances[id].multimesh.set_instance_custom_data(
			index, Color(rect.position.x, rect.position.y, rect.size.x, rect.size.y)
		)

#endregion
