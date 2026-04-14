extends Control

var fade_in_tween
var fade_out_tween

@export var create_world_button : Button
@export var back_button : Button


func _ready() -> void:
	SceneTransition.finish_trans()


func _on_back_button_pressed():
	SceneTransition.start_trans()
	await SceneTransition.done
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_create_world_button_pressed():

	SceneTransition.start_trans()
	await SceneTransition.done
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func animate_button(button : Button, self_scale: Vector2, color: Color) -> void:
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "scale", self_scale, 0.3).set_trans(Tween.TRANS_CIRC)
	tween.parallel().tween_property(button.get_theme_stylebox("normal"), "bg_color", color, 0.3)


func _on_back_mouse_entered() -> void:
	animate_button(
		back_button,
		Vector2(1.2, 1.2),
		Color("c5b405ff")
	)


func _on_back_mouse_exited() -> void:
	animate_button(back_button, Vector2(1, 1), Color("1a1a1a"))


func _on_create_world_mouse_entered() -> void:
	animate_button(
		create_world_button,
		Vector2(1.2, 1.2),
		Color("86c900")
	)


func _on_create_world_mouse_exited() -> void:
	animate_button(create_world_button, Vector2(1, 1), Color("1a1a1a"))
