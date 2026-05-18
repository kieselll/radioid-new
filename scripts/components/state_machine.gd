@icon("res://textures/editor_icons/cog.svg")
class_name StateMachine
extends BaseComponent

#region enums

enum state_types
{
	idle_state,
	move_state,
	build_state,
}

#endregion

#region private vars

var _states = []
var _current_state: BaseState
var _parent
var _type_map : Dictionary = {
	state_types.idle_state : IdleState,
	state_types.move_state : MoveState,
	state_types.build_state : BuildState,
}

#endregion

#region public vars

var owner : CharacterBody2D

#endregion

#region signals

signal state_changed(state_type: state_types)
signal state_done()

#endregion

#region lifecycle

@warning_ignore("unused_parameter")
func tick(delta : float) -> void:
	pass

#endregion

#region init

func setup(parent : CharacterBody2D) -> void:
	_parent = parent
	owner = _parent

	for state in _states:
		state.done.connect(_on_any_state_done)
	_current_state = _states[state_types.idle_state]

#endregion

#region API

func change_state(state_type : state_types, args: Dictionary = {}) -> void:
	assert(
		state_type <= _states.size() and _states[state_type] != null,
		"StateMachine of %s tried to switch to %s, but it isn't present." % [owner.name, state_types.find_key(state_type)]
	)

	if not _current_state:
		return

	_current_state.stop()
	_current_state = _states[state_type]
	_current_state.start(args)
	state_changed.emit(state_type)


func get_current_state_name() -> StringName:
	return _current_state.state_name if _current_state else &"no_state"

func get_state(state_type: state_types):
	return _states[state_type]

func add_state(state_type : state_types) -> void:
	var state = _type_map[state_type].new()
	state.setup(self)
	_states[state_type] = state

func erase_state(state_type : state_types) -> void:
	_states[state_type] = null

#endregion

#region helpers

func _on_any_state_done() -> void:
	state_done.emit()

#endregion
