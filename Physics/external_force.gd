extends Node
class_name ExternalForce

enum Force {NONE, PULL, PUSH}
var force := Force.NONE

var settings: Settings
var input_handler: InputHandler

func _ready() -> void:
	settings = get_parent().get_node("Settings")
	input_handler = get_parent().get_node("InputHandler")

# make every particles in radius to accelerate to origin
func _calculate_external_force(particle_postion_array: PackedVector2Array) -> PackedVector2Array:
	var particle_force_array := PackedVector2Array()
	particle_force_array.resize(particle_postion_array.size())
	if force != Force.NONE:
		for p_i in range(particle_force_array.size()):
			var dst = (particle_postion_array[p_i] - input_handler.mouse_position).length()
			if dst > settings.force_radius: continue
			var dir
			if force == Force.PUSH:
				dir = (particle_postion_array[p_i] - input_handler.mouse_position).normalized()
			else: 
				dir = (input_handler.mouse_position - particle_postion_array[p_i]).normalized()
			particle_force_array[p_i] += dir * settings.force_acceleration * settings.particle_mass
		force = Force.NONE
	return particle_force_array
