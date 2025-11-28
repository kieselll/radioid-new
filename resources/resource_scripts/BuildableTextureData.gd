class_name BuildableTextureData
extends Resource

@export_category("Base")
@export var can_autotile: bool
@export var texture: Texture2D
@export_category("Terrain specific")
@export var cell_size: Vector2i

enum tile_neigbors {
	TOP_LEFT   =  0b100000000,    TOP = 0b010000000,    TOP_RIGHT = 0b001000000,
				 LEFT = 0b000100000, CENTER = 0b000000000,        RIGHT = 0b000001000,
	BOTTOM_LEFT = 0b000000100, BOTTOM = 0b000000010, BOTTOM_RIGHT = 0b000000001
	}

@export var autotile_layout : Dictionary = {
	0b000010010 : Vector2i(0, 0),
	0b000011010 : Vector2i(1, 0),
	0b000111010 : Vector2i(2, 0),
	0b000110010 : Vector2i(3, 0),
	0b110111010 : Vector2i(4, 0),
	0b000111011 : Vector2i(5, 0),
	0b000111110 : Vector2i(6, 0),
	0b011111010 : Vector2i(7, 0),
	0b000011011 : Vector2i(8, 0),
	0b010111111 : Vector2i(9, 0),
	0b000111111 : Vector2i(10, 0),
	0b000110110 : Vector2i(11, 0),

	0b010010010 : Vector2i(0, 1),
	0b010011010 : Vector2i(1, 1),
	0b010111010 : Vector2i(2, 1),
	0b010110010 : Vector2i(3, 1),
	0b010011011 : Vector2i(4, 1),
	0b011111111 : Vector2i(5, 1),
	0b110111111 : Vector2i(6, 1),
	0b010110110 : Vector2i(7, 1),
	0b011011011 : Vector2i(8, 1),
	0b011111110 : Vector2i(9, 1),
	0b000000000 : Vector2i(10, 1),
	0b110111110 : Vector2i(11, 1),

	0b010010000 : Vector2i(0, 2),
	0b010011000 : Vector2i(1, 2),
	0b010111000 : Vector2i(2, 2),
	0b010110000 : Vector2i(3, 2),
	0b011011010 : Vector2i(4, 2),
	0b111111011 : Vector2i(5, 2),
	0b111111110 : Vector2i(6, 2),
	0b110110010 : Vector2i(7, 2),
	0b011111011 : Vector2i(8, 2),
	0b111111111 : Vector2i(9, 2),
	0b110111011 : Vector2i(10, 2),
	0b110110110 : Vector2i(11, 2),

	0b000010000 : Vector2i(0, 3),
	0b000011000 : Vector2i(1, 3),
	0b000111000 : Vector2i(2, 3),
	0b000110000 : Vector2i(3, 3),
	0b010111110 : Vector2i(4, 3),
	0b011111000 : Vector2i(5, 3),
	0b110111000 : Vector2i(6, 3),
	0b010111011 : Vector2i(7, 3),
	0b011011000 : Vector2i(8, 3),
	0b111111000 : Vector2i(9, 3),
	0b111111010 : Vector2i(10, 3),
	0b110110000 : Vector2i(11, 3)
}

func get_terrain_tile_rect(neighbors_mask : int):
	if not can_autotile: return Rect2i(0,0,1,1)
	assert(Vector2i(texture.get_size()) % cell_size == Vector2i.ZERO, "Texture size not divisible by cell_size")
	if not autotile_layout.has(neighbors_mask): return Rect2(Vector2(Vector2i(0, 3) * cell_size) / texture.get_size(), Vector2(cell_size) / texture.get_size())
	var return_rect = Rect2(Vector2(autotile_layout[neighbors_mask] * cell_size) / texture.get_size(), Vector2(cell_size) / texture.get_size())
	return return_rect
