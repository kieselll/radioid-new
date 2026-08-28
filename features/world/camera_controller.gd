extends Camera2D
@export var speed: float = 1000.0
@export var zoom_speed := 0.7
@export var min_zoom := Vector2(0.3, 0.3)
@export var max_zoom := Vector2(8, 8)
var _target_zoom: Vector2 = Vector2.ONE
var _zoom_step := 1.8
var _invert_movement := false
var _invert_zoom := false


func _ready() -> void:
	var movement_setting: Variant = GlobalCfg.get_setting(
		"controls", "camera_movement_sensitivity", 100
	)
	var zoom_setting: Variant = GlobalCfg.get_setting(
		"controls", "camera_zoom_sensitivity", 100
	)
	var invert_movement_setting: Variant = GlobalCfg.get_setting(
		"controls", "invert_camera_movement", false
	)
	var invert_zoom_setting: Variant = GlobalCfg.get_setting(
		"controls", "invert_camera_zoom", false
	)
	var movement_sensitivity := (
		float(movement_setting) if movement_setting is float or movement_setting is int else 100.0
	)
	var zoom_sensitivity := (
		float(zoom_setting) if zoom_setting is float or zoom_setting is int else 100.0
	)
	speed *= movement_sensitivity / 100.0
	_zoom_step = 1.0 + 0.8 * zoom_sensitivity / 100.0
	_invert_movement = invert_movement_setting if invert_movement_setting is bool else false
	_invert_zoom = invert_zoom_setting if invert_zoom_setting is bool else false
	InputHandler.connect("movement_key_pressed", _on_input_handler_movement_key_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in_mouse"):
		_target_zoom = (zoom / _zoom_step if _invert_zoom else zoom * _zoom_step).clamp(min_zoom, max_zoom)
	elif event.is_action_pressed("zoom_out_mouse"):
		_target_zoom = (zoom * _zoom_step if _invert_zoom else zoom / _zoom_step).clamp(min_zoom, max_zoom)


func _on_input_handler_movement_key_pressed(direction: Vector2i, delta: float) -> void:
	if _invert_movement:
		direction = -direction
	if direction == Vector2i.UP or direction == Vector2i.DOWN:
		move_local_y(delta * (speed * direction.y) / get_zoom().x)
	elif direction == Vector2i.LEFT or direction == Vector2i.RIGHT:
		move_local_x(delta * (speed * direction.x) / get_zoom().x)


func _process(delta: float) -> void:
	if _target_zoom and _target_zoom != zoom:
		zoom = zoom.lerp(_target_zoom, delta * 6)
		if zoom.x < _target_zoom.x + 0.01 and zoom.x > _target_zoom.x - 0.01:
			zoom = _target_zoom
