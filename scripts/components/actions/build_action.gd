@icon("res://textures/editor_icons/hand-truck.svg")
class_name BuildAction
extends BaseAction

## Action that moves a pawn adjacent to a queued build tile and constructs it.
##
## The action is intentionally split into resumable steps so it can later be
## serialized and restarted from an intermediate state.

#region vars

var _movement_component: MovementComponent
var _state_machine: StateMachine
var _move_state: MoveState
var _build_state: BuildState
var _pathfinder: GlobalPathfinder
var current_step: steps = steps.move
var current_args: Dictionary
var _parent
var owner

#endregion

#region constants

## Action-machine identifier for this action implementation.
const action_type = ActionMachine.action_types.build

## Resumable phases of the build action.
enum steps {
	move, build
}

#endregion

#region init

## Caches the owning action machine and state machine.
func setup(action_machine : ActionMachine):
	_parent = action_machine
	owner = _parent.owner
	_state_machine = owner.state_machine

#endregion

#region lifecycle

## Starts the build action from the currently stored [code]current_step[/code].
func start(args: Dictionary = {}) -> void:
	current_args = args
	initialize()
	if current_step == steps.move:
		await move_step(args.merged({"partial": true}, true))
	if current_step == steps.build:
		await build_step(args)
	current_step = steps.move
	done.emit()

## Starts the build action from an explicit [code]steps[/code] value.
func start_from_step(args: Dictionary = {"partial": true}, step : steps = steps.move):
	current_step = step
	start(args)

## Validates required states and refreshes component references.
func initialize() -> void:
	assert(
		_state_machine.get_state(StateMachine.state_types.move_state),
		"%s doesn't have the mandatory MoveState" % owner.name
	)
	assert(
		_state_machine.get_state(StateMachine.state_types.build_state),
		"%s doesn't have the mandatory BuildState" % owner.name
	)
	GlobalLogger.write_to_logs(owner, "Started building...")

	_active = true
	_movement_component = owner.movement_component
	_move_state = _state_machine.get_state(StateMachine.state_types.move_state)
	_build_state = _state_machine.get_state(StateMachine.state_types.build_state)
	_pathfinder = owner.get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.pathfinder))

#region Step functions

## Moves the pawn to the nearest adjacent tile around the build target.
func move_step(args: Dictionary) -> void:
	var neighbor_tiles := GridUtils.get_neighbor_tiles(args["target"], true)
	var walkable_neighbors := neighbor_tiles.filter(
		func(tile: Vector4i) -> bool: return not _pathfinder.is_tile_solid(tile)
	)
	if walkable_neighbors.is_empty():
		push_warning("No walkable approach tile for build target %s" % args["target"])
		return

	var nearest_coord = GridUtils.find_nearest_tile_coord(
		_movement_component.get_local_position(), walkable_neighbors
	)
	if _movement_component.get_local_position() != nearest_coord:
		_state_machine.change_state(StateMachine.state_types.move_state, args.merged({"target": nearest_coord}, true))
		print("moving to ", nearest_coord)
		await _move_state.done
	current_step = steps.build

## Runs the build state once the pawn is in position.
func build_step(args: Dictionary) -> void:
	_state_machine.change_state(StateMachine.state_types.build_state, args)
	await _build_state.done

#endregion

## Stops whichever build-related state is currently active.
func stop() -> void:
	if _move_state.is_active():
		_move_state.stop()
	elif _build_state.is_active():
		_build_state.stop()
	_active = false

#endregion
