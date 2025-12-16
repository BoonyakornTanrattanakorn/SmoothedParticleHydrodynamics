class_name Particle
extends Node2D

const this : PackedScene = preload("res://particle.tscn")

var color: Color;
var density: float;
var _velocity;
var _position;

static func new_particle(_velocity: Vector2 = Vector2(0, 0), _position: Vector2 = Vector2(0, 0)) -> Particle:
	var p: Particle = this.instantiate()
	p._velocity = _velocity
	p._position = _position
	p.color = Global.particle_color
	return p

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _draw() -> void:
	draw_circle(_position * Global._scale + Global._offset, Global.particle_radius * Global._scale, color)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# _update_physics(delta)
	_update_color()
	queue_redraw()

func _update_physics(delta: float) -> void:
	#var acceleration = Global.gravity;
	#_velocity += acceleration * delta
	#_position += _velocity * delta;

	_bounding_box_collision();

func _update_color() -> void:
	var ratio = (density - Global.min_density) / (Global.max_density - Global.min_density)
	color.b = 1 - ratio
	color.g = ratio

func _bounding_box_collision() -> void:
	if(_position.x > Global.box_dimension.x - Global.particle_radius):
		_position.x = Global.box_dimension.x - Global.particle_radius;
		_velocity.x *= -Global.damp;
	elif(_position.x < Global.particle_radius):
		_position.x = Global.particle_radius;
		_velocity.x *= -Global.damp;
	if(_position.y > Global.box_dimension.y - Global.particle_radius):
		_position.y = Global.box_dimension.y - Global.particle_radius;
		_velocity.y *= -Global.damp;
	elif(_position.y < Global.particle_radius):
		_position.y = Global.particle_radius;
		_velocity.y *= -Global.damp;
		
