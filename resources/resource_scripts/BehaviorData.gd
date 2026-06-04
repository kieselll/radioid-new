class_name BehaviorData
extends Resource

@export var default_action: ActionMachine.action_types = ActionMachine.action_types.wander
@export var auto_wander: bool = true
@export var takes_jobs: bool = true

@export_range(0, 64, 1) var wander_radius: int = 5
@export_range(0.0, 10.0, 0.1) var wander_delay_min: float = 0.3
@export_range(0.0, 10.0, 0.1) var wander_delay_max: float = 1.5

@export_range(0.0, 10.0, 0.1) var base_priority_weight: float = 1.0
@export_range(0.0, 10.0, 0.1) var skill_weight: float = 1.0
@export_range(0.0, 10.0, 0.1) var negative_skill_weight: float = 1.0
@export_range(0.0, 10.0, 0.1) var distance_weight: float = 1.0
