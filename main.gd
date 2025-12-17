extends Node2D

var rng = RandomNumberGenerator.new()

var rd := RenderingServer.create_local_rendering_device()
var density_compute_shader_file := load("res://density_compute_shader.glsl")
var density_compute_shader_spirv: RDShaderSPIRV = density_compute_shader_file.get_spirv()
var density_compute_shader := rd.shader_create_from_spirv(density_compute_shader_spirv)
var density_compute_pipeline := rd.compute_pipeline_create(density_compute_shader)

var particle_position: PackedVector2Array = []
var particle_velocity: PackedVector2Array = []

var particle_array: Array[Particle] = []
var particle_num = 10

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
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_add_particle((event.position - Global._offset) / Global._scale)

func _update_physics(delta: float) -> void:
	# Calculate particles density
	for particle_index in range(particle_array.size()):
		particle_array[particle_index].density = _calculate_density_cpu(particle_array[particle_index]._position)
	# Calculate pressure force
	for particle_index in range(particle_array.size()):
		var pressure_force = _calculate_pressure_force(particle_index)
		particle_array[particle_index]._velocity += (pressure_force / particle_array[particle_index].density) * delta
	# Calculate particle position
	for particle_index in range(particle_array.size()):
		particle_array[particle_index]._velocity += Global.gravity * delta;
		particle_array[particle_index]._position += particle_array[particle_index]._velocity * delta
		particle_array[particle_index]._velocity *= Global.damp
		particle_array[particle_index]._update_physics(delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_physics(delta)
	
func _calculate_density_cpu(_position: Vector2) -> float:
	var density = 0
	for idx in range(particle_array.size()):
		var dst = (particle_array[idx]._position - _position).length()
		density += Global.particle_mass * SmoothingKernel.W(dst)
	Global.min_density = min(Global.min_density, density)
	Global.max_density = max(Global.max_density, density)
	return density

func _calculate_density_gpu() -> PackedFloat32Array:
	# Position buffer (binding = 0)
	var position_bytes := particle_position.to_byte_array()
	var position_buffer := rd.storage_buffer_create(position_bytes.size(), position_bytes)

	var position_uniform := RDUniform.new()
	position_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	position_uniform.binding = 0
	position_uniform.add_id(position_buffer)

	# Density buffer (binding = 1)
	var density_input := PackedFloat32Array()
	density_input.resize(particle_num)
	var density_bytes := density_input.to_byte_array()
	var density_buffer := rd.storage_buffer_create(density_bytes.size(), density_bytes)

	var density_uniform := RDUniform.new()
	density_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	density_uniform.binding = 1
	density_uniform.add_id(density_buffer)

	# Param buffer (binding = 2)
	var param := PackedFloat32Array([particle_num, Global.smoothing_radius, Global.particle_mass])
	var param_bytes := param.to_byte_array()
	var param_buffer := rd.storage_buffer_create(param_bytes.size(), param_bytes)

	var param_uniform := RDUniform.new()
	param_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	param_uniform.binding = 2
	param_uniform.add_id(param_buffer)

	# uniform set for set = 0
	var uniform_set := rd.uniform_set_create(
		[density_uniform, position_uniform, param_uniform],
		density_compute_shader,
		0
	)

	# dispatch compute shader
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, density_compute_pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, particle_num, 1, 1)
	rd.compute_list_end()

	rd.submit()
	# we can actually do other CPU tasks here while GPU is working
	rd.sync ()

	# read back density buffer
	var density_output_bytes := rd.buffer_get_data(density_buffer)
	var density_output := density_output_bytes.to_float32_array()
	return density_output


func _calculate_density_gradient(_position: Vector2) -> Vector2:
	const delta = 1e-6
	var origin = _calculate_density_cpu(_position)
	var dx = _calculate_density_cpu(_position + Vector2.RIGHT * delta) - origin
	var dy = _calculate_density_cpu(_position + Vector2.UP * delta) - origin
	var dir = Vector2(-dx, dy)
	return Vector2.ZERO if dir == Vector2.ZERO else dir / dir.length()
	
func _convert_density_to_pressure(density: float) -> float:
	return Global.gas_constant * (density - Global.rest_density)

func _calculate_pressure_force(particle_index: int) -> Vector2:
	var pressure_force = Vector2.ZERO
	var self_pressure = _convert_density_to_pressure(particle_array[particle_index].density)
	for idx in range(particle_array.size()):
		if idx == particle_index: continue
		var dst = (particle_array[idx]._position - particle_array[particle_index]._position).length()
		var other_pressure = _convert_density_to_pressure(particle_array[idx].density)
		
		var dir = Vector2(rng.randf(), rng.randf()) if dst == 0 \
		else (particle_array[idx]._position - particle_array[particle_index]._position) / dst
		var grad = SmoothingKernel.Wgrad(dst)
		var shared_pressure = (self_pressure + other_pressure) / 2.0
		var density = particle_array[idx].density
		
		pressure_force += -shared_pressure * dir * grad \
		 * Global.particle_mass / density
	return pressure_force
