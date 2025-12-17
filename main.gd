extends Node2D

var rng = RandomNumberGenerator.new()

var particle_position_array: PackedVector2Array = []
var particle_velocity_array: PackedVector2Array = []
var initial_particle_num = 0

var particle_num = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(initial_particle_num):
		_add_particle(Vector2(rng.randf_range(0, Global.box_dimension.x),
							  rng.randf_range(0, Global.box_dimension.y)))

func _add_particle(_position: Vector2) -> void:
	particle_position_array.append(_position)
	particle_velocity_array.append(Vector2.ZERO)
	particle_num += 1

func _input(event: InputEvent):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_add_particle((event.position - Global._offset) / Global._scale)

func _update_physics(delta: float) -> void:
	if particle_num == 0: return
	# Calculate particles density
	var particle_density_array := Density._calculate_from_position_array(particle_position_array)
	# Calculate pressure force
	var pressure_force_array = PressureForce._calculate_array(particle_position_array, particle_density_array)
	for p_i in range(pressure_force_array.size()):
		particle_velocity_array[p_i] += (pressure_force_array[p_i] / particle_density_array[p_i]) * delta
	# Calculate particle position
	for particle_index in range(particle_num):
		particle_velocity_array[particle_index] += Global.gravity * delta;
		particle_position_array[particle_index] += particle_velocity_array[particle_index] * delta
		particle_velocity_array[particle_index] *= Global.damp
	_bounding_box_collision()
	if $Particles != null:
		$Particles._draw_particles(particle_position_array, particle_velocity_array, particle_density_array, particle_num)
	else:
		push_error("Particles is null!")

func _update_labels(physics_time: float) -> void:
	if $InfoLabel != null:
		$InfoLabel.text = "Particles: " + str(particle_num) + "\n" + \
						  "Physics Time: " + str(int(physics_time)) + " ms\n"
	else:
		push_error("InfoLabel is null!")
					
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var start_time = Time.get_ticks_msec()
	var t = min(delta, Global.time_step)
	_update_physics(t)
	var end_time = Time.get_ticks_msec()
	_update_labels(end_time-start_time)

func _calculate_density_gradient(_position: Vector2) -> Vector2:
	const delta = 1e-6
	var origin = Density._at_position(_position, particle_position_array)
	var dx = Density._at_position(_position + Vector2.RIGHT * delta, particle_position_array) - origin
	var dy = Density._at_position(_position + Vector2.UP * delta, particle_position_array) - origin
	var dir = Vector2(-dx, dy)
	return Vector2.ZERO if dir == Vector2.ZERO else dir / dir.length()

func _bounding_box_collision() -> void:
	for idx in range(particle_num):
		if (particle_position_array[idx].x > Global.box_dimension.x - Global.particle_radius):
			particle_position_array[idx].x = Global.box_dimension.x - Global.particle_radius;
			particle_velocity_array[idx].x *= -Global.damp;
		elif (particle_position_array[idx].x < Global.particle_radius):
			particle_position_array[idx].x = Global.particle_radius;
			particle_velocity_array[idx].x *= -Global.damp;
		if (particle_position_array[idx].y > Global.box_dimension.y - Global.particle_radius):
			particle_position_array[idx].y = Global.box_dimension.y - Global.particle_radius;
			particle_velocity_array[idx].y *= -Global.damp;
		elif (particle_position_array[idx].y < Global.particle_radius):
			particle_position_array[idx].y = Global.particle_radius;
			particle_velocity_array[idx].y *= -Global.damp;
