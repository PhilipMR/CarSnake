extends Node2D
export (PackedScene) var SmokeParticle


const SECONDS_PER_SMOKE_EMIT =  0.2 # Scales (inversely) with the car's speed

onready var car = get_parent()
var time_till_smoke_emit = SECONDS_PER_SMOKE_EMIT


# [ENGINE CALLBACK]
func _process(delta):
	if !car.is_driving():
		return
		
	# Wait until it's time to emit smoke.
	time_till_smoke_emit -= delta
	if time_till_smoke_emit > 0:
		return
		
	# Emit the smoke out the car's back.
	var dir = -car.get_forward_dir()
	var smokes_to_emit = (randi() % 2) + 1
	var tree_root = get_tree().get_root().get_child(0)
	for _i in range(0, smokes_to_emit):
		var smoke = SmokeParticle.instance()
		smoke.set_position(get_global_position())
		smoke.set_emission_dir(dir)
		tree_root.add_child(smoke)
	
	var smoke_speed_multiplier = 1.0
	if car.get_speed() > 0.0:
		smoke_speed_multiplier = car.INITIAL_MOVE_SPEED / car.get_speed()
	time_till_smoke_emit = SECONDS_PER_SMOKE_EMIT * smoke_speed_multiplier
