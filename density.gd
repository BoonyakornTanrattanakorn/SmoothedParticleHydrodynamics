extends Node
class_name Density

static var rd := RenderingServer.create_local_rendering_device()
static var density_compute_shader_file := load("res://density_compute_shader.glsl")
static var density_compute_shader_spirv: RDShaderSPIRV = density_compute_shader_file.get_spirv()
static var density_compute_shader := rd.shader_create_from_spirv(density_compute_shader_spirv)
static var density_compute_pipeline := rd.compute_pipeline_create(density_compute_shader)

static func _at_position(particle_position: Vector2, particle_position_array: PackedVector2Array) -> float:
	var density = 0
	for p_j in range(particle_position_array.size()):
		var dst = (particle_position_array[p_j] - particle_position).length()
		density += Global.particle_mass * SmoothingKernel.W(dst)
	return density

static func _calculate_from_position_array(particle_position_array: PackedVector2Array) -> PackedFloat32Array:
	var density: PackedFloat32Array
	if Global.use_gpu:
		density = _calculate_gpu(particle_position_array)
	else:
		density = _calculate_cpu(particle_position_array)
	return density

static func _calculate_cpu(particle_position_array: PackedVector2Array) -> PackedFloat32Array:
	var density := PackedFloat32Array()
	density.resize(particle_position_array.size())
	for p_i in range(density.size()):
		density[p_i] = _at_position(particle_position_array[p_i], particle_position_array)
	return density

	
static func _calculate_gpu(particle_position_array: PackedVector2Array) -> PackedFloat32Array:
	if particle_position_array.size() == 0 or particle_position_array == null: 
		return PackedFloat32Array()
	
	# Position buffer (binding = 0)
	var position_bytes := particle_position_array.to_byte_array()
	var position_buffer := rd.storage_buffer_create(position_bytes.size(), position_bytes)

	var position_uniform := RDUniform.new()
	position_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	position_uniform.binding = 0
	position_uniform.add_id(position_buffer)

	# Density buffer (binding = 1)
	var density_input := PackedFloat32Array()
	density_input.resize(particle_position_array.size())
	var density_bytes := density_input.to_byte_array()
	var density_buffer := rd.storage_buffer_create(density_bytes.size(), density_bytes)

	var density_uniform := RDUniform.new()
	density_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	density_uniform.binding = 1
	density_uniform.add_id(density_buffer)

	# Param buffer (binding = 2)
	var param := PackedFloat32Array([Global.particle_mass, particle_position_array.size(), Global.smoothing_length])
	var param_bytes := param.to_byte_array()
	var param_buffer := rd.storage_buffer_create(param_bytes.size(), param_bytes)

	var param_uniform := RDUniform.new()
	param_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	param_uniform.binding = 2
	param_uniform.add_id(param_buffer)

	# uniform set for set = 0
	var uniform_set := rd.uniform_set_create(
		[position_uniform, density_uniform, param_uniform],
		density_compute_shader,
		0
	)

	# dispatch compute shader
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, density_compute_pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, particle_position_array.size(), 1, 1)
	rd.compute_list_end()

	rd.submit()
	# we can actually do other CPU tasks here while GPU is working
	rd.sync()

	# read back density buffer
	var density_output_bytes := rd.buffer_get_data(density_buffer)
	var density_output := density_output_bytes.to_float32_array()
	return density_output
