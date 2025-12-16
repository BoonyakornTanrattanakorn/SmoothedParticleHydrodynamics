extends Node
class_name SmoothingKernel

static var alpha = 15 / (7*PI*Global.smoothing_length**2) # kernel normalization factor for 2d

static func W(r : float) -> float:
	var q = r / Global.smoothing_length
	if q >= 2:
		return 0
	else:
		return alpha * ((1.0/6.0) * (2-q)**3)
	#else:
		#return alpha * (2.0/3.0 - q**2 + (1.0/2.0)*q**3)
		

static func Wgrad(r : float) -> float:
	var q = r / Global.smoothing_length
	#if q >= 2:
		#return 0.0
	#else:
		#var dq = 1e-3
		#var dW = W(q+dq) - W(q)
		#return dW/dq
	if q >= 2:
		return 0
	else:
		return alpha * (- (1.0/2.0) * (2-q)**2)
	#else:
		#return alpha * (- 2*q + (3.0/2.0)*q**2)
