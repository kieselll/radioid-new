extends Control

var fade_in_tween
var fade_out_tween

func _ready() -> void :
	SceneTransition.finish_trans()

func _on_button_2_pressed():
	SceneTransition.start_trans()
	await SceneTransition.done
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_button_pressed():
	SceneTransition.start_trans()
	await SceneTransition.done
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func animate_button(button: Button, scale: Vector2, position: Vector2, color: Color) -> void :
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "scale", scale, 0.3).set_trans(Tween.TRANS_CIRC)
	tween.parallel().tween_property(button, "position", position, 0.3).set_trans(Tween.TRANS_CIRC)
	tween.parallel().tween_property(button.get_theme_stylebox("normal"), "bg_color", color, 0.3)

func _on_back_mouse_entered() -> void :
	animate_button($Container / Back, Vector2(1.2, 1.2), $Container / Back.position - Vector2(4.9, 4.1), Color("c5b405ff"))

func _on_back_mouse_exited() -> void :
	animate_button($Container / Back, Vector2(1, 1), Vector2(0, 0), Color("1a1a1a"))

func _on_create_world_mouse_entered() -> void :
	animate_button($"Container2/Create World", Vector2(1.2, 1.2), $"Container2/Create World".position - Vector2(15, 4.1), Color("86c900"))

func _on_create_world_mouse_exited() -> void :
	animate_button($"Container2/Create World", Vector2(1, 1), Vector2(0, 0), Color("1a1a1a"))
