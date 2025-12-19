extends Node
class_name ParticleContainer

var rng = RandomNumberGenerator.new()
var settings: Settings

var particle_position_array: PackedVector2Array = []
var particle_velocity_array: PackedVector2Array = []
var particle_num: int

func _ready() -> void:
	settings = get_parent().get_node("Settings")
	_initialize_particles()

func _add_particle(_position: Vector2) -> void:
	particle_position_array.append(_position)
	particle_velocity_array.append(Vector2.ZERO)
	particle_num += 1
	
func _initialize_particles() -> void:
	particle_num = 0
	for i in range(settings.initial_particle_num):
		_add_particle(Vector2(rng.randf_range(0, settings.box_dimension.x),
							  rng.randf_range(0, settings.box_dimension.y)))
