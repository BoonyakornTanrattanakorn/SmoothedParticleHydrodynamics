extends Node
class_name PressureForce

static var rng = RandomNumberGenerator.new()

static var rd := RenderingServer.create_local_rendering_device()
static var pressure_force_compute_shader_file := load("res://PressureForce/pressure_force_compute_shader.glsl")
static var pressure_force_compute_shader_spirv: RDShaderSPIRV = pressure_force_compute_shader_file.get_spirv()
static var pressure_force_compute_shader := rd.shader_create_from_spirv(pressure_force_compute_shader_spirv)
static var pressure_force_compute_pipeline := rd.compute_pipeline_create(pressure_force_compute_shader)

static func _convert_density_to_pressure(density: float) -> float:
	return Global.gas_constant * (density - Global.rest_density)
	
static func _calculate_array(particle_position_array: PackedVector2Array,
							particle_density_array: PackedFloat32Array) -> PackedVector2Array:
	var pressure_force: PackedVector2Array
	if Global.use_gpu && false:
		pressure_force = _calculate_gpu(particle_position_array, particle_density_array)
	else:
		pressure_force = _calculate_cpu(particle_position_array, particle_density_array)
	return pressure_force

static func _calculate_cpu(particle_position_array: PackedVector2Array,
						particle_density_array: PackedFloat32Array) -> PackedVector2Array:
	var pressure_force = PackedVector2Array()
	pressure_force.resize(particle_position_array.size())
	for p_i in range(pressure_force.size()):
		var self_pressure = _convert_density_to_pressure(particle_density_array[p_i])
		for p_j in range(pressure_force.size()):
			if p_i == p_j: continue
			var dst = (particle_position_array[p_j] - particle_position_array[p_i]).length()
			var other_pressure = _convert_density_to_pressure(particle_density_array[p_j])
			
			var dir = Vector2(rng.randf(), rng.randf()) if dst == 0 \
			else (particle_position_array[p_j] - particle_position_array[p_i]) / dst
			var grad = SmoothingKernel.Wgrad(dst)
			var shared_pressure = (self_pressure + other_pressure) / 2.0
			var density = particle_density_array[p_j]
			
			pressure_force[p_i] += -shared_pressure * dir * grad \
			 * Global.particle_mass / density
	return pressure_force

static func _calculate_gpu(particle_position_array: PackedVector2Array,
						particle_density_array: PackedFloat32Array) -> PackedVector2Array:
	return PackedVector2Array()
	#if particle_position_array.size() == 0 or particle_position_array == null or \
		#particle_density_array.size() == 0 or particle_density_array == null: 
		#return PackedVector2Array()
	#
	## Position buffer (binding = 0)
	#var position_bytes := particle_position_array.to_byte_array()
	#var position_buffer := rd.storage_buffer_create(position_bytes.size(), position_bytes)
#
	#var position_uniform := RDUniform.new()
	#position_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	#position_uniform.binding = 0
	#position_uniform.add_id(position_buffer)
#
	## Density buffer (binding = 1)
	#var density_input := PackedFloat32Array()
	#density_input.resize(particle_position_array.size())
	#var density_bytes := density_input.to_byte_array()
	#var density_buffer := rd.storage_buffer_create(density_bytes.size(), density_bytes)
#
	#var density_uniform := RDUniform.new()
	#density_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	#density_uniform.binding = 1
	#density_uniform.add_id(density_buffer)
#
	## Param buffer (binding = 2)
	#var param := PackedFloat32Array([Global.particle_mass, particle_position_array.size(), Global.smoothing_length])
	#var param_bytes := param.to_byte_array()
	#var param_buffer := rd.storage_buffer_create(param_bytes.size(), param_bytes)
#
	#var param_uniform := RDUniform.new()
	#param_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	#param_uniform.binding = 2
	#param_uniform.add_id(param_buffer)
#
	## uniform set for set = 0
	#var uniform_set := rd.uniform_set_create(
		#[position_uniform, density_uniform, param_uniform],
		#density_compute_shader,
		#0
	#)
#
	## dispatch compute shader
	#var compute_list := rd.compute_list_begin()
	#rd.compute_list_bind_compute_pipeline(compute_list, density_compute_pipeline)
	#rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	#rd.compute_list_dispatch(compute_list, particle_position_array.size(), 1, 1)
	#rd.compute_list_end()
#
	#rd.submit()
	## we can actually do other CPU tasks here while GPU is working
	#rd.sync()
#
	## read back density buffer
	#var density_output_bytes := rd.buffer_get_data(density_buffer)
	#var density_output := density_output_bytes.to_float32_array()
	#return density_output
