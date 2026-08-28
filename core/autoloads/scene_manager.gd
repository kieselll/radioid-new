extends Node


static func change_scene_to_file(scene_file: String, transition: bool) -> void:
	var scene_tree = SceneTree.new()
	if not transition:
		scene_tree.change_scene_to_file(scene_file)
		return
