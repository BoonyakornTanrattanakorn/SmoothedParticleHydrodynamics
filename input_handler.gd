extends Node
class_name InputHandler

var particle_container: ParticleContainer
var settings: Settings
var external_force: ExternalForce

enum ClickMode {ADD_PARTICLE, FORCE_PULL, FORCE_PUSH}
@export var click_mode := ClickMode.ADD_PARTICLE

var mouse_position: Vector2

func _ready() -> void:
	particle_container = get_parent().get_node("ParticleContainer")
	settings = get_parent().get_node("Settings")
	external_force = get_parent().get_node("ExternalForce")
	

func _input(event: InputEvent):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		mouse_position = (event.position - settings._offset) / settings._scale
		if click_mode == ClickMode.ADD_PARTICLE:
			particle_container._add_particle(mouse_position)
		elif click_mode == ClickMode.FORCE_PULL:
			external_force.force = external_force.Force.PULL
		elif click_mode == ClickMode.FORCE_PUSH:
			external_force.force = external_force.Force.PUSH
