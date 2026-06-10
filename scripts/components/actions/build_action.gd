@icon("res://textures/editor_icons/hand-truck.svg")
class_name BuildAction
extends BaseAction

#region vars

var _movement_component: MovementComponent
var _state_machine: StateMachine
var _move_state: MoveState
var _build_state: BuildState
var current_step : steps
var _parent
var owner

#endregion

#region constants

const action_type = ActionMachine.action_types.build

enum steps {
	move, build
}

#endregion

#region init

func setup(action_machine : ActionMachine):
	_parent = action_machine
	owner = _parent.owner
	_state_machine = owner.state_machine

#endregion

#region lifecycle

func start(args: Dictionary = {&"partial": true}, step : steps = steps.move) -> void:
	initialize(step)
	if current_step == steps.move:
		await move_step(args)
	if current_step == steps.build:
		await build_step(args)
	done.emit()

func initialize(step : steps = steps.move) -> void:
	assert(
		_state_machine.get_state(StateMachine.state_types.move_state),
		"%s doesn't have the mandatory MoveState" % owner.name
	)
	assert(
		_state_machine.get_state(StateMachine.state_types.build_state),
		"%s doesn't have the mandatory BuildState" % owner.name
	)
	GlobalLogger.write_to_logs(owner, "Started building...")

	current_step = step
	_active = true
	_movement_component = owner.movement_component
	_move_state = _state_machine.get_state(StateMachine.state_types.move_state)
	_build_state = _state_machine.get_state(StateMachine.state_types.build_state)

#region Step functions

func move_step(args: Dictionary) -> void:
	var _neighbor_tiles = GridUtils.get_neighbor_tiles(args[&"target"], true)
	_state_machine.change_state(
		StateMachine.state_types.move_state,
		args.merged(
			{
				&"target":
				GridUtils.find_nearest_tile_coord(
					_movement_component.get_local_position(), _neighbor_tiles
				)
			},
			true
		)
	)
	await _move_state.done
	current_step = steps.build

func build_step(args: Dictionary) -> void:
	_state_machine.change_state(StateMachine.state_types.build_state, args)
	await _build_state.done

#endregion

func stop() -> void:
	if _move_state.is_active():
		_move_state.stop()
	elif _build_state.is_active():
		_build_state.stop()
	_active = false

#endregion
