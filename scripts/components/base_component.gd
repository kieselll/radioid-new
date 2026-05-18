@abstract
extends RefCounted
class_name BaseComponent

enum {
	none,
	regular,
	physics,
}

var tick_type = none
var ticking = false

@abstract func tick(delta : float) -> void;

# Add more functions here later
