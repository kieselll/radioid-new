@icon("res://textures/editor_icons/stake-hammer.svg")
@warning_ignore_start("unused_parameter")
class_name BuildingComponent
extends Node

signal finished_building

func build(coords : Vector2i, id : int, time : float = 5):
	var _data = BuildableDB.get_tile(id)
	assert(_data, "Couldn't build tile with ID %s. (Invalid ID)" %id)
	var progressbar : ProgressBar = GlobalRef.get_scene_path(GlobalRef.scenes_enum.progressbar).instantiate()
	progressbar.z_index = 20
	progressbar.size = Vector2(100, 10)
	progressbar.position = get_node(GlobalRef.get_game_node_path(GlobalRef.game_nodes_enum.tilemap)).map_to_local(coords) - Vector2(12, 26)
	get_node(GlobalRef.get_tilemap_layer_path(_data.layer)).add_child(progressbar)
	var progressbar_tween = create_tween()
	progressbar_tween.tween_property(progressbar, "value", 100, time)
	await progressbar_tween.finished
	get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.building_agent)).fill_array([coords], _data, false)
	get_node(GlobalRef.get_tilemap_layer_path(_data.queued_layer)).erase_cell(coords)
	progressbar.queue_free()
	finished_building.emit()
