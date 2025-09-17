extends Control

var dir_access = DirAccess.open(Global.game_location)
var file_access: FileAccess
var current_action
var previous_key
var fade_in_tween
var fade_out_tween
var changed_actions = {
	"up" = (InputMap.action_get_events("up")[0]), 
	"left" = (InputMap.action_get_events("left")[0]), 
	"down" = (InputMap.action_get_events("down")[0]), 
	"right" = (InputMap.action_get_events("right")[0]), 
	"zoom_in" = (InputMap.action_get_events("zoom_in")[0]), 
	"zoom_out" = (InputMap.action_get_events("zoom_out")[0])
}

@onready var settings = {
	"window_type" = $Tabs / Graphics / ScrollContainer / VBoxContainer / window_type / window_type_selector.selected, 
	"frame_rate_limit" = $Tabs / Graphics / ScrollContainer / VBoxContainer / frame_rate_limit / custom_fps_limit.value, 
	"particle_amount" = $Tabs / Graphics / ScrollContainer / VBoxContainer / particle_amount_slider.value, 
	"brightness" = $Tabs / Graphics / ScrollContainer / VBoxContainer / brightness_slider.value, 

	"default_difficuty" = $Tabs / Gameplay / ScrollContainer / VBoxContainer / default_difficulty / default_difficulty_selector.selected, 

	"camera_movement_sensitivity" = $Tabs / Controls / ScrollContainer / VBoxContainer / camera_move_sensitivity_slider.value, 
	"camera_zoom_sensitivity" = $Tabs / Controls / ScrollContainer / VBoxContainer / camera_zoom_sensitivity_slider.value, 
	"invert_camera_movement" = $Tabs / Controls / ScrollContainer / VBoxContainer / invert_camera_movement_toggle.is_pressed(), 
	"invert_camera_zoom_movement" = $Tabs / Controls / ScrollContainer / VBoxContainer / invert_zoom_camera_movement_toggle.is_pressed(), 
	"invert_camera_zoom" = $Tabs / Controls / ScrollContainer / VBoxContainer / invert_camera_zoom_toggle.is_pressed(), 

	"main_volume" = $Tabs / Audio / ScrollContainer / VBoxContainer / main_volume_slider.value, 
	"sfx_volume" = $Tabs / Audio / ScrollContainer / VBoxContainer / sfx_volume_slider.value, 
	"music_volume" = $Tabs / Audio / ScrollContainer / VBoxContainer / music_volume_slider.value, 

	"save_path" = $Tabs / Saves / ScrollContainer / VBoxContainer / WindowType / path_line_edit.text, 
	"autosave_frequency" = $Tabs / Saves / ScrollContainer / VBoxContainer / autosave_frequency_slider.value, 
}
var json_settings

func erase_key(action: StringName) -> void :
	previous_key = InputMap.action_get_events(action)[0]
	get_node("Tabs/Keycodes/ScrollContainer/VBoxContainer/%s/keycode_label" % action).text = "Listening for input"
	current_action = action

func update_settings() -> void :
	update_actions()
	Engine.max_fps = settings["frame_rate_limit"]
	match settings["window_type"]:
		0:
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
		1:
			get_window().mode = Window.MODE_WINDOWED

func update_actions() -> void :
	for i in changed_actions.keys():
		InputMap.action_erase_events(i)
		InputMap.action_add_event(i, changed_actions[i])

