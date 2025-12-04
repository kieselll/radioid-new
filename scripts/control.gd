extends Control
var time
var seconds
var minutes
var hours


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	time = $"../handlers/process_handler".time
	$CanvasLayer/clock/Sprite2D/ColorRect3.rotation = (
		$CanvasLayer/clock/Sprite2D/ColorRect3.rotation + (0.00523598775 * delta)
	)
	$CanvasLayer/clock/Sprite2D/ColorRect2.rotation = (
		$CanvasLayer/clock/Sprite2D/ColorRect2.rotation + (0.06283185299999999 * delta)
	)
	minutes = roundi((time - floori(time) + (floori(time) % 100)) / 1.666666666)
	hours = int(time / 100)
	$CanvasLayer/clock/Label.text = "%02d:%02d" % [hours, minutes]
