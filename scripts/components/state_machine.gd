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

var _states: Array[BaseState] = []
var _current_state: BaseState
var _parent: BaseEntity

#endregion

#region public vars

var owner: BaseEntity

#endregion

#region signals

signal state_changed(state_type: state_types)
signal state_done()

#endregion

#region lifecycle

func tick(_delta: float) -> void:
	pass

#endregion

#region init

func setup(parent: BaseEntity) -> void:
	_parent = parent
	owner = _parent
	_states.resize(state_types.size())

#endregion

#region API

func change_state(state_type : state_types, args: Dictionary = {}) -> void:
	assert(
		state_type < _states.size() and _states[state_type] != null,
		(
			"StateMachine of %s tried to switch to %s, but it isn't present."
			% [owner.name, state_types.find_key(state_type)]
		)
	)

	if not _current_state:
		return

	_current_state.stop()
	_current_state = _states[state_type]
	_current_state.start(args)
	state_changed.emit(state_type)

func get_current_state_name() -> StringName:
	@warning_ignore("unsafe_property_access")
	return _current_state.state_name if _current_state else &"no_state"

func get_state(state_type: state_types) -> BaseState:
	if state_type >= _states.size():
		return null
	return _states[state_type]

func add_state(state_type : state_types) -> void:
	if _states.is_empty():
		_states.resize(state_types.size())
	var state: BaseState = _create_state(state_type)
	state.setup(self)
	_states[state_type] = state
	state.done.connect(_on_any_state_done)

func erase_state(state_type : state_types) -> void:
	_states[state_type] = null


func set_initial_state(state_type: state_types) -> void:
	assert(
		state_type < _states.size() and _states[state_type] != null,
		(
			"StateMachine of %s cannot set initial state %s because it isn't present."
			% [owner.name, state_types.find_key(state_type)]
		)
	)
	_current_state = _states[state_type]
	_current_state.start()

#endregion

#region helpers

func _on_any_state_done() -> void:
	state_done.emit()

func _create_state(state_type: state_types) -> BaseState:
	match state_type:
		state_types.idle_state:
			return IdleState.new()
		state_types.move_state:
			return MoveState.new()
		state_types.build_state:
			return BuildState.new()
	assert(false, "Unsupported state type: %s" % state_type)
	return null

#endregion
