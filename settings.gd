extends Node2D
class_name Settings

@export var gravity = Vector2(0, 9.81)
@export var box_dimension = Vector2(20, 20)
@export var particle_radius: float = 0.1
@export var particle_color = Color(0.0, 0.0, 1.0, 1.0)
@export var gas_constant: float = 100.0
@export var rest_density: float = 1000.0
@export var initial_particle_num: int = 1000

@export var smoothing_length: float = 2 * particle_radius
@export var particle_mass: float = 100.0
@export var damp: float = 0.999
@export var time_step := 0.01 # delta will not be bigger than this

var _scale: float;
var _offset: Vector2;

@export var use_gpu = true

func _ready() -> void:
	var window_size = get_viewport().get_visible_rect().size
	_scale = min(window_size.x / box_dimension.x, window_size.y / box_dimension.y);
	_offset = Vector2((window_size.x - box_dimension.x * _scale) / 2, (window_size.y - box_dimension.y * _scale) / 2)
	
func _process(delta: float) -> void:
	_ready()
