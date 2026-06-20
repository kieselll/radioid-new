extends CharacterBody2D
class_name BaseEntity

#region Vars

@export var entity_data: EntityData
@export var personality_profile: PersonalityProfile
@export var behavior_data: BehaviorData
@export var sprite: Sprite2D

var template_id: StringName = &""
var entity_id: int = -1
var current_health: int = 0
var entity_type: EntityManager.types

#endregion

#region Textures

# Move this into the new helper script and don't hardcode it
var front_texture = load("res://man_S.png")
var left_texture = load("res://man_E.png")
var back_texture = load("res://man_N.png")
var right_texture = load("res://man_W.png")
var right_front_texture = load("res://man_SE.png")
var left_front_texture = load("res://man_SW.png")
var right_back_texture = load("res://man_NE.png")
var left_back_texture = load("res://man_NW.png")

#endregion

#region Signals

signal died

#endregion

#region Components

var action_machine: ActionMachine
var building_component: BuildingComponent
var movement_component: MovementComponent
var state_machine: StateMachine
var ability_manager: AbilityManager
var decision_maker: DecisionMaker
var _components: Array[BaseComponent] = []

#endregion

#region Lifecycle

func initialize(template: EntityTemplate, components: Dictionary = {}) -> void:
	_apply_template_data(template)
	template_id = template.id

	movement_component = components.get("movement_component")
	building_component = components.get("building_component")
	state_machine = components.get("state_machine")
	action_machine = components.get("action_machine")
	ability_manager = components.get("ability_manager")
	decision_maker = components.get("decision_maker")
	_components.clear()

	if movement_component:
		movement_component.setup(self)
		_components.append(movement_component)

	if building_component:
		building_component.setup(self)
		_components.append(building_component)

	if state_machine:
		state_machine.setup(self)
		_components.append(state_machine)
		_configure_states(template.states)

	if action_machine:
		action_machine.setup(self)
		action_machine.state_machine = state_machine
		_components.append(action_machine)
		_configure_actions(template.actions)

	if ability_manager:
		ability_manager.setup(self)
		_components.append(ability_manager)

	if decision_maker:
		decision_maker.setup(self)
		_components.append(decision_maker)

	_update_label()


func _process(delta: float) -> void:
	_tick_components(BaseComponent.regular, delta)


func _physics_process(delta: float) -> void:
	_tick_components(BaseComponent.physics, delta)

#endregion

#region Setup

func _apply_template_data(template: EntityTemplate) -> void:
	entity_data = template.entity_data.duplicate(true) if template.entity_data else null
	personality_profile = (
		template.personality_profile.duplicate(true) if template.personality_profile else null
	)
	behavior_data = template.behavior_data.duplicate(true) if template.behavior_data else null
	current_health = entity_data.max_health if entity_data else 0


func _configure_states(template_states: Array[StateMachine.state_types]) -> void:
	var states_to_add: Array = template_states.duplicate()
	if not states_to_add.has(StateMachine.state_types.idle_state):
		states_to_add.push_front(StateMachine.state_types.idle_state)

	for state_type in states_to_add:
		state_machine.add_state(state_type)

	state_machine.set_initial_state(StateMachine.state_types.idle_state)


func _configure_actions(template_actions: Array[ActionMachine.action_types]) -> void:
	for action_type in template_actions:
		action_machine.add_action(action_type)


func _update_label() -> void:
	if not has_node("Label"):
		return

	if entity_data and entity_data.display_name != &"":
		$Label.text = String(entity_data.display_name)
	else:
		$Label.text = name

#endregion

#region Private helpers

func _tick_components(tick_type: int, delta: float) -> void:
	for component in _components:
		if component and component.tick_type == tick_type and component.ticking:
			component.tick(delta)


# This needs to later be moved into a separate helper script
func rotate_sprite(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	var angle := wrapf(direction.angle(), 0.0, TAU)
	var octant := int(floor((angle + PI / 8.0) / (PI / 4.0))) % 8

	match octant:
		0: sprite.texture = right_texture
		1: sprite.texture = right_front_texture
		2: sprite.texture = front_texture
		3: sprite.texture = left_front_texture
		4: sprite.texture = left_texture
		5: sprite.texture = left_back_texture
		6: sprite.texture = back_texture
		7: sprite.texture = right_back_texture

#endregion

#region Saving

func serialize() -> Dictionary:
	var result := {
		"entity_id" : entity_id,
		"template_id" : template_id,
		"entity_type" :entity_type,
		#I'm using var_to_str because THE FUCKASS VECTOR4I WON'T PARSE NORMALLY
		"position" : var_to_str(GridUtils.world_coord_to_chunk_coord(position)),
		"current_health" : current_health,
		"current_action" : action_machine.serialize(),
	}
	return result

#endregion

#region Debug (REMOVE LATER BEFORE CBT PLEEEEAAASE) CRITICAL CRITICAL CRITICAL CRITICAL CRITICAL

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_Q:
				print(current_health)
				print(GridUtils.world_coord_to_chunk_coord(position))
			KEY_U:
				current_health = 5
			KEY_K:
				current_health = 0
			KEY_KP_ADD:
				if ability_manager:
					ability_manager.add_xp(AbilityManager.ability_names.BUILD, 1000)
					print(ability_manager.get_ability_level(AbilityManager.ability_names.BUILD))
			KEY_KP_SUBTRACT:
				if ability_manager:
					ability_manager._ability_xp[AbilityManager.ability_names.BUILD] = maxi(
						0,
						ability_manager._ability_xp[AbilityManager.ability_names.BUILD] - 1000
					)
					print(ability_manager.get_ability_level(AbilityManager.ability_names.BUILD))

#endregion
