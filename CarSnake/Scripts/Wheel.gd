extends Node2D

signal hit_by_car

const SHINE_LAYER_1_ROT_SPEED = +(1.0 /  8.0) * PI
const SHINE_LAYER_2_ROT_SPEED = -(1.0 / 16.0) * PI
const FADEOUT_SECS = 0.25

const SHINE_BG_SCALE_RANGE       = [0.0, 0.35]
const SHINE_BG_SCALE_PERIOD_SECS = 1.0

var is_scaling_up     = false
var scaling_time      = 0.0

var is_disappearing   = false
var disappearing_time = 0.0

# [PUBLIC]
func set_collision_enabled(enabled):
	$Area2D/CollisionShape2D.set_deferred("disabled", !enabled)

# [ENGINE CALLBACK]
func _ready():
	$Area2D.connect("body_entered", self, "_on_Area2D_body_entered")
	$ShineLayer1.rotate(rand_range(0, 2*PI))
	$ShineLayer2.rotate(rand_range(0, 2*PI))

# [ENGINE CALLBACK]
func _process(delta):
	# Rotate "shiny rays"
	$ShineLayer1.rotate(SHINE_LAYER_1_ROT_SPEED * delta)
	$ShineLayer2.rotate(SHINE_LAYER_2_ROT_SPEED * delta)
	
	# Pulse scale background
	scaling_time += delta
	var scl_progress = min(1.0, scaling_time / SHINE_BG_SCALE_PERIOD_SECS)
	var from = 0
	var to   = 0
	if is_scaling_up:
		from = SHINE_BG_SCALE_RANGE[0]
		to   = SHINE_BG_SCALE_RANGE[1]
	else:
		from = SHINE_BG_SCALE_RANGE[1]
		to   = SHINE_BG_SCALE_RANGE[0] 
	var scl = lerp(from, to, scl_progress)
	$ShineBg.set_scale(scl * Vector2.ONE)
	if scl_progress >= 1.0:
		is_scaling_up = !is_scaling_up
		scaling_time = 0
	
	# Fade out
	if is_disappearing:
		disappearing_time += delta
		var fade_progress = min(1.0, disappearing_time / FADEOUT_SECS)
		var alpha = lerp(1.0, 0.0, fade_progress)
		set_modulate(Color(1, 1, 1, alpha))
		if fade_progress >= 1.0:
			queue_free()	
	
	
# [ENGINE SIGNAL CALLBACK]
func _on_Area2D_body_entered(_body):
	emit_signal("hit_by_car")
	
	# Restore the visibility/enabledness after everything but 
	#  the "next active wheel" becomes active, so that the fade-out becomes visible.
	set_visible(true)
	set_process(true)
	is_disappearing = true
