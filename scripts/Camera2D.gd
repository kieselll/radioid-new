extends Camera2D
@export var speed = 1000
@export var zoom_speed: = 0.7
@export var min_zoom: = Vector2(0.3, 0.3)
@export var max_zoom: = Vector2(8, 8)
var _target_zoom
var _zoom_step: = 1.8

func _ready() -> void:
	InputHandler.connect("movement_key_pressed",_on_input_handler_movement_key_pressed)

func _unhandled_input(event):
	if event.is_action_pressed("zoom_in_mouse"):
		_target_zoom = (zoom * _zoom_step).clamp(min_zoom, max_zoom)
	elif event.is_action_pressed("zoom_out_mouse"):
		_target_zoom = (zoom / _zoom_step).clamp(min_zoom, max_zoom)

func _on_input_handler_movement_key_pressed(direction : Vector2i, delta : float) -> void:
	if direction == Vector2i.UP or direction == Vector2i.DOWN:
		move_local_y(delta * (speed * direction.y) / get_zoom().x)
	elif direction == Vector2i.LEFT or direction == Vector2i.RIGHT:
		move_local_x(delta * (speed * direction.x) / get_zoom().x)

func _process(delta: float) -> void:
	if _target_zoom and _target_zoom != zoom:
		zoom = zoom.lerp(_target_zoom, delta * 6)
		if zoom.x < _target_zoom.x + 0.01 and zoom.x > _target_zoom.x - 0.01:
			zoom = _target_zoom
