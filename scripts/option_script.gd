extends Control

var file_access: FileAccess
var current_action: StringName
var previous_key: InputEvent
var changed_actions : Dictionary[String, InputEvent]

@export var path_text_edit : LineEdit

@export var graphics : Dictionary[String, Node] = {}
@export var gameplay : Dictionary[String, Node] = {}
@export var controls : Dictionary[String, Node] = {}
@export var audio : Dictionary[String, Node] = {}
@export var saves : Dictionary[String, Node] = {}

@export var option_buttons_map : Dictionary[OptionButton, Array]
@export var controls_map : Dictionary[TextureButton, String]
@export var control_labels : Dictionary[String, Label]

var settings_nodes: Dictionary[String, Dictionary]

func erase_key(action: StringName) -> void :
	previous_key = InputMap.action_get_events(action)[0]
	control_labels[action].text = "Listening for input"
	current_action = action
	GlobalLogger.write_to_logs(self, "Updating %s action" %action)

func update_settings() -> void :
	GlobalLogger.write_to_logs(self, "Updating the settings...")
	update_actions()
	GlobalLogger.write_to_logs(self, "Settings updated!")

func update_actions() -> void :
	for i: String in changed_actions.keys():
		InputMap.action_erase_events(i)
		InputMap.action_add_event(i, changed_actions[i])

func _ready() -> void :
	settings_nodes = {
		"graphics" = graphics,
		"gameplay" = gameplay,
		"controls" = controls,
		"audio" = audio,
		"saves" = saves,
	}

	changed_actions = {
		"up" = (InputMap.action_get_events("up")[0]),
		"left" = (InputMap.action_get_events("left")[0]),
		"down" = (InputMap.action_get_events("down")[0]),
		"right" = (InputMap.action_get_events("right")[0]),
		"zoom_in" = (InputMap.action_get_events("zoom_in")[0]),
		"zoom_out" = (InputMap.action_get_events("zoom_out")[0])
	}

	GlobalLogger.write_to_logs(self, "Current scene: Options")
	SceneTransition.finish_trans()
	var settings_dict := GlobalCfg.load_settings()
	GlobalLogger.write_to_logs(self, "Loading settings...")
	for section: String in settings_dict.keys():
		var section_dict: Dictionary[String, Node]
		for key: String in section_dict.keys():
			var node := section_dict[key]
			if node is OptionButton: (node as OptionButton).selected = settings_dict[section][key]
			if node is SpinBox: (node as SpinBox).value = settings_dict[section][key]
			if node is Slider: (node as Slider).value = settings_dict[section][key]
			@warning_ignore("unsafe_call_argument")
			if node is Button: (node as Button).set_pressed_no_signal(settings_dict[section][key])
			if node is LineEdit: (node as LineEdit).text = settings_dict[section][key]
	GlobalLogger.write_to_logs(self, "Settings loaded!")

	for category: String in settings_nodes.keys():
		var category_dict: Dictionary[String, Node] = settings_nodes[category]
		for key: String in category_dict.keys():
			var node := category_dict[key]
			if node is Slider:
				(node as Slider).value_changed.connect(_on_value_modified.bind(category, key))
			elif node is TextEdit:
				(node as TextEdit).text_changed.connect(_on_value_modified.bind(category, key))
			elif node is CheckButton:
				(node as CheckButton).toggled.connect(_on_value_modified.bind(category, key))
			elif node is OptionButton:
				(node as OptionButton).item_selected.connect(_on_option_selected.bind(category, key, option_buttons_map[(node as OptionButton)]))

	for node : TextureButton in controls_map.keys():
		node.pressed.connect(_on_reset_button_pressed.bind(controls_map[node]))

func _on_save_button_pressed() -> void :
	update_settings()
	GlobalCfg.write_dict_to_settings()
	SceneTransition.start_trans()
	await SceneTransition.done
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_value_modified(value : Variant, category : String, key : String) -> void:
	GlobalCfg.alter_setting(category, key, value)

func _on_option_selected(value : float, category : String, key : String, map : Array) -> void:
	GlobalCfg.alter_setting(category, key, map[value])

func _on_reset_button_pressed(action : String) -> void:
	erase_key(action)

func _on_path_line_edit_text_changed(new_text: String) -> void :
	if not new_text.is_absolute_path():
		path_text_edit.add_theme_color_override("font_color", Color.CRIMSON)
	else:
		path_text_edit.remove_theme_color_override("font_color")
	GlobalCfg.alter_setting("saves", "save_path", new_text)

func _input(event: InputEvent) -> void:
	if current_action != "" and event is InputEventKey and event.is_pressed():
		if not event.is_echo():
			if (event as InputEventKey).keycode != KEY_ESCAPE:
				control_labels[current_action].text = event.as_text()
				changed_actions[current_action] = event
				GlobalLogger.write_to_logs(self, "Recieved key, changed action in dictionary")
			else:
				control_labels[current_action].text = previous_key.as_text()
				changed_actions[current_action] = previous_key
				GlobalLogger.write_to_logs(self, "Recieved Esc, canceled action change.")
			current_action = ""
