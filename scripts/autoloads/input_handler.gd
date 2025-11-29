extends Node2D

var _tilemap
var _ui_manager

var _keyboard_input_allowed : bool = true
var _mouse_input_allowed : bool = true
var _click_1 = null
var _click_2 = null
var _prev_mouse_map_pos = null
var _prev_scene = ""

var current_item : BuildableData

signal region_selected(rect : Rect2i, _click_2 : Vector2i)
signal region_updated(rect : Rect2i)
signal movement_key_pressed(direction : Vector2i, delta : float)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	$/root/GameRoot/Control/popup_layer/pause_menu/VBoxContainer/resume_button.pressed.connect(_on_resume_button_pressed)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and _mouse_input_allowed:
		_handle_mouse_button(event)
	elif event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_F5:
			DebugMenu.visible = not DebugMenu.visible
			_keyboard_input_allowed = not DebugMenu.visible
		elif event.keycode == KEY_ESCAPE:
			if not $/root/GameRoot/Control/popup_layer/Panel3.visible:
				show_pause()
			else:
				hide_pause()
		elif event.keycode == KEY_F1:
			if $/root/GameRoot/Control/CanvasLayer.visible:
				GlobalLogger.write_to_logs(self, "UI was hidden")
				$/root/GameRoot/Control/CanvasLayer.hide()
			else:
				GlobalLogger.write_to_logs(self, "UI was shown")
				$/root/GameRoot/Control/CanvasLayer.show()


func _physics_process(delta: float) -> void:
	if get_tree().current_scene and _prev_scene != get_tree().current_scene.name and get_tree().current_scene.name == "GameRoot":
		_ui_manager = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.ui_manager))
		_tilemap = get_node(GlobalRef.get_game_node_path(GlobalRef.game_nodes_enum.tilemap))
	if _mouse_input_allowed:
		_handle_mouse_motion()
	if _keyboard_input_allowed:
		if Input.is_action_pressed("up"):
				movement_key_pressed.emit(Vector2i.UP, delta)
		if Input.is_action_pressed("left"):
				movement_key_pressed.emit(Vector2i.LEFT, delta)
		if Input.is_action_pressed("down"):
				movement_key_pressed.emit(Vector2i.DOWN, delta)
		if Input.is_action_pressed("right"):
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
					region_selected.emit(Rect2i(_tilemap.local_to_map(_click_1), _tilemap.local_to_map(_click_2) - _tilemap.local_to_map(_click_1)).abs())
					print(_tilemap.local_to_map(_click_1))
					print(_tilemap.local_to_map(_click_2))
				_click_2 = null
				_click_1 = null

func set_keyboard_input_allowed(allowed : bool):
	_keyboard_input_allowed = allowed

func set_mouse_input_allowed(allowed : bool):
	_mouse_input_allowed = allowed

func show_pause():
	_keyboard_input_allowed = false
	_mouse_input_allowed = false
	GlobalLogger.write_to_logs(self, "Pause menu is opened")
	$/root/GameRoot/Control/popup_layer/pause_menu.show()
	var pause_tween = create_tween().set_trans(Tween.TRANS_LINEAR).parallel()
	pause_tween.tween_property($/root/GameRoot/Control/popup_layer/pause_menu, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
	$/root/GameRoot/Control/popup_layer/Panel3.show()
	get_tree().paused = true
	get_viewport().set_input_as_handled()

func hide_pause():
	_keyboard_input_allowed = true
	_mouse_input_allowed = true
	GlobalLogger.write_to_logs(self, "Pause menu is closed")
	var pause_tween = create_tween().set_trans(Tween.TRANS_LINEAR).parallel()
	pause_tween.tween_property($/root/GameRoot/Control/popup_layer/pause_menu, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.5)
	await pause_tween.finished
	$/root/GameRoot/Control/popup_layer/pause_menu.hide()
	$/root/GameRoot/Control/popup_layer/Panel3.hide()
	$/root/GameRoot/Control/popup_layer/save_confirmation_menu.hide()
	get_tree().paused = false
	get_viewport().set_input_as_handled()

func _on_resume_button_pressed():
	hide_pause()
