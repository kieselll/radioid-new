extends Control

var fade_in_tween: Tween
var fade_out_tween: Tween
var current_popup_type: popup_types

@export var create_world_button: Button
@export var back_button: Button
@export var name_edit: TextEdit
@export var seed_edit: TextEdit
@export_category("Popups")
@export var blur_panel: Panel
@export var popup_panel: PanelContainer
@export var popup_text: RichTextLabel
@export var popup_button_1: Button
@export var popup_button_2: Button

enum popup_types { save_name_exists, save_name_empty }


func _ready() -> void:
	SceneTransition.finish_trans()


func _show_popup(popup_type: popup_types) -> void:
	match popup_type:
		popup_types.save_name_exists:
			popup_text.text = "A save with the same name has been detected!\nWould you like to overwrite the save file? [color=red]This cannot be undone![/color]"
			popup_button_1.text = "yes, DELETE!"
		popup_types.save_name_empty:
			popup_text.text = "You haven't entered a save name! The save name will be set to the current date and time. Would you like to go back and change it?"
			popup_button_1.text = "no, REPLACE!"
	var opacity_tween = (
		create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	)
	blur_panel.self_modulate = Color(1.0, 1.0, 1.0, 0.0)
	popup_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	blur_panel.show()
	popup_panel.show()
	opacity_tween.tween_property(blur_panel, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)
	opacity_tween.tween_property(popup_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)


func _on_back_button_pressed():
	SceneTransition.start_trans()
	await SceneTransition.done
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_create_world_button_pressed():
	if GlobalSaver.get_saves_list().has(name_edit.text.to_snake_case()):
	elif name_edit.text.is_empty():
	else:
		GlobalSaver.write_save(
			name_edit.text.to_snake_case(),
			name_edit.text,
			seed_edit.text.to_int() if not seed_edit.text.is_empty() else randi()
		)
		SceneTransition.start_trans()
		await SceneTransition.done
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func animate_button(button: Button, self_scale: Vector2, color: Color) -> void:
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "scale", self_scale, 0.3).set_trans(Tween.TRANS_CIRC)
	tween.parallel().tween_property(button.get_theme_stylebox("normal"), "bg_color", color, 0.3)


func _on_back_mouse_entered() -> void:
	animate_button(back_button, Vector2(1.2, 1.2), Color("c5b405ff"))


func _on_back_mouse_exited() -> void:
	animate_button(back_button, Vector2(1, 1), Color("1a1a1a"))


func _on_create_world_mouse_entered() -> void:
	animate_button(create_world_button, Vector2(1.2, 1.2), Color("86c900"))


func _on_create_world_mouse_exited() -> void:
	animate_button(create_world_button, Vector2(1, 1), Color("1a1a1a"))
