extends Control

var file_access: FileAccess
var current_action
var previous_key
var changed_actions = {
	"up" = (InputMap.action_get_events("up")[0]), 
	"left" = (InputMap.action_get_events("left")[0]), 
	"down" = (InputMap.action_get_events("down")[0]), 
	"right" = (InputMap.action_get_events("right")[0]), 
	"zoom_in" = (InputMap.action_get_events("zoom_in")[0]), 
	"zoom_out" = (InputMap.action_get_events("zoom_out")[0])
}

@onready var settings_nodes = {
	"graphics" = {
		"window_type" = $Tabs/Graphics/ScrollContainer/VBoxContainer/window_type/window_type_selector, 
		"frame_rate_limit" = $Tabs/Graphics/ScrollContainer/VBoxContainer/frame_rate_limit/custom_fps_limit, 
		"particle_amount" = $Tabs/Graphics/ScrollContainer/VBoxContainer/particle_amount_slider,
		"brightness" = $Tabs/Graphics/ScrollContainer/VBoxContainer/brightness_slider
	},
	
	"gameplay" = {
		"default_difficuty" = $Tabs/Gameplay/ScrollContainer/VBoxContainer/default_difficulty/default_difficulty_selector
	},
	
	"controls" = {
		"camera_movement_sensitivity" = $Tabs/Controls/ScrollContainer/VBoxContainer/camera_move_sensitivity_slider,
		"camera_zoom_sensitivity" = $Tabs/Controls/ScrollContainer/VBoxContainer/camera_zoom_sensitivity_slider, 
		"invert_camera_movement" = $Tabs/Controls/ScrollContainer/VBoxContainer/invert_camera_movement_toggle, 
		"invert_camera_zoom_movement" = $Tabs/Controls/ScrollContainer/VBoxContainer/invert_zoom_camera_movement_toggle, 
		"invert_camera_zoom" = $Tabs/Controls/ScrollContainer/VBoxContainer/invert_camera_zoom_toggle
	},
	
	"audio" = {
		"main_volume" = $Tabs/Audio/ScrollContainer/VBoxContainer/main_volume_slider, 
		"sfx_volume" = $Tabs/Audio/ScrollContainer/VBoxContainer/sfx_volume_slider,
		"music_volume" = $Tabs/Audio/ScrollContainer/VBoxContainer/music_volume_slider, 
	},
	
	"saves" = {
		"game_path" = $Tabs/Saves/ScrollContainer/VBoxContainer/WindowType/path_line_edit, 
		"autosave_frequency" = $Tabs/Saves/ScrollContainer/VBoxContainer/autosave_frequency_slider, 
	}
}

func erase_key(action: StringName) -> void :
	previous_key = InputMap.action_get_events(action)[0]
	get_node("Tabs/Keycodes/ScrollContainer/VBoxContainer/%s/keycode_label" % action).text = "Listening for input"
	current_action = action

func update_settings() -> void :
	update_actions()
	if GlobalCfg.get_setting("graphics", "frame_rate_limit"):
		Engine.max_fps = GlobalCfg.get_setting("graphics", "frame_rate_limit")
	match GlobalCfg.get_setting("graphics", "window_type", 0):
		0:
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
		1:
			get_window().mode = Window.MODE_WINDOWED

func update_actions() -> void :
	for i in changed_actions.keys():
		InputMap.action_erase_events(i)
		InputMap.action_add_event(i, changed_actions[i])

func _ready() -> void :
	var settings_dict = GlobalCfg.load_settings()
	for section in settings_dict.keys():
		for key in settings_dict[section].keys():
			var node = settings_nodes[section][key]
			if node is OptionButton: node.select(settings_dict[section][key])
			if node is SpinBox or node is Slider: node.value = settings_dict[section][key]
			if node is Button: node.set_pressed_no_signal(settings_dict[section][key])
			if node is LineEdit: node.text = settings_dict[section][key]

func _on_save_button_pressed() -> void :
	update_settings()
	GlobalCfg.write_dict_to_settings()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_window_type_selector_item_selected(index: int) -> void :
	GlobalCfg.alter_setting("graphics", "window_type", index)
func _on_custom_fps_limit_value_changed(value: float) -> void :
	GlobalCfg.alter_setting("graphics", "frame_rate_limit", value)
func _on_particle_amount_slider_value_changed(value: float) -> void :
	GlobalCfg.alter_setting("graphics", "particle_amount", value)
func _on_brightness_slider_value_changed(value: float) -> void :
	GlobalCfg.alter_setting("graphics", "brightness", value)

func _on_default_difficulty_selector_item_selected(index: int) -> void :
	GlobalCfg.alter_setting("gameplay", "default_difficuty", index)

func _on_camera_move_sensitivity_slider_value_changed(value: float) -> void :
	GlobalCfg.alter_setting("controls", "camera_movement_sensitivity", value)
func _on_camera_zoom_sensitivity_slider_value_changed(value: float) -> void :
	GlobalCfg.alter_setting("controls", "camera_zoom_sensitivity", value)
func _on_invert_camera_movement_toggle_toggled(toggled_on: bool) -> void :
	GlobalCfg.alter_setting("controls", "invert_camera_movement", toggled_on)
func _on_invert_zoom_camera_movement_toggle_toggled(toggled_on: bool) -> void :
	GlobalCfg.alter_setting("controls", "invert_camera_zoom_movement", toggled_on)
func _on_invert_camera_zoom_toggle_toggled(toggled_on: bool) -> void :
	GlobalCfg.alter_setting("controls", "invert_camera_zoom", toggled_on)

func _on_main_volume_slider_value_changed(value: float) -> void :
	GlobalCfg.alter_setting("audio", "main_volume", value)
func _on_sfx_volume_slider_value_changed(value: float) -> void :
	GlobalCfg.alter_setting("audio", "sfx_volume", value)
func _on_music_volume_slider_value_changed(value: float) -> void :
	GlobalCfg.alter_setting("audio", "music_volume", value)

func _on_path_line_edit_text_changed(new_text: String) -> void :
	if not new_text.is_absolute_path():
		$Tabs/Saves/ScrollContainer/VBoxContainer/WindowType/path_line_edit.add_theme_color_override("font_color", Color.CRIMSON)
	else:
		$Tabs/Saves/ScrollContainer/VBoxContainer/WindowType/path_line_edit.remove_theme_color_override("font_color")
	GlobalCfg.alter_setting("saves", "save_path", new_text)
func _on_autosave_frequency_slider_value_changed(value: float) -> void :
	GlobalCfg.alter_setting("saves", "autosave_frequency", value)


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

func _input(event: InputEvent) -> void:
	if current_action != null and event is InputEventKey and event.is_pressed():
		if not event.is_echo():
			if event.keycode != KEY_ESCAPE:
				get_node("Tabs/Keycodes/ScrollContainer/VBoxContainer/%s/keycode_label" % current_action).text = event.as_text()
				changed_actions[current_action] = event
			else:
				get_node("Tabs/Keycodes/ScrollContainer/VBoxContainer/%s/keycode_label" % current_action).text = previous_key.as_text()
				changed_actions[current_action] = previous_key
			current_action = null
