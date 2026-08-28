extends MeshInstance2D


func _ready() -> void:
	var immediate_mesh := ImmediateMesh.new()
	mesh = immediate_mesh
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var polygon: Array[Vector2] = []
	for i in range(61):
		polygon.append(Vector2(cos(i * TAU / 100), -sin(i * TAU / 100)))
	polygon.append(Vector2.ZERO)
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(polygon)
	for index: int in indices:
		immediate_mesh.surface_set_uv((polygon[index] + Vector2(1, 1)) / 2)
		immediate_mesh.surface_add_vertex_2d(polygon[index] * 250)
	immediate_mesh.surface_end()
	await get_tree().process_frame
	position = get_window().size / 2
