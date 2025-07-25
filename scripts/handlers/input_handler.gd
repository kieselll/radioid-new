@icon("res://textures/editor_icons/click.svg")
extends Node2D

@export var tilemap : TileMap

var click_1 = null
var click_2 = null

var current_item: BuildableData

signal region_selected(rect: Rect2i)
signal region_updated(rect: Rect2i)

func _input(event: InputEvent) -> void :
	if event is InputEventMouseMotion:
		_handle_mouse_motion()
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)

func _handle_mouse_motion() -> void :
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		region_updated.emit(Rect2i(tilemap.local_to_map(click_1), tilemap.local_to_map(get_global_mouse_position()) - tilemap.local_to_map(click_1)).abs())

func _handle_mouse_button(event: InputEventMouseButton) -> void :
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			click_2 = null
			click_1 = get_global_mouse_position()
		else:
			click_2 = get_global_mouse_position()
			region_selected.emit(Rect2i(tilemap.local_to_map(click_1), tilemap.local_to_map(click_2) - tilemap.local_to_map(click_1)).abs())