func _ready() -> void :
	fade_in_tween = create_tween().set_ease(Tween.EASE_IN)
	fade_in_tween.tween_property($ColorRect, "color", Color(0, 0, 0, 0), 1.0).from(Color(0, 0, 0, 1))

	if dir_access.file_exists(Global.game_location + "/options.cfg"):
		file_access = FileAccess.open(Global.game_location + "/options.cfg", FileAccess.READ)
		$Tabs / Graphics / ScrollContainer / VBoxContainer / window_type / window_type_selector.selected = JSON.parse_string(file_access.get_as_text())["window_type"]
		$Tabs / Graphics / ScrollContainer / VBoxContainer / frame_rate_limit / custom_fps_limit.value = JSON.parse_string(file_access.get_as_text())["frame_rate_limit"]
		$Tabs / Graphics / ScrollContainer / VBoxContainer / particle_amount_slider.value = JSON.parse_string(file_access.get_as_text())["particle_amount"]
		$Tabs / Graphics / ScrollContainer / VBoxContainer / brightness_slider.value = JSON.parse_string(file_access.get_as_text())["brightness"]

		$Tabs / Gameplay / ScrollContainer / VBoxContainer / default_difficulty / default_difficulty_selector.selected = JSON.parse_string(file_access.get_as_text())["default_difficuty"]

		$Tabs / Controls / ScrollContainer / VBoxContainer / camera_move_sensitivity_slider.value = JSON.parse_string(file_access.get_as_text())["camera_movement_sensitivity"]
		$Tabs / Controls / ScrollContainer / VBoxContainer / camera_zoom_sensitivity_slider.value = JSON.parse_string(file_access.get_as_text())["camera_zoom_sensitivity"]
		$Tabs / Controls / ScrollContainer / VBoxContainer / invert_camera_movement_toggle.set_pressed_no_signal(JSON.parse_string(file_access.get_as_text())["invert_camera_movement"])
		$Tabs / Controls / ScrollContainer / VBoxContainer / invert_zoom_camera_movement_toggle.set_pressed_no_signal(JSON.parse_string(file_access.get_as_text())["invert_camera_zoom_movement"])
		$Tabs / Controls / ScrollContainer / VBoxContainer / invert_camera_zoom_toggle.set_pressed_no_signal(JSON.parse_string(file_access.get_as_text())["invert_camera_zoom"])

		$Tabs / Saves / ScrollContainer / VBoxContainer / WindowType / path_line_edit.text = JSON.parse_string(file_access.get_as_text())["save_path"]
		$Tabs / Saves / ScrollContainer / VBoxContainer / autosave_frequency_slider.value = JSON.parse_string(file_access.get_as_text())["autosave_frequency"]
	else:
		$Tabs / Graphics / ScrollContainer / VBoxContainer / window_type / window_type_selector.selected = 0
		$Tabs / Graphics / ScrollContainer / VBoxContainer / frame_rate_limit / custom_fps_limit.value = 60
		$Tabs / Graphics / ScrollContainer / VBoxContainer / particle_amount_slider.value = 0
		$Tabs / Graphics / ScrollContainer / VBoxContainer / brightness_slider.value = 0

		$Tabs / Gameplay / ScrollContainer / VBoxContainer / default_difficulty / default_difficulty_selector.selected = 0

		$Tabs / Controls / ScrollContainer / VBoxContainer / camera_move_sensitivity_slider.value = 50
		$Tabs / Controls / ScrollContainer / VBoxContainer / camera_zoom_sensitivity_slider.value = 50
		$Tabs / Controls / ScrollContainer / VBoxContainer / invert_camera_movement_toggle.set_pressed_no_signal(false)
		$Tabs / Controls / ScrollContainer / VBoxContainer / invert_zoom_camera_movement_toggle.set_pressed_no_signal(false)
		$Tabs / Controls / ScrollContainer / VBoxContainer / invert_camera_zoom_toggle.set_pressed_no_signal(false)

		$Tabs / Saves / ScrollContainer / VBoxContainer / WindowType / path_line_edit.text = ""
		$Tabs / Saves / ScrollContainer / VBoxContainer / autosave_frequency_slider.value = 0

	$Tabs / Keycodes / ScrollContainer / VBoxContainer / up / keycode_label.text = (InputMap.action_get_events("up")[0]).as_text()
	$Tabs / Keycodes / ScrollContainer / VBoxContainer / left / keycode_label.text = (InputMap.action_get_events("left")[0]).as_text()
	$Tabs / Keycodes / ScrollContainer / VBoxContainer / down / keycode_label.text = (InputMap.action_get_events("down")[0]).as_text()
	$Tabs / Keycodes / ScrollContainer / VBoxContainer / right / keycode_label.text = (InputMap.action_get_events("right")[0]).as_text()
	$Tabs / Keycodes / ScrollContainer / VBoxContainer / zoom_in / keycode_label.text = (InputMap.action_get_events("zoom_in")[0]).as_text()
	$Tabs / Keycodes / ScrollContainer / VBoxContainer / zoom_out / keycode_label.text = (InputMap.action_get_events("zoom_out")[0]).as_text()

