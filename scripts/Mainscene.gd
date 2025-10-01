extends Node2D
var saved_scene = PackedScene.new()
var dir_access = DirAccess.open("res://")
func _on_button_pressed():
	$Control / popup_layer / pause_menu.show()
	$Control / popup_layer / Panel3.show()
	get_tree().paused = true

func _input(event: InputEvent) -> void :
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
		$Control / popup_layer / pause_menu.show()
		$Control / popup_layer / Panel3.show()
		get_tree().paused = true
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.keycode == KEY_F1 and event.is_pressed():
		if $Control / CanvasLayer.visible:
			$Control / CanvasLayer.hide()
		else:
			$Control / CanvasLayer.show()

# CRITICAL MOVE ME TO UI_HANDLER
