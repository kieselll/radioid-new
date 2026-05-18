extends Resource
class_name EntityTemplate

@export var can_move : bool
@export var can_build : bool
# Populate later

func encode() -> Array[Array]:
	var actions : Array[bool]
	var states : Array[bool]
	var components : Array
	if can_move:
		actions[ActionMachine.action_types.wander] = true
		states[StateMachine.state_types.move_state] = true
		components.append(MovementComponent)
	if can_build:
		actions[ActionMachine.action_types.build] = true
		states[StateMachine.state_types.build_state] = true
		components.append(BuildingComponent)


	return [actions,states,components]
