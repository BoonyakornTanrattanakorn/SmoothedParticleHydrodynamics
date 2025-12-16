extends Node2D

var rng = RandomNumberGenerator.new()

var particle_array : Array[Particle] = []
var particle_num = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(particle_num):
		_add_particle(Vector2(rng.randf_range(0, Global.box_dimension.x),
							  rng.randf_range(0, Global.box_dimension.y)))

func _add_particle(_position: Vector2) -> void:
	var p = Particle.new_particle(
		Vector2.ZERO,
		_position
	)
	particle_array.append(p)
	add_child(p)

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT and event.is_pressed():
			_add_particle((event.position - Global._offset) / Global._scale)

func _update_physics(delta: float) -> void:
	# Calculate particles density
	for particle_index in range(particle_array.size()):
		particle_array[particle_index].density = _calculate_density(particle_array[particle_index]._position)
	# Calculate pressure force
	for particle_index in range(particle_array.size()):
		var pressure_force = _calculate_pressure_force(particle_index)
		particle_array[particle_index]._velocity += (pressure_force / particle_array[particle_index].density) * delta
	# Calculate particle position
	for particle_index in range(particle_array.size()):
		#particle_array[particle_index]._velocity += Global.gravity * delta;
		particle_array[particle_index]._position += particle_array[particle_index]._velocity * delta
		particle_array[particle_index]._update_physics(delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_physics(delta)
	
func _calculate_density(_position: Vector2) -> float:
	var density = 0
	for idx in range(particle_array.size()):
		var dst = (particle_array[idx]._position - _position).length()
		density += Global.particle_mass * SmoothingKernel.W(dst)
	Global.min_density = min(Global.min_density, density)
	Global.max_density = max(Global.max_density, density)
	return density

func _calculate_density_gradient(_position: Vector2) -> Vector2:
	const delta = 1e-3
	var origin = _calculate_density(_position)
	var dx = _calculate_density(_position + Vector2.UP * delta) - origin
	var dy = _calculate_density(_position + Vector2.RIGHT * delta) - origin
	var dir = Vector2(dy, dx)
	return dir / dir.length()
	
func _convert_density_to_pressure(density: float) -> float:
	return Global.gas_constant * (density - Global.rest_density)

func _calculate_pressure_force(particle_index: int) -> Vector2:
	var pressure_force = Vector2.ZERO
	var self_pressure = _convert_density_to_pressure(particle_array[particle_index].density)
	for idx in range(particle_array.size()):
		if idx == particle_index: continue
		var dst = (particle_array[idx]._position - particle_array[particle_index]._position).length()
		var other_pressure = _convert_density_to_pressure(particle_array[idx].density)
		
		var dir = Vector2(rng.randf(), rng.randf()) if dst == 0  \
		else (particle_array[idx]._position - particle_array[particle_index]._position) / dst
		var grad = SmoothingKernel.Wgrad(dst)
		var shared_pressure = (self_pressure + other_pressure) / 2.0
		var density = particle_array[idx].density
		pressure_force += -shared_pressure * dir * grad \
		 * Global.particle_mass / density
	return pressure_force
