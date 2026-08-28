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
	current_popup_type = popup_type
	match popup_type:
		popup_types.save_name_exists:
			popup_text.text = "A save with the same name has been detected!\nWould you like to overwrite the save file? [color=red]This cannot be undone![/color]"
			popup_button_1.text = "yes, DELETE!"
			popup_button_2.text = "no, CANCEL!"
		popup_types.save_name_empty:
			popup_text.text = "You haven't entered a save name! The save name will be set to the current date and time. Would you like to go back and change it?"
			popup_button_1.text = "no, REPLACE!"
			popup_button_2.text = "yes, GO BACK!"
	var opacity_tween = (
		create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	)
	blur_panel.self_modulate = Color(1.0, 1.0, 1.0, 0.0)
	popup_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	blur_panel.show()
	popup_panel.show()
	opacity_tween.tween_property(blur_panel, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)
	opacity_tween.tween_property(popup_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)

func _hide_popup() -> void:
	var opacity_tween = (
		create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	)
	blur_panel.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	popup_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
	opacity_tween.tween_property(blur_panel, "self_modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4)
	opacity_tween.tween_property(popup_panel, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4)
	blur_panel.hide()
	popup_panel.hide()

func _on_back_button_pressed():
	SceneTransition.start_trans()
	await SceneTransition.done
	get_tree().change_scene_to_file("res://features/ui/menus/menu.tscn")


func _on_create_world_button_pressed():
	if GlobalSaver.get_saves_list().has(name_edit.text.to_snake_case()):
		_show_popup(popup_types.save_name_exists)
	elif name_edit.text.is_empty():
		_show_popup(popup_types.save_name_empty)
	else:
		GlobalSaver.write_save(
			name_edit.text.to_snake_case(),
			name_edit.text,
			seed_edit.text.to_int() if not seed_edit.text.is_empty() else randi()
		)
		SceneTransition.start_trans()
		await SceneTransition.done
		get_tree().change_scene_to_file("res://features/world/game.tscn")


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

func _on_popup_button_1_pressed() -> void:
	match current_popup_type:
		popup_types.save_name_exists:
			_hide_popup()
			GlobalSaver.delete_save(name_edit.text)
			GlobalSaver.write_save(
				name_edit.text.to_snake_case(),
				name_edit.text,
				seed_edit.text.to_int() if not seed_edit.text.is_empty() and seed_edit.text.is_valid_int() else randi()
			)
			SceneTransition.start_trans()
			await SceneTransition.done
			get_tree().change_scene_to_file("res://features/world/game.tscn")
		popup_types.save_name_empty:
			_hide_popup()
			GlobalSaver.write_save(
				Time.get_datetime_string_from_system().replace_char(":".unicode_at(0),"-".unicode_at(0)).replace_char("T".unicode_at(0),",".unicode_at(0)),
				Time.get_datetime_string_from_system().replace_char("T".unicode_at(0),",".unicode_at(0)),
				seed_edit.text.to_int() if not seed_edit.text.is_empty() and seed_edit.text.is_valid_int() else randi()
			)
			SceneTransition.start_trans()
			await SceneTransition.done
			get_tree().change_scene_to_file("res://features/world/game.tscn")


func _on_popup_button_2_pressed() -> void:
	match current_popup_type:
		popup_types.save_name_exists:
			_hide_popup()
		popup_types.save_name_empty:
			_hide_popup()
