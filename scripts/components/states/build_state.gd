@icon("res://textures/editor_icons/wheelbarrow.svg")
class_name BuildState
extends BaseState

var _movement_component: MovementComponent
var _building_component: BuildingComponent
var _parent : StateMachine
var owner : CharacterBody2D

const state_name = &"build_state"

func setup(state_machine : StateMachine):
	_parent = state_machine
	owner = _parent.owner
	_movement_component = owner.movement_component
	_building_component = owner.building_component

func start(args: Dictionary = {}) -> void:
	assert(
		args["target"] is Vector4i,
		(
			'BuildState of %s recieved start(), but has no argument "target" of type Vector4i.'
			% owner.name
		)
	)

	assert(
		args["id"] is int or args["id"] is float,
		'BuildState of %s recieved start(), but has no argument "id" of type int.' % owner.name
	)
	GlobalLogger.write_to_logs(owner, "Started building")
	var _neighbor_tiles := GridUtils.get_neighbor_tiles(args["target"], true)
	assert(
		_neighbor_tiles.has(_movement_component.get_local_position()),
		"%s tried to build a non-adjacent tile" % owner.name
	)
	_building_component.build(args["target"], int(args["id"]))
	await _building_component.finished_building
	stop()
	done.emit()


func stop():
	GlobalLogger.write_to_logs(owner, "Stopped building")
	_active = false
