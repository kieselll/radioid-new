@icon("res://textures/editor_icons/wheelbarrow.svg")
class_name BuildState
extends BaseState

var _movement_component : MovementComponent
var _building_component : BuildingComponent

const state_name = &"build_state"

func _late_ready():
	assert (owner.building_component, "%s doesn\'t have a BuildingComponent assigned, which is a mandatory dependency for BuildState." % [owner.name])
	_building_component = owner.building_component
	assert (owner.movement_component, "%s doesn\'t have a MovementComponent assigned, which is a mandatory dependency for BuildState." % [owner.name])
	_movement_component = owner.movement_component

func start(args : Dictionary = {}) -> void:
	assert(args[&"target"] is Vector2i, "BuildState of %s recieved start(), but has no argument \"target\" of type Vector2i." %owner.name)
	assert(args[&"id"] is int, "BuildState of %s recieved start(), but has no argument \"id\" of type int." %owner.name)
	GlobalLogger.write_to_logs(self, "Started building")
	var _local_pos : Vector2i = _movement_component.get_local_position()
	var _diff : Vector2i = abs(_movement_component.get_local_position() - args[&"target"])
	assert(max(_diff.x, _diff.y) == 1, "%s tried to build a non-adjacent tile" % owner.name)
	_building_component.build(args[&"target"],args[&"id"])
	await _building_component.finished_building
	stop()
	done.emit()

func stop():
	GlobalLogger.write_to_logs(self, "Stopped building")
	_active = false
