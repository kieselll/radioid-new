extends Node
class_name EntityManager

#region enums

enum types
{
	pawn,
}

#endregion

#region lifecycle

func _ready() -> void:
	load_templates()
	next_entity_id = GlobalSaver.load_current_entity_id()
	#spawn_entity(types.pawn, true)

func load_templates() -> void:
	entity_templates.clear()
	var diracc := DirAccess.open("res://resources/entity_templates")
	if diracc == null:
		push_warning("Entity template directory is missing.")
		return
	for i in diracc.get_files():
		if not (i.ends_with(".tres") or i.ends_with(".res")):
			continue
		var template : EntityTemplate = load("res://resources/entity_templates/" + i)
		if template == null:
			push_warning("Failed to load Entity template: %s" % i)
			continue
		entity_templates[template.type] = template


#endregion

#region helper classes

class Entity:
	var id : int
	var type : types
	var node : BaseEntity

	@warning_ignore("shadowed_variable")
	func _init(id : int, type : types, node : BaseEntity) -> void:
		self.id = id
		self.type = type
		self.node = node

#endregion

#region vars

var entity_templates : Dictionary[types, EntityTemplate] = {}
var entities_by_id : Dictionary[int, Entity] = {}
var entities_by_chunk : Dictionary[Vector2i, Array] = {}
var next_entity_id: int = 1

var entity_pool : Array

#endregion

#region API

func spawn_entity(entity_type: types, autogenerate: bool, spawn_coord: Vector4i = Vector4i.ZERO, forced_id: int = -1) -> BaseEntity:
	var template: EntityTemplate = entity_templates.get(entity_type)
	assert(template != null, "EntityManager has no template for type %s" % types.find_key(entity_type))
	assert(template.scene != null, "EntityTemplate %s is missing a scene." % template.id)

	var entity_node := template.scene.instantiate() as BaseEntity
	assert(entity_node != null, "EntityTemplate %s did not instantiate a BaseEntity." % template.id)

	var entity_id: int
	if forced_id != -1:
		entity_id = forced_id
	else:
		entity_id = next_entity_id
		next_entity_id += 1
	entity_node.entity_id = entity_id
	entity_node.name = "%s_%d" % [template.id, entity_id]
	entity_node.position = GridUtils.chunk_coord_to_world_coord(spawn_coord)
	entity_node.entity_type = entity_type
	add_child(entity_node)
	entity_node.initialize(template, autogenerate, _build_components(template))
	GlobalRef.register_pawn(entity_node)
	var spawned_entity := Entity.new(entity_id, entity_type, entity_node)
	entities_by_id[entity_id] = spawned_entity
	if not entities_by_chunk.keys().has(Vector2i(spawn_coord.x, spawn_coord.y)):
		entities_by_chunk[Vector2i(spawn_coord.x, spawn_coord.y)] = []
	entities_by_chunk[Vector2i(spawn_coord.x, spawn_coord.y)].append(spawned_entity)
	return entity_node

func delete_entity(entity_id : int) -> void:
	if not entities_by_id.has(entity_id):
		return

	var entity_entry: Entity = entities_by_id[entity_id]
	if is_instance_valid(entity_entry.node):
		GlobalRef.unregister_pawn(entity_entry.node)
		entity_entry.node.queue_free()
	entities_by_id.erase(entity_id)


func _build_components(template: EntityTemplate) -> Dictionary:
	var components := {}

	if template.uses_movement_component:
		var movement_component := MovementComponent.new()
		if template.entity_data:
			movement_component.set_speed(template.entity_data.base_move_speed)
		components["movement_component"] = movement_component

	if template.uses_building_component:
		components["building_component"] = BuildingComponent.new()

	if not template.states.is_empty():
		components["state_machine"] = StateMachine.new()

	if not template.actions.is_empty():
		components["action_machine"] = ActionMachine.new()

	if template.uses_ability_manager:
		components["ability_manager"] = AbilityManager.new()

	if template.behavior_data and not template.actions.is_empty():
		components["decision_maker"] = DecisionMaker.new()

	return components

func serialize_entity(entity_id : int) -> Dictionary:
	return {entity_id : entities_by_id[entity_id].node.serialize()}

func deserialize_entity(serialized_dict: Dictionary) -> void:
	@warning_ignore("shadowed_variable", "unsafe_call_argument")
	var Entity := spawn_entity(serialized_dict["entity_type"], false, str_to_var(serialized_dict["position"]), serialized_dict["entity_id"])
	Entity.current_health = serialized_dict["current_health"]
	@warning_ignore("unsafe_call_argument")
	Entity.action_machine.deserialize(serialized_dict["current_action"])
	@warning_ignore("unsafe_call_argument")
	Entity.decision_maker.deserialize(serialized_dict["decision_maker"])

func serialize_chunk(chunk_coords : Vector2i) -> Dictionary:
	var result := {}
	if entities_by_chunk.has(chunk_coords):
		for entity_instance: Entity in entities_by_chunk[chunk_coords]:
			result[entity_instance.id] = entity_instance.node.serialize()
	return result

#endregion
