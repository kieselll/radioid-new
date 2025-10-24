extends Node2D

@onready var _tilemap : TileMapLayer = get_node(GlobalRef.get_tilemap_layer_path(GlobalRef.tilemap_layers_enum.ground))
@onready var _ui_manager = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.ui_manager))

var _keyboard_input_allowed : bool = true
var _mouse_input_allowed : bool = true
var _click_1 = null
var _click_2 = null
var _prev_mouse_map_pos = null

var current_item : BuildableData

signal region_selected(rect : Rect2i, _click_2 : Vector2i)
signal region_updated(rect : Rect2i)
signal movement_key_pressed(direction : Vector2i, delta : float)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and _mouse_input_allowed:
		_handle_mouse_button(event)
	elif event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_F5:
			DebugMenu.visible = not DebugMenu.visible
			_keyboard_input_allowed = not DebugMenu.visible

func _physics_process(delta: float) -> void:
	if _mouse_input_allowed:
		_handle_mouse_motion()
	if Input.is_action_pressed("up"):
		if _keyboard_input_allowed:
			movement_key_pressed.emit(Vector2i.UP, delta)
	if Input.is_action_pressed("left"):
		if _keyboard_input_allowed:
			movement_key_pressed.emit(Vector2i.LEFT, delta)
	if Input.is_action_pressed("down"):
		if _keyboard_input_allowed:
			movement_key_pressed.emit(Vector2i.DOWN, delta)
	if Input.is_action_pressed("right"):
		if _keyboard_input_allowed:
			movement_key_pressed.emit(Vector2i.RIGHT, delta)

func _handle_mouse_motion() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _click_1:
		if _prev_mouse_map_pos and _prev_mouse_map_pos != _tilemap.local_to_map(get_global_mouse_position()):
			region_updated.emit(Rect2i(_tilemap.local_to_map(_click_1), _tilemap.local_to_map(get_global_mouse_position()) - _tilemap.local_to_map(_click_1)).abs())
		_prev_mouse_map_pos = _tilemap.local_to_map(get_global_mouse_position())

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if get_tree().current_scene.name == "GameRoot":
			if event.pressed and not _ui_manager.button_hover:
				_click_2 = null
				_click_1 = get_global_mouse_position()
			elif not event.pressed:
				_click_2 = get_global_mouse_position()
				if _click_1 and _click_2:
					region_selected.emit(Rect2i(_tilemap.local_to_map(_click_1), _tilemap.local_to_map(_click_2) - _tilemap.local_to_map(_click_1)).abs(),_tilemap.local_to_map(_click_2))
				_click_2 = null
				_click_1 = null

func set_keyboard_input_allowed(allowed : bool):
	_keyboard_input_allowed = allowed

func set_mouse_input_allowed(allowed : bool):
	_mouse_input_allowed = allowed
