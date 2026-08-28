@abstract
extends RefCounted
class_name BaseComponent

enum tick_types{
	none,
	regular,
	physics,
}

var tick_type: tick_types = tick_types.none
var ticking: bool = false

@abstract func tick(delta : float) -> void;

# Add more functions here later
