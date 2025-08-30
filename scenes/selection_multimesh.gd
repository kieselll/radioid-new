extends Node

@onready var valid_multimesh_inst : MultiMeshInstance2D = $valid_selection_multimesh
@onready var invalid_multimesh_inst : MultiMeshInstance2D = $invalid_selection_multimesh
@onready var valid_multimesh : MultiMesh = $valid_selection_multimesh.multimesh
@onready var invalid_multimesh : MultiMesh = $invalid_selection_multimesh.multimesh

func set_multimesh_texture(texture : Texture2D) -> void:
	valid_multimesh_inst.texture = texture
	invalid_multimesh_inst.texture = texture

func create_mesh_instances(rects : Dictionary) -> void:
	valid_multimesh.instance_count = rects.valid.size()
	invalid_multimesh.instance_count = rects.invalid.size()
	for instance_id in valid_multimesh.instance_count:
		var pair = rects.valid[instance_id]
		valid_multimesh.set_instance_transform_2d(instance_id, Transform2D(PI, pair.coords))
		valid_multimesh.set_instance_custom_data(instance_id, Color(pair.rect.position.x, pair.rect.position.y, pair.rect.size.x, pair.rect.size.y))
	for instance_id in invalid_multimesh.instance_count:
		var pair = rects.invalid[instance_id]
		invalid_multimesh.set_instance_transform_2d(instance_id, Transform2D(PI, pair.coords))
		invalid_multimesh.set_instance_custom_data(instance_id, Color(pair.rect.position.x, pair.rect.position.y, pair.rect.size.x, pair.rect.size.y))

func erase_mesh_instances() -> void:
	valid_multimesh.instance_count = 0
	invalid_multimesh.instance_count = 0
