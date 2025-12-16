extends Node2D

var particle_array : Array[Particle] = []
var w = 10
var h = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(w):
		for j in range(h):
			var p = Particle.new_particle(
				Vector2.ZERO,
				Vector2(2 * Global.particle_radius * j, 2 * Global.particle_radius * i)
			)
			particle_array.append(p)
			add_child(p)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Calculate particles density
	for particle_index in range(particle_array.size()):
		_calculate_density(particle_index)
	# Calculate pressure force
	for particle_index in range(particle_array.size()):
		var pressure_force = _calculate_pressure_force(particle_index)
		particle_array[particle_index]._velocity += pressure_force / particle_array[particle_index].density * delta
	# Calculate particle position
	for particle_index in range(particle_array.size()):
		particle_array[particle_index]._velocity += Global.gravity * delta;
		particle_array[particle_index]._position += particle_array[particle_index]._velocity * delta
		particle_array[particle_index]._update_physics(delta)
	

func _calculate_density(particle_index: int) -> void:
	var density = 0
	for idx in range(particle_array.size()):
		var dst = (particle_array[idx]._position - particle_array[particle_index]._position).length()
		density += Global.particle_mass * SmoothingKernel.W(dst)
	Global.min_density = min(Global.min_density, density)
	Global.max_density = max(Global.max_density, density)
	particle_array[particle_index].density = density

func _convert_density_to_pressure(density: float) -> float:
	return Global.gas_constant * (density - Global.rest_density)

func _calculate_pressure_force(particle_index: int) -> Vector2:
	var pressure_force = Vector2.ZERO
	var self_pressure = _convert_density_to_pressure(particle_array[particle_index].density)
	for idx in range(particle_array.size()):
		if idx == particle_index: continue
		var dst = (particle_array[idx]._position - particle_array[particle_index]._position).length()
		if dst <= 1e-6: continue
		
		var other_pressure = _convert_density_to_pressure(particle_array[idx].density)
		var dir = (particle_array[idx]._position - particle_array[particle_index]._position) / dst
		var grad = SmoothingKernel.Wgrad(dst)
		var shared_pressure = (self_pressure + other_pressure) / 2.0
		var density = particle_array[idx].density
		pressure_force += -shared_pressure * dir * grad \
		 * Global.particle_mass / density
	return pressure_force
