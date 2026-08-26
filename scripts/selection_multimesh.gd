extends Node
class_name SelectionMultimesh

#				 /$$$$$$$              /$$                           /$$
#				| $$__  $$            |__/                          | $$
#				| $$  \ $$   /$$$$$$   /$$  /$$    /$$   /$$$$$$   /$$$$$$     /$$$$$$
#				| $$$$$$$/  /$$__  $$ | $$ |  $$  /$$/  |____  $$ |_  $$_/    /$$__  $$
#				| $$____/  | $$  \__/ | $$  \  $$/$$/    /$$$$$$$   | $$     | $$$$$$$$
#				| $$       | $$       | $$   \  $$$/    /$$__  $$   | $$ /$$ | $$_____/
#				| $$       | $$       | $$    \  $/    |  $$$$$$$   |  $$$$/ |  $$$$$$$
#				|__/       |__/       |__/     \_/      \_______/    \___/    \_______/
#
#
#
#				 /$$    /$$   /$$$$$$    /$$$$$$    /$$$$$$$
#				|  $$  /$$/  |____  $$  /$$__  $$  /$$_____/
#				 \  $$/$$/    /$$$$$$$ | $$  \__/ |  $$$$$$
#				  \  $$$/    /$$__  $$ | $$        \____  $$
#				   \  $/    |  $$$$$$$ | $$        /$$$$$$$/
#				    \_/      \_______/ |__/       |_______/

@onready var valid_multimesh_inst: MultiMeshInstance2D = $valid_selection_multimesh
@onready var invalid_multimesh_inst: MultiMeshInstance2D = $invalid_selection_multimesh

@onready var valid_multimesh: MultiMesh = valid_multimesh_inst.multimesh
@onready var invalid_multimesh: MultiMesh = invalid_multimesh_inst.multimesh

#				 /$$$$$$$              /$$        /$$  /$$
#				| $$__  $$            | $$       | $$ |__/
#				| $$  \ $$  /$$   /$$ | $$$$$$$  | $$  /$$   /$$$$$$$
#				| $$$$$$$/ | $$  | $$ | $$__  $$ | $$ | $$  /$$_____/
#				| $$____/  | $$  | $$ | $$  \ $$ | $$ | $$ | $$
#				| $$       | $$  | $$ | $$  | $$ | $$ | $$ | $$
#				| $$       |  $$$$$$/ | $$$$$$$/ | $$ | $$ |  $$$$$$$
#				|__/        \______/  |_______/  |__/ |__/  \_______/
#
#
#
#				  /$$$$$$   /$$$$$$$   /$$$$$$
#				 /$$__  $$ | $$__  $$ |_  $$_/
#				| $$  \ $$ | $$  \ $$   | $$
#				| $$$$$$$$ | $$$$$$$/   | $$
#				| $$__  $$ | $$____/    | $$
#				| $$  | $$ | $$         | $$
#				| $$  | $$ | $$        /$$$$$$
#				|__/  |__/ |__/       |______/


## Assigns texture used for both valid & invalid previews.
func set_multimesh_texture(texture: Texture2D) -> void:
	valid_multimesh_inst.texture = texture
	invalid_multimesh_inst.texture = texture


## Creates both valid and invalid multimesh tile instances.
## rects = {valid = {coord : rect, ...}, invalid = {coord : rect, ...}}
func create_mesh_instances(rects: Dictionary) -> void:
	var valid_rects: Dictionary = rects["valid"]
	var invalid_rects: Dictionary = rects["invalid"]
	# --- Set instance counts ---
	valid_multimesh.instance_count = valid_rects.size()

	invalid_multimesh.instance_count = invalid_rects.size()

	# --- Create valid instances ---
	for id: int in range(valid_rects.size()):
		var coord: Vector2i = valid_rects.keys()[id]
		var rect: Rect2 = valid_rects[coord]

		valid_multimesh.set_instance_transform_2d(
			id, Transform2D(PI, Vector2(coord + Vector2i(16, 16)))
		)

		valid_multimesh.set_instance_custom_data(
			id, Color(rect.position.x, rect.position.y, rect.size.x, rect.size.y)
		)

	# --- Create invalid instances ---
	for id: int in range(invalid_rects.size()):
		var coord: Vector2i = invalid_rects.keys()[id]
		var rect: Rect2 = invalid_rects[coord]

		invalid_multimesh.set_instance_transform_2d(
			id, Transform2D(PI, Vector2(coord + Vector2i(16, 16)))
		)

		invalid_multimesh.set_instance_custom_data(
			id, Color(rect.position.x, rect.position.y, rect.size.x, rect.size.y)
		)


## Removes all preview tiles from both multimeshes.
func erase_mesh_instances() -> void:
	valid_multimesh.instance_count = 0
	invalid_multimesh.instance_count = 0
