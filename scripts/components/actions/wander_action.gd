@warning_ignore_start("unused_parameter")
@icon("res://textures/editor_icons/misdirection.svg")
class_name WanderAction
extends BaseAction

## Default idle action that sends a pawn to a random nearby tile.
##
## Wander acts as the fallback behavior in the queue and intentionally supports
## the same step-based API as more complex actions so deserialization code can
## stay uniform.

#region constants

## Action-machine identifier for this action implementation.
## Resumable phases of the wander action.
enum steps {
	wander
}

#endregion

#region vars

var _movement_component: MovementComponent
var _state_machine: StateMachine
var _move_state: BaseState
var _pathfinder: GlobalPathfinder
var _random_pos: Vector4i = Vector4i.ZERO
var _parent: ActionMachine
var owner: BaseEntity

#endregion

#region init

## Caches the owning action machine and movement state references.
func setup(action_machine : ActionMachine) -> void:
	_parent = action_machine
	owner = _parent.owner
	_movement_component = owner.movement_component
	_state_machine = _parent.state_machine
	_move_state = _state_machine.get_state(StateMachine.state_types.move_state)
	_pathfinder = owner.get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.pathfinder))
	action_type = ActionMachine.action_types.wander
	current_step = steps.wander

#endregion

#region lifecycle

## Starts a new wander run.
func start(args: Dictionary = {}) -> void:
	current_args = args
	assert(
		_state_machine.get_state(StateMachine.state_types.move_state),
		"%s doesn't have the mandatory MoveState" % owner.name
	)
	GlobalLogger.write_to_logs(owner, "Started wandering around...")
	_active = true
	new_pos()

## Starts the action from an explicit [code]steps[/code] value.
##
## This wrapper is intentionally redundant so all actions expose the same
## deserialization-friendly API.
func start_from_step(args: Dictionary = {"partial": true}, step: int = steps.wander) -> void:
	current_step = step
	start(args)

#endregion

#region helpers

## Picks a random reachable offset, moves there, then emits completion after a delay.
func new_pos() -> void:
	if not _active:
		return
	if not _random_pos:
		var radius: int = owner.behavior_data.wander_radius if owner.behavior_data else 5
		var current_position := _movement_component.get_local_position()
		var found_candidate := false
		for _attempt in 16:
			var offset := Vector2i(randi_range(-radius, radius), randi_range(-radius, radius))
			var candidate := GridUtils.tile_coord_to_chunk_coord(
				GridUtils.chunk_coord_to_tile_coord(current_position) + offset
			)
			if candidate != current_position and not _pathfinder.is_tile_solid(candidate):
				_random_pos = candidate
				found_candidate = true
				break

		if not found_candidate:
			# Chunks and their A* grids may still be initializing. Do not emit [signal done]
			# here: DecisionMaker immediately starts the fallback wander action again,
			# creating an unbounded same-frame call chain. Yield, then retry instead.
			await owner.get_tree().process_frame
			if _active:
				new_pos()
			return

		_state_machine.change_state(StateMachine.state_types.move_state, {"target": _random_pos, "partial": true})
	await _move_state.done
	if not _active:
		return
	_random_pos = Vector4i.ZERO
	var delay_min: float = owner.behavior_data.wander_delay_min if owner.behavior_data else 0.3
	var delay_max: float = owner.behavior_data.wander_delay_max if owner.behavior_data else 1.5
	await owner.get_tree().create_timer(randf_range(delay_min, delay_max)).timeout
	if _active:
		done.emit()

#endregion

#region lifecycle

## Cancels the current wander run and stops movement immediately.
func stop() -> void:
	GlobalLogger.write_to_logs(owner, "Stopped wandering around")
	_active = false
	_random_pos = Vector4i.ZERO
	_movement_component.stop_moving()

#endregion
