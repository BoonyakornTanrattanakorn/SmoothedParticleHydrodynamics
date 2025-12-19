extends Node2D
class_name Main


func _update_physics(delta: float) -> void:
	if $ParticleContainer.particle_num == 0: return
	# Calculate particles density
	var particle_density_array = $Density._calculate_from_position_array($ParticleContainer.particle_position_array)
	# Calculate pressure force
	var pressure_force_array = $PressureForce._calculate_array($ParticleContainer.particle_position_array, particle_density_array)
	for p_i in range(pressure_force_array.size()):
		$ParticleContainer.particle_velocity_array[p_i] += (pressure_force_array[p_i] / particle_density_array[p_i]) * delta
	# Calculate particle position
	for particle_index in range($ParticleContainer.particle_num):
		$ParticleContainer.particle_velocity_array[particle_index] += $Settings.gravity * delta;
		$ParticleContainer.particle_position_array[particle_index] += $ParticleContainer.particle_velocity_array[particle_index] * delta
		$ParticleContainer.particle_velocity_array[particle_index] *= $Settings.damp
	_bounding_box_collision()
	$ParticleRenderer._draw_particles($ParticleContainer.particle_position_array, $ParticleContainer.particle_velocity_array,
	particle_density_array, $ParticleContainer.particle_num, $Density.max_density, $Density.min_density)

func _update_labels(delta: float, physics_time: float) -> void:
	if $InfoLabel != null:
		$InfoLabel.text = "Particles: " + str($ParticleContainer.particle_num) + "\n" + \
						  "Physics Time: " + str(int(physics_time)) + " ms\n" + \
						  "FPS: " + str(snapped(1 / delta, 0.01)) + "\n" + \
						  "Max Density: " + str(snapped($Density.max_density, 0.01)) + "\n" + \
						  "Min Density: " + str(snapped($Density.min_density, 0.01)) + "\n" + \
						  "Avg Density: " + str(snapped($Density.avg_density, 0.01)) + "\n"
	else:
		push_error("InfoLabel is null!")
					
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var start_time = Time.get_ticks_msec()
	var t = min(delta, $Settings.time_step)
	_update_physics(t)
	var end_time = Time.get_ticks_msec()
	_update_labels(delta, end_time - start_time)

func _calculate_density_gradient(_position: Vector2) -> Vector2:
	const delta = 1e-6
	var origin = $Density._at_position(_position, $ParticleContainer.particle_position_array)
	var dx = $Density._at_position(_position + Vector2.RIGHT * delta, $ParticleContainer.particle_position_array) - origin
	var dy = $Density._at_position(_position + Vector2.UP * delta, $ParticleContainer.particle_position_array) - origin
	var dir = Vector2(-dx, dy)
	return Vector2.ZERO if dir == Vector2.ZERO else dir / dir.length()

# TODO: move to gpu
func _bounding_box_collision() -> void:
	for idx in range($ParticleContainer.particle_num):
		if ($ParticleContainer.particle_position_array[idx].x > $Settings.box_dimension.x - $Settings.particle_radius):
			$ParticleContainer.particle_position_array[idx].x = $Settings.box_dimension.x - $Settings.particle_radius;
			$ParticleContainer.particle_velocity_array[idx].x *= -$Settings.damp;
		elif ($ParticleContainer.particle_position_array[idx].x < $Settings.particle_radius):
			$ParticleContainer.particle_position_array[idx].x = $Settings.particle_radius;
			$ParticleContainer.particle_velocity_array[idx].x *= -$Settings.damp;
		if ($ParticleContainer.particle_position_array[idx].y > $Settings.box_dimension.y - $Settings.particle_radius):
			$ParticleContainer.particle_position_array[idx].y = $Settings.box_dimension.y - $Settings.particle_radius;
			$ParticleContainer.particle_velocity_array[idx].y *= -$Settings.damp;
		elif ($ParticleContainer.particle_position_array[idx].y < $Settings.particle_radius):
			$ParticleContainer.particle_position_array[idx].y = $Settings.particle_radius;
			$ParticleContainer.particle_velocity_array[idx].y *= -$Settings.damp;
