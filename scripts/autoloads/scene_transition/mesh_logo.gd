extends MeshInstance2D

func _ready() -> void:
	mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var polygon : Array[Vector2] = []
	for i in range(61):
		polygon.append(Vector2(cos(i * TAU / 100), -sin(i * TAU / 100)))
	polygon.append(Vector2.ZERO)
	var indices = Geometry2D.triangulate_polygon(polygon)
	for index in indices:
		mesh.surface_set_uv((polygon[index] + Vector2(1,1))/2)
		mesh.surface_add_vertex_2d(polygon[index] * 250)
	mesh.surface_end()
	
