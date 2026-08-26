@icon("res://textures/editor_icons/stack.svg")
extends Node2D
class_name UIManager

@export var buttons: Array[BaseButton]
@export var lists: Array[ItemList]
@export var rects: Array[Control]
var list_id_map: Dictionary = {
	&"wall_selection_list": [1, 2, 3, -1],
	&"floor_selection_list": [5, -2],
	&"furniture_selection_list": [7, 0, 0, 0, 0, 0, 0, 0, 0, 0],
}

var button_hover: bool = false

signal building_selected(id: int)


func _ready() -> void:
	for button in buttons:
		button.toggled.connect(_on_listen_button_toggled.bind(button))
	for list in lists:
		list.item_selected.connect(_on_list_item_selected.bind(StringName(list.name)))
	for rect in rects:
		rect.mouse_entered.connect(_on_ui_entered_exited.bind(true))
		rect.mouse_exited.connect(_on_ui_entered_exited.bind(false))


func _on_listen_button_toggled(toggled_on: bool, button: BaseButton) -> void:
	if button.get_meta_list().has(&"linked_list"):
		var linked_path: NodePath = button.get_meta(&"linked_list")
		var linked_control := button.get_node(linked_path) as Control
		linked_control.set_visible(toggled_on)
		GlobalLogger.write_to_logs(
			button,
			"Toggled visibility of %s" % linked_control.name
		)


func _on_list_item_selected(item_id: int, list_name: StringName) -> void:
	building_selected.emit(list_id_map[list_name][item_id])


func _on_ui_entered_exited(entered: bool) -> void:
	if entered:
		button_hover = true
	else:
		button_hover = false
