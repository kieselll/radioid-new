extends Node2D
var saved_scene = PackedScene.new()
var dir_access = DirAccess.open("res://")


func _ready() -> void:
	SceneTransition.finish_trans()
	GlobalLogger.write_to_logs(self, "Scene changed to game")
	InputHandler.world_init()
