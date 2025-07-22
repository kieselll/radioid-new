class_name BuildAction
extends BaseAction

func start(args : Dictionary = {}) -> void:
	assert(args[&"target"] is Vector2i, "BuildAction of %s recieved start(), but has no argument \"target\" of type Vector2i.")
	assert(args[&"id"] is int, "BuildAction of %s recieved start(), but has no argument \"id\" of type int.")
	
	_active = true

func stop() -> void:
	_active = false
