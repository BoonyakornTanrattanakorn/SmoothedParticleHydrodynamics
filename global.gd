extends Node2D

var gravity = Vector2(0, 9.81)
var box_dimension = Vector2(20, 20)
var particle_radius : float = 0.1
var particle_color = Color(0.0, 0.0, 1.0, 1.0)
var gas_constant : float = 10.0
var rest_density : float = 1000.0

var smoothing_length : float = 2 * particle_radius
var particle_mass : float = 1.0
var damp: float = 0.99
var time_step := 0.01 # delta will not be bigger than this

var _scale: float;
var _offset: Vector2;

var use_gpu = true

func _ready() -> void:
	var window_size = get_viewport().get_visible_rect().size
	_scale = min(window_size.x/box_dimension.x, window_size.y/box_dimension.y);
	_offset = Vector2((window_size.x - box_dimension.x * _scale)/2, (window_size.y - box_dimension.y * _scale)/2)
