extends RefCounted
class_name TileMapRect

const CHUNK_SIZE = 16
const TILE_SIZE = 32

var start : Vector4i
var end : Vector4i

@warning_ignore("shadowed_variable")
func _init(start : Vector4i, end : Vector4i) -> void:
	self.start = start
	self.end = end

func get_tile_area() -> int:
	var width = abs(start.x - end.x) * CHUNK_SIZE + abs(start.z - end.z + 1)
	var height = abs(start.y - end.y) * CHUNK_SIZE + abs(start.w - end.w + 1)
	return width * height

func get_world_area() -> int:
	return get_tile_area() * TILE_SIZE * TILE_SIZE

func normalize() -> TileMapRect:
	if start.x > end.x:
		var temp_x = start.x
		var temp_z = start.z
		start.x = end.x
		start.z = end.z
		end.x = temp_x
		end.z = temp_z
	if start.y > end.y:
		var temp_y = start.y
		var temp_w = start.w
		start.y = end.y
		start.w = end.w
		end.y = temp_y
		end.w = temp_w
	return self
