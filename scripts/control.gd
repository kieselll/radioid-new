extends Control
var time: float
var seconds: int
var minutes: int
var hours: int
@onready var process_handler: ProcessHandler = $"../handlers/process_handler"
@onready var minute_hand: ColorRect = $CanvasLayer/clock/Sprite2D/ColorRect3
@onready var second_hand: ColorRect = $CanvasLayer/clock/Sprite2D/ColorRect2
@onready var clock_label: Label = $CanvasLayer/clock/Label


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	time = process_handler.time
	minute_hand.rotation += 0.00523598775 * delta
	second_hand.rotation += 0.06283185299999999 * delta
	minutes = roundi((time - floori(time) + (floori(time) % 100)) / 1.666666666)
	hours = int(time / 100)
	clock_label.text = "%02d:%02d" % [hours, minutes]
