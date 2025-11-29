@icon("res://textures/editor_icons/pause-button.svg")
extends Node

func _on_main_menu_button_pressed() -> void :
	$"../../Control/popup_layer/pause_menu".hide()
	$"../../Control/popup_layer/save_confirmation_menu".show()

func _on_exit_button_pressed() -> void :
	$"../../Control/popup_layer/pause_menu".hide()
	$"../../Control/popup_layer/save_confirmation_menu".show()

func _on_options_button_pressed() -> void :
	printerr("_on_options_button_pressed not implemented")

func _on_cancel_button_pressed() -> void :
	$"../../Control/popup_layer/pause_menu".show()
	$"../../Control/popup_layer/save_confirmation_menu".hide()

func _on_save_progress_pressed() -> void :
	printerr("FUCKING IMPLEMENT SAVING ALREADY (NOT IN THE UI)")

func _on_dont_save_progress_pressed() -> void :
	printerr("_on_dont_save_progress_pressed not implemented")
