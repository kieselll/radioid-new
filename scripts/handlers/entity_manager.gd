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

func load_templates() -> void:
	var diracc := DirAccess.open("res://resources/entity_templates")
	for i in diracc.get_files():
		var template : EntityTemplate = load("res://resources/entity_templates/" + i)
		entity_templates[template.type] = template


#endregion

#region helper classes

class entity:
	var type : types
	var node : Node

	@warning_ignore("shadowed_variable")
	func _init(type : types, node : Node) -> void:
		self.type = type
		self.node = node

#endregion

#region vars

var entity_templates : Dictionary[types, EntityTemplate]
var entities : Dictionary

var entity_pool

#endregion

#region API

func summon_entity() -> String:
	var pawn_scene : PackedScene = GlobalRef.get_scene(GlobalRef.scenes_enum.pawn)
	var pawn_node = pawn_scene.instantiate()
	pawn_node.initialize(MovementComponent.new(), BuildingComponent.new())
	pawn_node.characteristics = PawnStats.new(PawnStats.personalities.AMBIVERT, {}, [])
	add_child(pawn_node)

	return ""

func delete_entity(entity_id : int):
	pass

#endregion
