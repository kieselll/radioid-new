extends Node2D

@export var buttons_to_listen: Array[BaseButton]
@export var lists_to_listen: Array[ItemList]

var click_1 = null
var click_2 = null
var build_button: bool
var item_map: = {
	"wall_selection_list" = {
		"1" = 1, 
		"2" = 2, 
		"3" = 3
	}, 
	"floor_selection_list" = {

	}, 
	"furniture_selection_list" = {

	}, 
	"workbench_selection_list" = {

	}, 
	"power_selection_list" = {

	}, 
	"plants_selection_list" = {

	}
}
var current_item: BuildableData

signal building_menu_toggled(toggled_on: bool)
signal selection_button_toggled(toggled_on: bool, button_name: String)
signal building_menu_buildable_selected(item_id: int, list_name: String)
signal building_tile_selected(id: int)
signal region_selected(rect: Rect2i)
signal region_updated(rect: Rect2i)

func _ready() -> void :
	for i in buttons_to_listen:
		i.toggled.connect(_listen_button_toggled.bind(i.name))
	for i in lists_to_listen:
		i.item_selected.connect(_listen_list_item_selected.bind(i.name))

func _input(event: InputEvent) -> void :
	if event is InputEventMouseMotion:
		_handle_mouse_motion()
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)

func _handle_mouse_motion() -> void :
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		region_updated.emit(Rect2i(click_1, get_global_mouse_position() - click_1).abs())

func _handle_mouse_button(event: InputEventMouseButton) -> void :
	if event.pressed:
		click_2 = null
		click_1 = event.position
	else:
		click_2 = event.position
		if Rect2(click_2 - Vector2(5, 5), Vector2(10, 10)).has_point(click_1):
			region_selected.emit(Rect2i(click_1, click_2 - click_1).abs())

func _listen_button_toggled(toggled_on: bool, button_name: String):
	selection_button_toggled.emit(toggled_on, button_name)

func _listen_list_item_selected(item_id: int, list_name: String):
	current_item = %BuildableDB.tiles[item_map[list_name][str(item_id)]]
