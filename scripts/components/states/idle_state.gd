@icon("res://textures/editor_icons/cancel.svg")
@warning_ignore_start("unused_parameter")
class_name IdleState
extends BaseState

#region public vars

var state_name = &"idle_state"

#endregion

#region lifecycle

func start(args = {}) -> void:
	GlobalLogger.write_to_logs(
		self, "[WARN]: Idling. Should not be displayed unless intended by mods"
	)
	_active = true


func stop() -> void:
	GlobalLogger.write_to_logs(self, "Stopped idling")
	_active = false

#endregion
