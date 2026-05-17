@icon("res://textures/editor_icons/cog.svg")
class_name StateMachine
extends Node

#region enums

enum state_types
{
	null_state,
	idle_state,
	move_state,
	build_state,
}

#endregion

#region private vars

var _states = []
var _current_state: BaseState

#endregion

#region public vars

func _ready() -> void:
	assert(
		owner is CharacterBody2D,
		"A StateMachine cannot be owned by a non-CharacterBody2D. Please change the root of this scene to a CharacterBody2D."
	)

	for child in get_children():
		assert(
			child is BaseState,
			"%s, child of the state_machine of %s isn't a state" % [child.name, owner.name]
		)
		_state_nodes[child.state_name] = child
#endregion

	)
#region signals

signal state_changed(state_type: state_types)
signal state_done()

#endregion

#region lifecycle


#endregion

#region init
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

#endregion

#region helpers

func _on_any_state_done() -> void:
	state_done.emit()

#endregion
