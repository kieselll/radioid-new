extends Node2D

var _new_cells : Array[Dictionary] = []
var _cells : Array[Array] = []
var _used_textures : Array[int] = []
var _multimesh_instances : Array[MultiMeshInstance2D]
const LAYER_COUNT = 7
const CHUNK_SIZE = 16

func _ready() -> void:
	_cells.resize(7)
	_cells.insert(GlobalRef.tilemap_layers_enum.ground, [])
	_cells.insert(GlobalRef.tilemap_layers_enum.terrain, [])
	_cells.insert(GlobalRef.tilemap_layers_enum.walls, [])
	_cells.insert(GlobalRef.tilemap_layers_enum.terrain_queued, [])
	_cells.insert(GlobalRef.tilemap_layers_enum.walls_queued, [])
	_cells.insert(GlobalRef.tilemap_layers_enum.terrain_queued_d, [])
	_cells.insert(GlobalRef.tilemap_layers_enum.walls_queued_d, [])
	_init_cells()
	set_cell(1, Vector2i(0,0))

func _init_cells():
	_cells.resize(LAYER_COUNT)
	for layer in LAYER_COUNT:
		_cells[layer] = []
		_cells[layer].resize(CHUNK_SIZE)
		for x in CHUNK_SIZE:
			_cells[layer][x] = []
			_cells[layer][x].resize(CHUNK_SIZE)
			for y in CHUNK_SIZE:
				_cells[layer][x][y] = -1

func set_cell(id : int, coords : Vector2i) -> void:
	_new_cells.append({"id" = id, "coords" = coords})

func _update():
	for i in _new_cells:
		_cells[BuildableDB.get_tile_layer(i.id)][i.coords.x][i.coords.y] = i.id
		if not _used_textures.has(i.id):
			_used_textures.append(i.id)
			var new_multimesh = MultiMeshInstance2D.new()
			new_multimesh.texture = BuildableDB.get_tile(i.id).texture_params.texture
			_multimesh_instances.insert(i.id, new_multimesh)
			add_child(new_multimesh)
			
			print("YAY NEW MM")
	_new_cells.clear()

func _process(delta: float) -> void:
	if _new_cells.size() > 0:
		_update()
