extends Resource
class_name EntityTemplate

@export var id: StringName = &"entity"
@export var type: EntityManager.types = EntityManager.types.pawn
@export var scene: PackedScene

@export var entity_data: EntityData
@export var personality_profile: PersonalityProfile
@export var behavior_data: BehaviorData

@export var uses_movement_component: bool = true
@export var uses_building_component: bool = false
@export var uses_ability_manager: bool = false

@export var actions: Array[ActionMachine.action_types] = []
@export var states: Array[StateMachine.state_types] = []
