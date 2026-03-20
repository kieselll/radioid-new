extends Node2D

func _draw() -> void:
	draw_polyline([Vector2(-16 ,-16), Vector2(512 - 16 ,-16), Vector2(512 - 16, 512 - 16), Vector2(-16 ,512 - 16), Vector2(-16 ,-16)], Color.AQUA)
