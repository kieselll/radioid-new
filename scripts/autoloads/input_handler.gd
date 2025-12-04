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
#				 /$$    /$$   /$$$$$$    /$$$$$$    /$$$$$$$
#				|  $$  /$$/  |____  $$  /$$__  $$  /$$_____/
#				 \  $$/$$/    /$$$$$$$ | $$  \__/ |  $$$$$$
#				  \  $$$/    /$$__  $$ | $$        \____  $$
#				   \  $/    |  $$$$$$$ | $$        /$$$$$$$/
#				    \_/      \_______/ |__/       |_______/

var _tilemap
var _ui_manager

var _keyboard_input_allowed: bool = true
var _mouse_input_allowed: bool = true

var _click_1 = null
var _click_2 = null
var _prev_mouse_map_pos = null
var _prev_scene: String = ""

var current_item: BuildableData

#				 /$$$$$$$               /$$      /$$
#				| $$__  $$             | $$     | $$
#				| $$  \ $$  /$$$$$$   /$$$$$$   | $$$$$$$
#				| $$$$$$$/ |____  $$ |_  $$_/   | $$__  $$
#				| $$____/   /$$$$$$$   | $$     | $$  \ $$
#				| $$       /$$__  $$   | $$ /$$ | $$  | $$
#				| $$      |  $$$$$$$   |  $$$$/ | $$  | $$
#				|__/       \_______/    \___/   |__/  |__/
#
#
#
#				                        /$$$$$$
#				                       /$$__  $$
#				  /$$$$$$    /$$$$$$  | $$  \__/ /$$$$$$$
#				 /$$__  $$  /$$__  $$ | $$$$    /$$_____/
#				| $$  \__/ | $$$$$$$$ | $$_/   |  $$$$$$
#				| $$       | $$_____/ | $$      \____  $$
#				| $$       |  $$$$$$$ | $$      /$$$$$$$/
#				|__/        \_______/ |__/     |_______/

@onready var _pause_menu := $/root/GameRoot/Control/popup_layer/pause_menu
@onready
var _resume_button := $/root/GameRoot/Control/popup_layer/pause_menu/VBoxContainer/resume_button
@onready var _ui_layer := $/root/GameRoot/Control/CanvasLayer
@onready var _blur_layer := $/root/GameRoot/Control/popup_layer/Panel3  # эффект блюра / инверсии
@onready var _save_confirm := $/root/GameRoot/Control/popup_layer/save_confirmation_menu

@onready var _popup_layer := $/root/GameRoot/Control/popup_layer

#				  /$$$$$$   /$$                                   /$$
#				 /$$__  $$ |__/                                  | $$
#				| $$  \__/  /$$   /$$$$$$   /$$$$$$$    /$$$$$$  | $$   /$$$$$$$
#				|  $$$$$$  | $$  /$$__  $$ | $$__  $$  |____  $$ | $$  /$$_____/
#				 \____  $$ | $$ | $$  \ $$ | $$  \ $$   /$$$$$$$ | $$ |  $$$$$$
#				 /$$  \ $$ | $$ | $$  | $$ | $$  | $$  /$$__  $$ | $$  \____  $$
#				|  $$$$$$/ | $$ |  $$$$$$$ | $$  | $$ |  $$$$$$$ | $$  /$$$$$$$/
#				 \______/  |__/  \____  $$ |__/  |__/  \_______/ |__/ |_______/
#				                 /$$  \ $$
#				                |  $$$$$$/
#				                 \______/

signal region_selected(rect: Rect2i, _click_2: Vector2i)
signal region_updated(rect: Rect2i)
signal movement_key_pressed(direction: Vector2i, delta: float)

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(_on_resume_button_pressed)


func _physics_process(delta: float) -> void:
	# Lazy-load handlers when scene changes
	if (
		get_tree().current_scene
		and _prev_scene != get_tree().current_scene.name
		and get_tree().current_scene.name == "GameRoot"
	):
		_prev_scene = get_tree().current_scene.name
		_ui_manager = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.ui_manager))
		_tilemap = get_node(GlobalRef.get_game_node_path(GlobalRef.game_nodes_enum.tilemap))

	# Mouse input
	if _mouse_input_allowed:
		_handle_mouse_motion()

	# Keyboard input
	if _keyboard_input_allowed:
		if Input.is_action_pressed("up"):
			movement_key_pressed.emit(Vector2i.UP, delta)
		if Input.is_action_pressed("left"):
			movement_key_pressed.emit(Vector2i.LEFT, delta)
		if Input.is_action_pressed("down"):
			movement_key_pressed.emit(Vector2i.DOWN, delta)
		if Input.is_action_pressed("right"):
			movement_key_pressed.emit(Vector2i.RIGHT, delta)


#				 /$$$$$$                                     /$$
#				|_  $$_/                                    | $$
#				  | $$    /$$$$$$$    /$$$$$$   /$$   /$$  /$$$$$$
#				  | $$   | $$__  $$  /$$__  $$ | $$  | $$ |_  $$_/
#				  | $$   | $$  \ $$ | $$  \ $$ | $$  | $$   | $$
#				  | $$   | $$  | $$ | $$  | $$ | $$  | $$   | $$ /$$
#				 /$$$$$$ | $$  | $$ | $$$$$$$/ |  $$$$$$/   |  $$$$/
#				|______/ |__/  |__/ | $$____/   \______/     \___/
#				                    | $$
#				                    | $$
#				                    |__/


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and _mouse_input_allowed:
		_handle_mouse_button(event)
		return

	if event is InputEventKey and event.is_pressed():
		_handle_keyboard_input(event)


