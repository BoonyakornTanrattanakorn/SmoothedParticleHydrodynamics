extends Node2D

var arrow_length = 20.0 # pixel
var resolution = 0.25

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()
	
func _draw() -> void:
	var x = 0
	while x <= Global.box_dimension.x:
		var y = 0
		while y <= Global.box_dimension.y:
			_draw_density_gradient_line(Vector2(x, y))	
			y += resolution
		x += resolution		

func _draw_density_gradient_line(_position: Vector2) -> void:
	pass
	#var dir = Main._calculate_density_gradient(_position)
	#if dir == Vector2.ZERO: dir = Vector2.UP
	#var from = _position * Global._scale + Global._offset
	#var to = from + dir * arrow_length 
	#draw_line(from, to, Color.WHITE)
	#draw_circle(from, arrow_length*0.1, Color.WHITE)
