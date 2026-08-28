extends Resource
class_name EntityTemplate

## Template resource describing how to instantiate a gameplay entity.
##
## An [EntityTemplate] bundles scene, data resources, and component toggles so
## [EntityManager] can spawn a pawn or other entity type without hardcoding its
## setup logic.

## Stable template identifier used for naming and serialization.
@export var id: StringName = &"entity"
## Entity-manager enum value that this template spawns as.
@export var type: EntityManager.types = EntityManager.types.pawn
## Scene instantiated for the entity.
@export var scene: PackedScene

## Core stats copied into the spawned entity.
@export var entity_data: EntityData
## Personality profile copied into the spawned entity.
@export var personality_profile: PersonalityProfile
## Behavior settings copied into the spawned entity.
@export var behavior_data: BehaviorData

## If [code]true[/code], [EntityManager] adds a [MovementComponent].
@export var uses_movement_component: bool = true
## If [code]true[/code], [EntityManager] adds a [BuildingComponent].
@export var uses_building_component: bool = false
## If [code]true[/code], [EntityManager] adds an [AbilityManager].
@export var uses_ability_manager: bool = false

## High-level actions exposed through the entity's [ActionMachine].
@export var actions: Array[ActionMachine.action_types] = []
## Low-level states exposed through the entity's [StateMachine].
@export var states: Array[StateMachine.state_types] = []
