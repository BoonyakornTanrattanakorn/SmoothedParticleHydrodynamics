extends Node2D

var particle_position_array: PackedVector2Array
var particle_velocity_array: PackedVector2Array
var particle_density_array: PackedFloat32Array
var particle_num: int

var min_density := 0.0
var max_density := 0.0

func _draw() -> void:
	for idx in range(particle_num):
		var color := _get_particle_color(idx)
		draw_circle(particle_position_array[idx] * Global._scale + Global._offset, Global.particle_radius * Global._scale, color)

func _get_particle_color(idx: int) -> Color:
	var color := Color.BLUE
	var ratio = (particle_density_array[idx] - min_density) / (max_density - min_density)
	color.b = 1 - ratio
	color.g = ratio
	return color

# TODO IMPLEMENT MEA MAX MIN DENSITY
func _draw_particles(particle_position_array: PackedVector2Array, 
					particle_velocity_array: PackedVector2Array, 
					particle_density_array: PackedFloat32Array, 
					particle_num: int) -> void:
	self.particle_position_array = particle_position_array
	self.particle_velocity_array = particle_velocity_array
	self.particle_density_array = particle_density_array
	self.particle_num = particle_num
	
	_calculate_density_range()
	queue_redraw()
		
func _calculate_density_range() -> void:
	var tmp_max = particle_density_array[0]
	var tmp_min = particle_density_array[0]
	for d in particle_density_array:
		tmp_min = min(min_density, d)
		tmp_max = max(max_density, d)
	var alpha = 0.5
	max_density = alpha * tmp_max + (1 - alpha) * max_density
	min_density = alpha * tmp_min + (1 - alpha) * min_density
