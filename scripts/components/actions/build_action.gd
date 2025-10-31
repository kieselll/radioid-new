@icon("res://textures/editor_icons/hand-truck.svg")
class_name BuildAction
extends BaseAction

var _movement_component : MovementComponent
var _move_state : MoveState
var _build_state : BuildState
@onready var _grid_utils = get_node(GlobalRef.get_handler(GlobalRef.handlers_enum.grid_utils))

const action_name = &"build_action"

func start(args : Dictionary = {&"partial" : true}) -> void:
	assert(_state_machine.get_state(&"move_state"),"%s doesn't have the mandatory MoveState" %owner.name)
	assert(_state_machine.get_state(&"build_state"),"%s doesn't have the mandatory BuildState" %owner.name)
	GlobalLogger.write_to_logs(self, "Started building...")
	_active = true
	_movement_component = owner.movement_component
	_move_state = _state_machine.get_state(&"move_state")
	_build_state = _state_machine.get_state(&"build_state")
	var _neighbor_tiles = _grid_utils.get_neighbor_tiles(args[&"target"], true)
	_state_machine.change_state(&"move_state",args.merged({&"target" : Vector2i(_grid_utils.find_nearest_tile_coord(_movement_component.get_local_position(), _neighbor_tiles))}, true))
	await _move_state.done
	_state_machine.change_state(&"build_state",args)
	await _build_state.done
	done.emit()
	
func stop() -> void:
	if _move_state.is_active(): _move_state.stop()
	elif _build_state.is_active(): _build_state.stop()
	_active = false
