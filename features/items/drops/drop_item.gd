extends Resource
class_name DropItem

@export var id: int
@export_range(0.0, 1.0, 0.01) var weight: float
@export var amount_curve: Curve
