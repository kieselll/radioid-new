extends Node

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

@onready var valid_multimesh_inst : MultiMeshInstance2D = $valid_selection_multimesh
@onready var invalid_multimesh_inst : MultiMeshInstance2D = $invalid_selection_multimesh

@onready var valid_multimesh : MultiMesh = valid_multimesh_inst.multimesh
@onready var invalid_multimesh : MultiMesh = invalid_multimesh_inst.multimesh


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
func set_multimesh_texture(texture : Texture2D) -> void:
	valid_multimesh_inst.texture = texture
	invalid_multimesh_inst.texture = texture


## Creates both valid and invalid multimesh tile instances.
## rects = {valid = [ {coords, rect}, ...], invalid = [...]}
func create_mesh_instances(rects : Dictionary) -> void:
	# --- Set instance counts ---
	valid_multimesh.instance_count = rects.valid.size()

	invalid_multimesh.instance_count = rects.invalid.size()

	# --- Create valid instances ---
	for id in range(valid_multimesh.instance_count):
		var pair = rects.valid[id]

		valid_multimesh.set_instance_transform_2d(
			id,
			Transform2D(PI, pair.coords)
		)

		valid_multimesh.set_instance_custom_data(
			id,
			Color(pair.rect.position.x, pair.rect.position.y, pair.rect.size.x, pair.rect.size.y)
		)

	# --- Create invalid instances ---
	for id in range(invalid_multimesh.instance_count):
		var pair = rects.invalid[id]

		invalid_multimesh.set_instance_transform_2d(
			id,
			Transform2D(PI, pair.coords)
		)

		invalid_multimesh.set_instance_custom_data(
			id,
			Color(pair.rect.position.x, pair.rect.position.y, pair.rect.size.x, pair.rect.size.y)
		)


## Removes all preview tiles from both multimeshes.
func erase_mesh_instances() -> void:
	valid_multimesh.instance_count = 0
	invalid_multimesh.instance_count = 0
