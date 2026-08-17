extends Control
var previous_position: Vector2i
var window_velocity: Vector2
var window: Window
var default_button_color = Color("1a1a1a")
var button_hover_sound = load("res://sounds/UI/button_hover.wav")
@onready var audiostream = $AudioStreamPlayer
@onready var rigid_bodies: Array[RigidBody2D] = [
	$Node2D/RigidBody2D,
	$Node2D/RigidBody2D2,
	$Node2D/RigidBody2D3,
	$Node2D/RigidBody2D4,
	$Node2D/RigidBody2D5,
	$Node2D/RigidBody2D6,
]
@export var menu_buttons: Array[Button] = []
var button_color_array: Array[Color] = [
	Color("659900"), Color("659900"), Color("659900"), Color("90000e")
]


func _ready() -> void:
	GlobalLogger.write_to_logs(self, "Current scene: Main menu")
	window = get_window()
	window.title = "Radioid: Main menu"
	if SceneTransition.first_entry:
		SceneTransition.show_dev_icon()
		await SceneTransition.done
		SceneTransition.start_animation(0.5)
		await SceneTransition.done
		SceneTransition.first_entry = false
	SceneTransition.finish_trans()

	await get_tree().process_frame
	var max_button_size := Vector2(0, 0)
	var button_x_position: float = INT32_MAX
	for i in menu_buttons:
		if i.size > max_button_size: max_button_size = i.size
		if i.position.x < button_x_position: button_x_position = i.position.x
		print(max_button_size)
		print(button_x_position)
		i.pivot_offset_ratio = Vector2(0.5, 0.5)
		i.mouse_entered.connect(_process_button_anims_and_sounds.bind(i, true))
		i.mouse_exited.connect(_process_button_anims_and_sounds.bind(i, false))

	for i in menu_buttons:
		i.size = max_button_size
		i.position.x = button_x_position

func _process(delta: float) -> void:
	$Node2D/right_border.position.x = window.size.x
	$Node2D/bottom_border.position.y = window.size.y
	window_velocity = ((window.position - previous_position) / delta) * -0.4
	previous_position = window.position

	for i in rigid_bodies:
		i.apply_central_force(window_velocity)

func _animate_button(button: Button, button_scale: Vector2, color: Color) -> void:
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "scale", button_scale, 0.3).set_trans(Tween.TRANS_CIRC)
	tween.parallel().tween_property(button.get_theme_stylebox("normal"), "bg_color", color, 0.3)


func _modulate_body(body: RigidBody2D, color: Color):
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(body, "modulate", color, 0.3)


func _on_new_game_pressed():
	SceneTransition.start_trans()
	await SceneTransition.done
	get_tree().change_scene_to_file("res://scenes/worldmaking.tscn")


func _on_quit_pressed():
	SceneTransition.start_trans()
	await SceneTransition.done
	GlobalLogger.write_to_logs(self, "Quitting. Goodbye!")
	GlobalLogger.open_log_file()
	get_tree().quit()


func _on_options_pressed():
	SceneTransition.start_trans()
	await SceneTransition.done
	get_tree().change_scene_to_file("res://scenes/options.tscn")


func _on_load_game_pressed():
	SceneTransition.start_trans()
	await SceneTransition.done
	get_tree().change_scene_to_file("res://scenes/save_loader.tscn")


func _process_button_anims_and_sounds(button: Button, entered: bool):
	if entered:
		_animate_button(button, Vector2(1.1, 1.1), button_color_array[menu_buttons.find(button)])
		audiostream.stream = button_hover_sound
		audiostream.play()

	else:
		_animate_button(button, Vector2(1, 1), default_button_color)


func _on_rigid_body_2d_mouse_entered() -> void:
	_modulate_body($Node2D/RigidBody2D, Color(1.5, 1.5, 1.5))


func _on_rigid_body_2d_mouse_exited() -> void:
	_modulate_body($Node2D/RigidBody2D, Color(0.65, 0.65, 0.65))


func _on_rigid_body_2d_2_mouse_entered() -> void:
	_modulate_body($Node2D/RigidBody2D2, Color(1.5, 1.5, 1.5))


func _on_rigid_body_2d_2_mouse_exited() -> void:
	_modulate_body($Node2D/RigidBody2D2, Color(0.65, 0.65, 0.65))


func _on_rigid_body_2d_3_mouse_entered() -> void:
	_modulate_body($Node2D/RigidBody2D3, Color(1.5, 1.5, 1.5))


func _on_rigid_body_2d_3_mouse_exited() -> void:
	_modulate_body($Node2D/RigidBody2D3, Color(0.65, 0.65, 0.65))


func _on_rigid_body_2d_4_mouse_entered() -> void:
	_modulate_body($Node2D/RigidBody2D4, Color(1.3, 1.3, 1.3))


func _on_rigid_body_2d_4_mouse_exited() -> void:
	_modulate_body($Node2D/RigidBody2D4, Color(0.65, 0.65, 0.65))


func _on_rigid_body_2d_5_mouse_entered() -> void:
	_modulate_body($Node2D/RigidBody2D5, Color(1.5, 1.5, 1.5))


func _on_rigid_body_2d_5_mouse_exited() -> void:
	_modulate_body($Node2D/RigidBody2D5, Color(0.65, 0.65, 0.65))


func _on_rigid_body_2d_6_mouse_entered() -> void:
	_modulate_body($Node2D/RigidBody2D6, Color(1.5, 1.5, 1.5))


func _on_rigid_body_2d_6_mouse_exited() -> void:
	_modulate_body($Node2D/RigidBody2D6, Color(0.65, 0.65, 0.65))
