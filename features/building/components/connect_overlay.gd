class_name ConnectOverlay

extends Resource
@export var connect_id: int
@export var top_overlay: Texture2D
@export var right_overlay: Texture2D
@export var bottom_overlay: Texture2D
@export var left_overlay: Texture2D


func get_overlay(direction: Vector2i):
	match direction:
		Vector2i.UP:
			return top_overlay
		Vector2i.RIGHT:
			return right_overlay
		Vector2i.DOWN:
			return bottom_overlay
		Vector2i.LEFT:
			return left_overlay
		_:
			push_error("Unexpected %s in get_overlay" % direction)
