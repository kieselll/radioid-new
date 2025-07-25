@icon("res://textures/editor_icons/pause-button.svg")
extends Node
var dir_access = DirAccess.open(Global.game_location + "/saves")
var file_access: FileAccess
var save_name: String
var ground_tiles_array = {}
var terrain_tiles_array = {}
var walls_tiles_array = {}
var light_masked_tiles_array = {}
var ground_queued_tiles_array = {}
var terrain_queued_tiles_array = {}
var walls_queued_tiles_array = {}
var light_masked_queued_tiles_array = {}
var ground_queued_d_tiles_array = {}
var terrain_queued_d_tiles_array = {}
var walls_queued_d_tiles_array = {}
var light_masked_queued_d_tiles_array = {}

func _on_resume_button_pressed() -> void :
	$"../../Control/popup_layer/pause_menu".hide()
	$"../../Control/popup_layer/Panel3".hide()
	get_tree().paused = false

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
	var stored_data = JSON.stringify([
		ground_tiles_array, ground_queued_tiles_array, ground_queued_d_tiles_array, 
		terrain_tiles_array, terrain_queued_tiles_array, terrain_queued_d_tiles_array, 
		walls_tiles_array, walls_queued_tiles_array, walls_queued_d_tiles_array, 
		light_masked_tiles_array, light_masked_queued_tiles_array, light_masked_queued_d_tiles_array])
	save_name = Time.get_date_string_from_system() + Time.get_time_string_from_system()
	dir_access.make_dir_recursive(save_name)
	file_access = FileAccess.open(Global.game_location + "/saves" + Time.get_date_string_from_system() + "_" + Time.get_time_string_from_system() + "/map_data.dat", FileAccess.READ_WRITE)
	file_access.store_string(stored_data)

func _on_dont_save_progress_pressed() -> void :
	printerr("_on_dont_save_progress_pressed not implemented")

func _input(event: InputEvent) -> void :
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
		$"../../Control/popup_layer/pause_menu".hide()
		$"../../Control/popup_layer/Panel3".hide()
		get_tree().paused = false
		get_viewport().set_input_as_handled()
