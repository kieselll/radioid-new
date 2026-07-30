@icon("res://textures/editor_icons/wheelbarrow.svg")
class_name BuildState
extends BaseState

var _movement_component: MovementComponent
var _building_component: BuildingComponent
var _parent: StateMachine
var owner: BaseEntity

const state_name: StringName = &"build_state"

func setup(state_machine: StateMachine) -> void:
	_parent = state_machine
	owner = _parent.owner
	_movement_component = owner.movement_component
	_building_component = owner.building_component

func start(args: Dictionary = {}) -> void:
	print(typeof(args["target"]))
	var target: Variant = args.get("target")
	assert(
		target is Vector4i,
		(
			'BuildState of %s recieved start(), but has no argument "target" of type Vector4i.'
			% owner.name
		)
	)
	var build_target: Vector4i = target

	var id_value: int = args.get("id")
	GlobalLogger.write_to_logs(owner, "Started building")
	var _neighbor_tiles: Array[Vector4i] = GridUtils.get_neighbor_tiles(build_target, true)
	assert(
		_neighbor_tiles.has(_movement_component.get_local_position()),
		"%s tried to build a non-adjacent tile" % owner.name
	)
	_building_component.build(build_target, id_value)
	await _building_component.finished_building
	stop()
	done.emit()


func stop() -> void:
	GlobalLogger.write_to_logs(owner, "Stopped building")
	_active = false
