extends Node
class_name SmoothingKernel

var settings: Settings
var alpha: float

func _ready():
	settings = get_parent().get_node("Settings")
	alpha = 15 / (7 * PI * settings.smoothing_length ** 2) # kernel normalization factor for 2d

func W(r: float) -> float:
	var q = r / settings.smoothing_length
	if q >= 2:
		return 0
	else:
		return alpha * ((1.0 / 6.0) * (2 - q) ** 3)
	#else:
		#return alpha * (2.0/3.0 - q**2 + (1.0/2.0)*q**3)
		

func Wgrad(r: float) -> float:
	var q = r / settings.smoothing_length
	#if q >= 2:
		#return 0.0
	#else:
		#var dq = 1e-3
		#var dW = W(q+dq) - W(q)
		#return dW/dq
	if q >= 2:
		return 0
	else:
		return alpha * (- (1.0 / 2.0) * (2 - q) ** 2)
	#else:
		#return alpha * (- 2*q + (3.0/2.0)*q**2)
