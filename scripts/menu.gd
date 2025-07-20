extends Control
var previous_position: Vector2i
var window_velocity
var fade_in_tween
var fade_out_tween
var default_button_color = Color("1a1a1a")
var button_hover_sound = load("res://sounds/UI/button_hover.wav")
@onready var audiostream = $AudioStreamPlayer
@onready var rigid_bodies: Array[RigidBody2D] = [
	$Node2D / RigidBody2D, 
	$Node2D / RigidBody2D2, 
	$Node2D / RigidBody2D3, 
	$Node2D / RigidBody2D4, 
	$Node2D / RigidBody2D5, 
	$Node2D / RigidBody2D6, 
]
@onready var menu_buttons: Array[Button] = [
	$MarginContainer / CanvasLayer / VBoxContainer / Button4, 
	$MarginContainer / CanvasLayer / VBoxContainer / Button, 
	$MarginContainer / CanvasLayer / VBoxContainer / Button2, 
	$MarginContainer / CanvasLayer / VBoxContainer / Button3
]
var button_color_array: Array[Color] = [
	Color("86c900"), 
	Color("86c900"), 
	Color("86c900"), 
	Color("90000e")
]
var button_default_pos_array = [Vector2(0, 0), Vector2(0, 31), Vector2(0, 62), Vector2(0, 93)]

func _ready() -> void :
	get_window().title = "Radioid: Main menu"
	fade_in_tween = create_tween().set_ease(Tween.EASE_IN)
	fade_in_tween.tween_property($MarginContainer / CanvasLayer / ColorRect2, "color", Color(0, 0, 0, 0), 1.0).from(Color(0, 0, 0, 1))

	for i in menu_buttons:
		i.mouse_entered.connect(_process_button_anims_and_sounds.bind(i, true))
		i.mouse_exited.connect(_process_button_anims_and_sounds.bind(i, false))

func _process(delta: float) -> void :
	$Node2D / right_border.position.x = get_window().size.x - 26
	$Node2D / bottom_border.position.y = get_window().size.y - 24
	window_velocity = ((get_window().position - previous_position) / delta) * -0.4
	previous_position = get_window().position

	for i in rigid_bodies:
		i.apply_central_force(window_velocity)

func _animate_button(button: Button, scale: Vector2, position: Vector2, color: Color) -> void :
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "scale", scale, 0.3).set_trans(Tween.TRANS_CIRC)
	tween.parallel().tween_property(button, "position", position, 0.3).set_trans(Tween.TRANS_CIRC)
	tween.parallel().tween_property(button.get_theme_stylebox("normal"), "bg_color", color, 0.3)

func _modulate_body(body: RigidBody2D, color: Color):
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(body, "modulate", color, 0.3)

func _on_button_pressed():
	fade_out_tween = create_tween().set_ease(Tween.EASE_OUT)
	fade_out_tween.tween_property($MarginContainer / CanvasLayer / ColorRect2, "color", Color(0, 0, 0, 1), 1.0).from(Color(0, 0, 0, 0))
	await fade_out_tween.finished
	get_tree().change_scene_to_file("res://scenes/worldmaking.tscn")

func _on_button_3_pressed():
	fade_out_tween = create_tween().set_ease(Tween.EASE_OUT)
	fade_out_tween.tween_property($MarginContainer / CanvasLayer / ColorRect2, "color", Color(0, 0, 0, 1), 1.0).from(Color(0, 0, 0, 0))
	await fade_out_tween.finished
	get_tree().quit()

func _on_button_2_pressed():
	fade_out_tween = create_tween().set_ease(Tween.EASE_OUT)
	fade_out_tween.tween_property($MarginContainer / CanvasLayer / ColorRect2, "color", Color(0, 0, 0, 1), 1.0).from(Color(0, 0, 0, 0))
	await fade_out_tween.finished
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func _process_button_anims_and_sounds(button: Button, entered: bool):
	if entered:
		_animate_button(button, Vector2(1.2, 1.2), button.position - Vector2(11, 2.7), button_color_array[menu_buttons.find(button)])
		audiostream.stream = button_hover_sound
		audiostream.play()
		
	else:
		_animate_button(button, Vector2(1, 1), button_default_pos_array[menu_buttons.find(button)], default_button_color)


func _on_rigid_body_2d_mouse_entered() -> void :
	_modulate_body($Node2D / RigidBody2D, Color(1.5, 1.5, 1.5))

func _on_rigid_body_2d_mouse_exited() -> void :
	_modulate_body($Node2D / RigidBody2D, Color(0.65, 0.65, 0.65))

func _on_rigid_body_2d_2_mouse_entered() -> void :
	_modulate_body($Node2D / RigidBody2D2, Color(1.5, 1.5, 1.5))

func _on_rigid_body_2d_2_mouse_exited() -> void :
	_modulate_body($Node2D / RigidBody2D2, Color(0.65, 0.65, 0.65))

func _on_rigid_body_2d_3_mouse_entered() -> void :
	_modulate_body($Node2D / RigidBody2D3, Color(1.5, 1.5, 1.5))

func _on_rigid_body_2d_3_mouse_exited() -> void :
	_modulate_body($Node2D / RigidBody2D3, Color(0.65, 0.65, 0.65))

func _on_rigid_body_2d_4_mouse_entered() -> void :
	_modulate_body($Node2D / RigidBody2D4, Color(1.3, 1.3, 1.3))

func _on_rigid_body_2d_4_mouse_exited() -> void :
	_modulate_body($Node2D / RigidBody2D4, Color(0.65, 0.65, 0.65))

func _on_rigid_body_2d_5_mouse_entered() -> void :
	_modulate_body($Node2D / RigidBody2D5, Color(1.5, 1.5, 1.5))

func _on_rigid_body_2d_5_mouse_exited() -> void :
	_modulate_body($Node2D / RigidBody2D5, Color(0.65, 0.65, 0.65))

func _on_rigid_body_2d_6_mouse_entered() -> void :
	_modulate_body($Node2D / RigidBody2D6, Color(1.5, 1.5, 1.5))

func _on_rigid_body_2d_6_mouse_exited() -> void :
	_modulate_body($Node2D / RigidBody2D6, Color(0.65, 0.65, 0.65))
