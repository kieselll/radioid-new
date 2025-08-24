extends MultiMeshInstance2D

func create_mesh_instances(pairs : Array) -> void:
	multimesh.instance_count = pairs.size()
	for i in pairs.size():
		multimesh.set_instance_transform_2d(i, Transform2D(PI, pairs[i][0]))
		multimesh.set_instance_custom_data(i, Color(pairs[i][1].position.x, pairs[i][1].position.y, pairs[i][1].size.x, pairs[i][1].size.y))

func erase_mesh_instances() -> void:
	multimesh.instance_count = 0
