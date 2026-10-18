@icon("res://shared/editor_icons/stack.svg")
extends Node2D
class_name UIManager

@export var buttons: Array[BaseButton]
@export var lists: Array[ItemList]
@export var rects: Array[Control]
var list_by_name: Dictionary[StringName, ItemList] = {}

var button_hover: bool = false

signal building_selected(id: int)


func _ready() -> void:
	for button in buttons:
		button.toggled.connect(_on_listen_button_toggled.bind(button))
	for list in lists:
		list_by_name[list.name] = list
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


func _on_list_item_selected(item_index: int, list_name: StringName) -> void:
	var list := list_by_name[list_name]
	var buildable_id: Variant = list.get_item_metadata(item_index)
	if buildable_id is not int:
		push_warning("Selected build menu item has no buildable ID: %s" % list_name)
		return
	building_selected.emit(buildable_id)


func _on_ui_entered_exited(entered: bool) -> void:
	if entered:
		button_hover = true
	else:
		button_hover = false
