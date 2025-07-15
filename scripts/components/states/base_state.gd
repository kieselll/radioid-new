class_name BaseState
extends Node

func start(args = {}) -> void:
	printerr("%s doesn't have start functionality implemented. Please override this function in the superclass to get rid of this warning" %name)

func stop() -> void:
	printerr("%s doesn't have stop functionality implemented. Please override this function in the superclass to get rid of this warning" %name)
