extends ColorRect

const ONE_WAY_TRANSITION_SECS = 1.0
const MAX_DARKENING           = 0.5

onready var initial_color = get_frame_color()
var current_time  = 0.0
var alpha         = 0.0
var direction     = 1

func _process(delta):
	alpha += direction * delta / ONE_WAY_TRANSITION_SECS
	alpha = clamp(alpha, 0, 1)
	if alpha <= 0 or alpha >= 1:
		direction *= -1
	
	set_frame_color(initial_color.darkened(alpha * MAX_DARKENING))
	pass