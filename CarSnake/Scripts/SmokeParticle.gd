extends Node2D

const SCALE_RANGE     = [ 0,    2.0]
const SPEED_RANGE     = [10.0, 60.0]
const AMPLITUDE_RANGE = [ 1.0, 10.0]
const OFFSET_RANGE    = [ 0.0, 10.0]
const LIFETIME_SECS   = 1.0

var progress	   = 0.0
var initial_scale  = rand_range(SCALE_RANGE[0],     SCALE_RANGE[1]   /2.0)
var emission_speed = rand_range(SPEED_RANGE[0],     SPEED_RANGE[1]   /2.0)
var wave_amplitude = rand_range(AMPLITUDE_RANGE[0], AMPLITUDE_RANGE[1]/2.0)

var emission_dir   : Vector2


# [PUBLIC]
func set_emission_dir(dir):
	emission_dir = dir.normalized()


# [ENGINE CALLBACK]
func _ready():
	$SmokeSprite.set_self_modulate(Color.transparent)
	$SmokeSprite.set_rotation(rand_range(0, 2*PI))
	
	var offset_x = rand_range(OFFSET_RANGE[0], OFFSET_RANGE[1])
	var offset_y = rand_range(OFFSET_RANGE[0], OFFSET_RANGE[1])
	translate(Vector2(offset_x, offset_y))


# [ENGINE CALLBACK]
func _process(delta):
	progress += delta / LIFETIME_SECS
	if progress >= 1:
		self.queue_free()
		
	var alpha = sin(progress*PI)
	$SmokeSprite.set_self_modulate(Color(1, 1, 1, alpha))
	
	var new_scale = lerp(initial_scale, SCALE_RANGE[1], progress)
	$SmokeSprite.set_scale(Vector2(1,1) * new_scale)
	
	var emission_side = emission_dir.rotated(0.5 * PI).normalized()
	emission_side *= sin(progress * 2 * PI) * wave_amplitude
	var emission = emission_dir * emission_speed + emission_side 
	translate(emission * delta)