func _handle_keyboard_input(event: InputEventKey) -> void:
	match event.keycode:
		KEY_F5:
			DebugMenu.visible = not DebugMenu.visible
			_keyboard_input_allowed = not DebugMenu.visible

		KEY_ESCAPE:
			if not _blur_layer.visible:
				show_pause()
			else:
				hide_pause()

		KEY_F1:
			if _ui_layer.visible:
				GlobalLogger.write_to_logs(self, "UI was hidden")
				_ui_layer.hide()
			else:
				GlobalLogger.write_to_logs(self, "UI was shown")
				_ui_layer.show()


func _handle_mouse_motion() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _click_1:
		var mouse_map = _tilemap.local_to_map(get_global_mouse_position())

		if _prev_mouse_map_pos and mouse_map != _prev_mouse_map_pos:
			var rect := (
				Rect2i(_tilemap.local_to_map(_click_1), mouse_map - _tilemap.local_to_map(_click_1))
				. abs()
			)
			region_updated.emit(rect)

		_prev_mouse_map_pos = mouse_map


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if get_tree().current_scene.name != "GameRoot":
		return

	if event.pressed and not _ui_manager.button_hover:
		_click_2 = null
		_click_1 = get_global_mouse_position()

	elif not event.pressed:
		_click_2 = get_global_mouse_position()

		if _click_1 and _click_2:
			var rect := (
				Rect2i(
					_tilemap.local_to_map(_click_1),
					_tilemap.local_to_map(_click_2) - _tilemap.local_to_map(_click_1)
				)
				. abs()
			)

			region_selected.emit(rect)

		_click_2 = null
		_click_1 = null


#				 /$$$$$$$
#				| $$__  $$
#				| $$  \ $$  /$$$$$$   /$$   /$$   /$$$$$$$   /$$$$$$
#				| $$$$$$$/ |____  $$ | $$  | $$  /$$_____/  /$$__  $$
#				| $$____/   /$$$$$$$ | $$  | $$ |  $$$$$$  | $$$$$$$$
#				| $$       /$$__  $$ | $$  | $$  \____  $$ | $$_____/
#				| $$      |  $$$$$$$ |  $$$$$$/  /$$$$$$$/ |  $$$$$$$
#				|__/       \_______/  \______/  |_______/   \_______/
#
#
#
#				 /$$                              /$$
#				| $$                             |__/
#				| $$         /$$$$$$    /$$$$$$   /$$   /$$$$$$$
#				| $$        /$$__  $$  /$$__  $$ | $$  /$$_____/
#				| $$       | $$  \ $$ | $$  \ $$ | $$ | $$
#				| $$       | $$  | $$ | $$  | $$ | $$ | $$
#				| $$$$$$$$ |  $$$$$$/ |  $$$$$$$ | $$ |  $$$$$$$
#				|________/  \______/   \____  $$ |__/  \_______/
#				                       /$$  \ $$
#				                      |  $$$$$$/
#				                       \______/


func show_pause() -> void:
	_keyboard_input_allowed = false
	_mouse_input_allowed = false

	GlobalLogger.write_to_logs(self, "Pause menu is opened")

	_pause_menu.show()
	_blur_layer.show()

	var tween := create_tween().set_trans(Tween.TRANS_LINEAR).parallel()
	tween.tween_property(_pause_menu, "modulate", Color(1, 1, 1, 1), 0.5)

	get_tree().paused = true
	get_viewport().set_input_as_handled()


func hide_pause() -> void:
	_keyboard_input_allowed = true
	_mouse_input_allowed = true

	GlobalLogger.write_to_logs(self, "Pause menu is closed")

	var tween := create_tween().set_trans(Tween.TRANS_LINEAR).parallel()
	tween.tween_property(_pause_menu, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished

	_pause_menu.hide()
	_blur_layer.hide()
	_save_confirm.hide()

	get_tree().paused = false
	get_viewport().set_input_as_handled()


func _on_resume_button_pressed() -> void:
	hide_pause()


#				  /$$$$$$                /$$      /$$
#				 /$$__  $$              | $$     | $$
#				| $$  \__/   /$$$$$$   /$$$$$$  /$$$$$$     /$$$$$$    /$$$$$$    /$$$$$$$
#				|  $$$$$$   /$$__  $$ |_  $$_/ |_  $$_/    /$$__  $$  /$$__  $$  /$$_____/
#				 \____  $$ | $$$$$$$$   | $$     | $$     | $$$$$$$$ | $$  \__/ |  $$$$$$
#				 /$$  \ $$ | $$_____/   | $$ /$$ | $$ /$$ | $$_____/ | $$        \____  $$
#				|  $$$$$$/ |  $$$$$$$   |  $$$$/ |  $$$$/ |  $$$$$$$ | $$        /$$$$$$$/
#				 \______/   \_______/    \___/    \___/    \_______/ |__/       |_______/


func set_keyboard_input_allowed(allowed: bool) -> void:
	_keyboard_input_allowed = allowed


func set_mouse_input_allowed(allowed: bool) -> void:
	_mouse_input_allowed = allowed
