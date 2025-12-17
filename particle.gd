extends Node2D

var particle_position_array: PackedVector2Array
var particle_velocity_array: PackedVector2Array
var particle_density_array: PackedFloat32Array
var particle_num: int

func _draw() -> void:
	for idx in range(particle_num):
		var color := _get_particle_color(idx)
		draw_circle(particle_position_array[idx] * Global._scale + Global._offset, Global.particle_radius * Global._scale, color)

func _get_particle_color(idx: int) -> Color:
	var color := Color.BLUE
	var ratio = (particle_density_array[idx] - Global.min_density) / (Global.max_density - Global.min_density)
	color.b = 1 - ratio
	color.g = ratio
	return color

func _draw_particles(particle_position_array: PackedVector2Array,
					particle_velocity_array: PackedVector2Array,
					particle_density_array: PackedFloat32Array,
					particle_num: int) -> void:
	self.particle_position_array = particle_position_array
	self.particle_velocity_array = particle_velocity_array
	self.particle_density_array = particle_density_array
	self.particle_num = particle_num
	queue_redraw()
