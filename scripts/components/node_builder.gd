@icon("res://textures/editor_icons/stake-hammer.svg")
@warning_ignore_start("unused_parameter")
class_name BuildingComponent
extends Node

func build(coords : Vector2i, id : int):
	var _data = %BuildableDB.get_tile(id)
	assert(_data, "Couldn't build tile with ID %s. (Invalid ID)" %id)
	

func _build_object():
	pass

func _build_terrain():
	pass
