extends Node2D

var arrow_length = 0.5
var resolution = 2.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for x in range(0, Global.box_dimension.x, resolution):
		for y in range(0, Global.box_dimension.y, resolution):
			pass
			#_draw_density_gradient_line(Vector2(x, y))
	queue_redraw()
	
func _draw() -> void:
	draw_line(Vector2(0,0), Vector2(100, 100), Color.WHITE)

	#
#func _draw_density_gradient_line(_position: Vector2) -> void:
	#var grad = _calculate_density_gradient(_position)
