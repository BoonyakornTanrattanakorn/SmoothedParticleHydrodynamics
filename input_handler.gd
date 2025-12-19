extends Node
class_name InputHandler

var particle_container: ParticleContainer
var settings: Settings

enum ClickMode {ADD_PARTICLE, FORCE_PULL, FORCE_PUSH}
var click_mode := ClickMode.ADD_PARTICLE

func _ready() -> void:
	particle_container = get_parent().get_node("ParticleContainer")
	settings = get_parent().get_node("Settings")
	

func _input(event: InputEvent):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if click_mode == ClickMode.ADD_PARTICLE:
			particle_container._add_particle((event.position - settings._offset) / settings._scale)
		elif click_mode == ClickMode.FORCE_PULL:
			print("not implemented")
		elif click_mode == ClickMode.FORCE_PUSH:
			print("note implemented")
