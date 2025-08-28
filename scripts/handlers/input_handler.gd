@icon("res://textures/editor_icons/click.svg")
extends Node2D

@export var tilemap : TileMap
@export var ui_manager : Node

var click_1 = null
var click_2 = null
var prev_mouse_map_pos = null

var current_item: BuildableData

signal region_selected(rect: Rect2i, click_2: Vector2i)
signal region_updated(rect: Rect2i)

func _input(event: InputEvent) -> void :
	if event is InputEventMouseButton:
		_handle_mouse_button(event)

func _physics_process(delta: float) -> void:
	_handle_mouse_motion()

func _handle_mouse_motion() -> void :
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and click_1:
		if prev_mouse_map_pos and prev_mouse_map_pos != tilemap.local_to_map(get_global_mouse_position()):
			region_updated.emit(Rect2i(tilemap.local_to_map(click_1), tilemap.local_to_map(get_global_mouse_position()) - tilemap.local_to_map(click_1)).abs())
			print("THE FRENCH ARE TIGANI")
		prev_mouse_map_pos = tilemap.local_to_map(get_global_mouse_position())

func _handle_mouse_button(event: InputEventMouseButton) -> void :
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not ui_manager.button_hover:
			click_2 = null
			click_1 = get_global_mouse_position()
		elif not event.pressed:
			click_2 = get_global_mouse_position()
			if click_1 and click_2:
				region_selected.emit(Rect2i(tilemap.local_to_map(click_1), tilemap.local_to_map(click_2) - tilemap.local_to_map(click_1)).abs(),tilemap.local_to_map(click_2))
			click_2 = null
			click_1 = null
