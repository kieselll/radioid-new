@warning_ignore_start("unused_parameter")
class_name BuildingComponent
extends BaseComponent

signal finished_building

var _parent: CharacterBody2D

func tick(delta: float):
	pass

func setup(parent : CharacterBody2D) -> void:
	tick_type = none #Better to specify, but it's none by default
	_parent = parent

func build(coords: Vector4i, id: int, time: float = 5):
	var _data := BuildableDB.get_tile(id)
	if not _data:
		GlobalLogger.write_to_logs(_parent, "[ERROR]: Could not build tile with id: %d!" % id)
		GlobalLogger.open_log_file()
		_parent.get_tree().quit()
	var progressbar: ProgressBar = (
		GlobalRef.get_scene(GlobalRef.scenes_enum.progressbar).instantiate()
	)
	progressbar.z_index = 20
	progressbar.size = Vector2(100, 10)
	progressbar.position = (GridUtils.chunk_coord_to_world_coord(coords))
	_parent.get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.building_agent)).add_child(progressbar)
	var progressbar_tween = _parent.create_tween()
	progressbar_tween.tween_property(progressbar, "value", 100, time)
	await progressbar_tween.finished
	_parent.get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.building_agent)).fill_array(
		[coords], _data, false
	)
	_parent.get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.building_agent)).erase_tiles([coords], _data.queued_layer)
	progressbar.queue_free()
	finished_building.emit()
