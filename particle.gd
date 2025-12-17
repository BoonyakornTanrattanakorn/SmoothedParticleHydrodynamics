extends Node2D

var settings: Settings
var particle_position_array: PackedVector2Array
var particle_velocity_array: PackedVector2Array
var particle_density_array: PackedFloat32Array
var particle_num: int

var min_density := 0.0
var max_density := 0.0

@onready var multi_mesh := MultiMesh.new()
@onready var multi_mesh_instance := MultiMeshInstance2D.new()

var multi_mesh_instance_count := 0
	
func _ready() -> void:
	settings = get_parent().get_node("Settings")
	multi_mesh_instance.multimesh = multi_mesh
	add_child(multi_mesh_instance)
	
func _create_circle_mesh() -> Mesh:
	var mesh := ArrayMesh.new()
	var verts := PackedVector2Array()
	var indices := PackedInt32Array()
	var steps := 16
	
	verts.append(Vector2.ZERO)
	
	for i in range(steps + 1):
		var a := TAU * i / steps
		verts.append(Vector2(cos(a), sin(a)) * settings.particle_radius * settings._scale)
	
	for i in range(1, steps + 1):
		indices.append(0)
		indices.append(i)
		indices.append(i + 1)
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		arrays
	)
	
	return mesh

func _draw() -> void:
	# Cache global values to avoid repeated lookups
	var scale = settings._scale
	var offset = settings._offset
	var radius = settings.particle_radius * scale
	var density_range := max_density - min_density
	
	# Inline color calculation to reduce function call overhead
	for idx in range(particle_num):
		var ratio := (particle_density_array[idx] - min_density) / density_range if density_range > 0 else 0.5
		var color := Color(0, ratio, 1 - ratio)
		draw_circle(particle_position_array[idx] * scale + offset, radius, color)

func _init_mesh() -> void:
	multi_mesh.instance_count = 0
	multi_mesh.transform_format = MultiMesh.TRANSFORM_2D
	multi_mesh.use_colors = true
	multi_mesh.instance_count = multi_mesh_instance_count
	
	multi_mesh.mesh = _create_circle_mesh()

func _update_mesh() -> void:
	if particle_num != multi_mesh_instance_count:
		multi_mesh_instance_count = particle_num
		_init_mesh()
	
	var scale = settings._scale
	var offset = settings._offset
	var radius = settings.particle_radius * scale
	var density_range := max_density - min_density
	
	for idx in range(particle_num):
		var pos = particle_position_array[idx] * scale + offset
		
		var transform := Transform2D.IDENTITY
		transform.origin = pos
		multi_mesh.set_instance_transform_2d(idx, transform)
		
		var ratio := (particle_density_array[idx] - min_density) / density_range if density_range > 0 else 0.5
		var color := Color(0, ratio, 1 - ratio)
		multi_mesh.set_instance_color(idx, color)

# TODO IMPLEMENT MEA MAX MIN DENSITY
func _draw_particles(particle_position_array: PackedVector2Array,
					particle_velocity_array: PackedVector2Array,
					particle_density_array: PackedFloat32Array,
					particle_num: int,
					max_density: float,
					min_density: float) -> void:
	self.particle_position_array = particle_position_array
	self.particle_velocity_array = particle_velocity_array
	self.particle_density_array = particle_density_array
	self.particle_num = particle_num
	self.max_density = max_density
	self.min_density = min_density
	_update_mesh()