func _on_save_button_pressed() -> void :
	update_settings()
	file_access = FileAccess.open(Global.game_location + "/options.cfg", FileAccess.WRITE_READ)
	json_settings = JSON.stringify(settings)
	file_access.store_string(json_settings)
	file_access.close()
	fade_out_tween = create_tween().set_ease(Tween.EASE_OUT)
	fade_out_tween.tween_property($ColorRect, "color", Color(0, 0, 0, 1), 1.0).from(Color(0, 0, 0, 0))
	await fade_out_tween.finished
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_cancel_button_pressed() -> void :
	file_access = FileAccess.open(Global.game_location + "/options.cfg", FileAccess.READ)
	fade_out_tween = create_tween().set_ease(Tween.EASE_OUT)
	fade_out_tween.tween_property($ColorRect, "color", Color(0, 0, 0, 1), 1.0).from(Color(0, 0, 0, 0))
	await fade_out_tween.finished
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_window_type_selector_item_selected(index: int) -> void :
	settings["window_type"] = index
func _on_custom_fps_limit_value_changed(value: float) -> void :
	settings["frame_rate_limit"] = value
func _on_particle_amount_slider_value_changed(value: float) -> void :
	settings["particle_amount"] = value
func _on_brightness_slider_value_changed(value: float) -> void :
	settings["brightness"] = value

func _on_default_difficulty_selector_item_selected(index: int) -> void :
	settings["default_difficuty"] = index

func _on_camera_move_sensitivity_slider_value_changed(value: float) -> void :
	settings["camera_movement_sensitivity"] = value
func _on_camera_zoom_sensitivity_slider_value_changed(value: float) -> void :
	settings["camera_zoom_sensitivity"] = value
func _on_invert_camera_movement_toggle_toggled(toggled_on: bool) -> void :
	settings["invert_camera_movement"] = toggled_on
func _on_invert_zoom_camera_movement_toggle_toggled(toggled_on: bool) -> void :
	settings["invert_camera_zoom_movement"] = toggled_on
func _on_invert_camera_zoom_toggle_toggled(toggled_on: bool) -> void :
	settings["invert_camera_zoom"] = toggled_on

func _on_main_volume_slider_value_changed(value: float) -> void :
	settings["main_volume"] = value
func _on_sfx_volume_slider_value_changed(value: float) -> void :
	settings["sfx_volume"] = value
func _on_music_volume_slider_value_changed(value: float) -> void :
	settings["music_volume"] = value

func _on_path_line_edit_text_changed(new_text: String) -> void :
	settings["save_path"] = new_text
func _on_autosave_frequency_slider_value_changed(value: float) -> void :
	settings["autosave_frequency"] = value


func _on_up_reset_button_pressed() -> void :
	erase_key("up")
func _on_left_reset_button_pressed() -> void :
	erase_key("left")
func _on_down_reset_button_pressed() -> void :
	erase_key("down")
func _on_right_reset_button_pressed() -> void :
	erase_key("right")
func _on_zoom_in_reset_button_pressed() -> void :
	erase_key("zoom_in")
func _on_zoom_out_reset_button_pressed() -> void :
	erase_key("zoom_out")

func _input(event: InputEvent) -> void :
	if current_action != null and event is InputEventKey and event.is_pressed():
		if not Input.is_physical_key_pressed(KEY_ESCAPE):
			get_node("Tabs/Keycodes/ScrollContainer/VBoxContainer/%s/keycode_label" % current_action).text = event.as_text()
			changed_actions[current_action] = event
		else:
			get_node("Tabs/Keycodes/ScrollContainer/VBoxContainer/%s/keycode_label" % current_action).text = previous_key.as_text()
