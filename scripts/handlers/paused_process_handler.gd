@icon("res://textures/editor_icons/pause-button.svg")
extends Node

@export var pause_menu : PanelContainer
@export var save_confirmation_menu : PanelContainer

func _on_main_menu_button_pressed() -> void:
	pause_menu.hide()
	save_confirmation_menu.show()


func _on_exit_button_pressed() -> void:
	pause_menu.hide()
	save_confirmation_menu.show()


func _on_options_button_pressed() -> void:
	printerr("_on_options_button_pressed not implemented")


func _on_cancel_button_pressed() -> void:
	pause_menu.show()
	save_confirmation_menu.hide()


func _on_save_progress_pressed() -> void:
	GlobalSaver.save()
	SceneTransition.start_trans(false, 0.4)
	await SceneTransition.done
	get_tree().change_scene_to_packed(GlobalRef.get_scene(GlobalRef.scenes_enum.main_menu))


func _on_dont_save_progress_pressed() -> void:
	printerr("_on_dont_save_progress_pressed not implemented")
