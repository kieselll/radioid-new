extends Node2D
var saved_scene = PackedScene.new()
var dir_access = DirAccess.open("res://")

func _ready() -> void:
	SceneTransition.finish_trans()
	GlobalLogger.write_to_logs(self, "Scene changed to game")

func _input(event: InputEvent) -> void :
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
		GlobalLogger.write_to_logs(self, "Pause menu is opened")
		$Control / popup_layer / pause_menu.show()
		$Control / popup_layer / Panel3.show()
		get_tree().paused = true
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.keycode == KEY_F1 and event.is_pressed():
		if $Control / CanvasLayer.visible:
			GlobalLogger.write_to_logs(self, "UI was hidden")
			$Control / CanvasLayer.hide()
		else:
			GlobalLogger.write_to_logs(self, "UI was shown")
			$Control / CanvasLayer.show()

# CRITICAL MOVE ME TO UI_HANDLER
