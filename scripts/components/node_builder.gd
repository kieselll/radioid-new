@icon("res://textures/editor_icons/stake-hammer.svg")
@warning_ignore_start("unused_parameter")
class_name BuildingComponent
extends Node

signal finished_building


func build(coords: Vector4i, id: int, time: float = 5):
	var _data = BuildableDB.get_tile(id)
	if not _data:
		GlobalLogger.write_to_logs(self, "[ERROR]: Could not build tile with id: %d!" % id)
		GlobalLogger.open_log_file()
		get_tree().quit()
	var progressbar: ProgressBar = (
		GlobalRef.get_scene(GlobalRef.scenes_enum.progressbar).instantiate()
	)
	progressbar.z_index = 20
	progressbar.size = Vector2(100, 10)
	progressbar.position = (
		GridUtils.chunk_coord_to_tile_coord(coords)
		- Vector2i(12, 26)
	)
	get_node(GlobalRef.get_tilemap_layer_path(_data.layer)).add_child(progressbar)
	var progressbar_tween = create_tween()
	progressbar_tween.tween_property(progressbar, "value", 100, time)
	await progressbar_tween.finished
	get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.building_agent)).fill_array(
		[coords], _data, false
	)
	get_node(GlobalRef.get_tilemap_layer_path(_data.queued_layer)).erase_cell(coords)
	progressbar.queue_free()
	finished_building.emit()
