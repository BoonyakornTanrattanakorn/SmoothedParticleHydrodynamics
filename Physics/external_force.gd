extends Node

enum Force {NONE, PULL, PUSH}
var particle_position_array: PackedVector2Array = []

# make every particles in radius to accelerate to origin
func _apply_external_force(force: Force, origin: Vector2, radius: float, acceleration: float):
