extends Node2D

export (PackedScene) var SmokeParticle

const INITIAL_SPEED          = 50.0
const INITIAL_TURN_SPEED     = 50.0
const ACCELERATION_PER_WHEEL = 20.0
const TORQUE_PER_WHEEL       = 20.0 
const SECONDS_PER_SMOKE_EMIT =  0.2   # Scales (inversely) with speed
const DRIFT_TURN_THRESHOLD   = 115.0

var forward_dir          : Vector2
var speed                = INITIAL_SPEED
var turn_speed           = INITIAL_TURN_SPEED
var turn_degrees         = 0
var time_till_smoke_emit = SECONDS_PER_SMOKE_EMIT
var was_drifting         = false
var is_driving           = true
var is_turning_left      = false
var is_turning_right     = false


# [PUBLIC]
func set_turning_left(tleft):
	is_turning_left = tleft

# [PUBLIC]
func set_turning_right(tright):
	is_turning_right = tright

# [PUBLIC]	
func increase_speed():
	speed      += ACCELERATION_PER_WHEEL
	turn_speed += TORQUE_PER_WHEEL

# [PUBLIC]	
func is_within_bounds():
	var xformed_car_rect = $CarSprite.get_global_transform().xform($CarSprite.get_rect())
	return get_viewport().get_visible_rect().intersects(xformed_car_rect)

# [PUBLIC]
func stop_driving():
	is_driving = false

# [PUBLIC]
func is_drifting():
	return abs(avg_turn_rate) >= DRIFT_TURN_THRESHOLD

# [PUBLIC]
func was_drifting():
	return self.was_drifting
	
# [PUBLIC]
func is_drifting_ccw():
	return is_drifting() && (avg_turn_rate > 0)

# [PUBLIC]
func is_drifting_cw():
	return is_drifting() && (avg_turn_rate < 0)
	
# [PRIVATE]
func stop_drifting():
	avg_turn_rate = 0

# [PUBLIC]
func get_forward_dir():
	return forward_dir 


# [PRIVATE]
func emit_smoke(delta, dir):
	time_till_smoke_emit -= delta
	if time_till_smoke_emit <= 0:
		time_till_smoke_emit = SECONDS_PER_SMOKE_EMIT * (INITIAL_SPEED / speed)
		var smokes_to_emit = (randi() % 2) + 1
		for _i in range(0, smokes_to_emit):
			var tree_root = get_tree().get_root().get_child(0)
			var smoke = SmokeParticle.instance()
			smoke.set_position($SmokeEmitter.get_global_position())
			smoke.set_emission_dir(dir)
			tree_root.add_child(smoke)


# [PRIVATE]	
const TURN_RATE_AVG_RING_SIZE = 20
var avg_turn_rate        = 0.0
var prev_avg_turn_rate   = 0.0
var cumulative_turn_rate = 0.0
var turn_rate_ring_i     = 0 
func add_to_avg_turn_rate(turn_rate):
	cumulative_turn_rate += turn_rate
	turn_rate_ring_i += 1
	var alpha = turn_rate_ring_i / TURN_RATE_AVG_RING_SIZE
	var next_avg_turn_rate = cumulative_turn_rate / turn_rate_ring_i
	avg_turn_rate = lerp(prev_avg_turn_rate, next_avg_turn_rate, alpha)
	if turn_rate_ring_i >= TURN_RATE_AVG_RING_SIZE:
		prev_avg_turn_rate   = next_avg_turn_rate
		cumulative_turn_rate = 0.0
		turn_rate_ring_i     = 0


# [PUBLIC]
signal arrived_at_destination
const DRIVING_AUTOMATIC_SPEED  = 100.0
var is_driving_automatic       = false
var driving_automatic_start    : Vector2
var driving_automatic_goals    = [] # Vector2[]
var driving_automatic_goal_i   = 0
var driving_automatic_time     = 0.0
var driving_automatic_duration = 0.0
func drive_to_points(goal_points):
	is_driving_automatic     = true
	driving_automatic_start  = position
	driving_automatic_goals  = goal_points
	driving_automatic_goal_i = 0
	driving_automatic_time   = 0.0
	
	stop_drifting()
	
	var goal = driving_automatic_goals[driving_automatic_goal_i]
	var distance = driving_automatic_start.distance_to(goal)
	driving_automatic_duration = distance / DRIVING_AUTOMATIC_SPEED

# [PRIVATE]
func process_automatic_drive(delta):
	var goal = driving_automatic_goals[driving_automatic_goal_i]

	driving_automatic_time += delta
	var progress = 1.0
	if driving_automatic_duration > 0:
		progress = min(1.0, driving_automatic_time / driving_automatic_duration)
	var pos = lerp(driving_automatic_start, goal, progress)
	var dir = (pos - get_position()).normalized()
	set_position(pos)
	set_rotation(atan2(dir.y, dir.x) + 0.5*PI)
	if progress >= 1.0:
		driving_automatic_goal_i += 1
		if driving_automatic_goal_i >= driving_automatic_goals.size():		
			is_driving_automatic = false
			emit_signal("arrived_at_destination")
		else:
			driving_automatic_start  = position
			driving_automatic_time   = 0.0
			goal = driving_automatic_goals[driving_automatic_goal_i]
			var distance = driving_automatic_start.distance_to(goal)
			driving_automatic_duration = distance / DRIVING_AUTOMATIC_SPEED
			
	# Emit smoke particles out the back of the car
	emit_smoke(delta, -dir)
	

func process_controlled_drive(delta):
	# Determine rotation
	var turn_rate = 0
	if is_turning_left:
		turn_rate -= turn_speed
	if is_turning_right:
		turn_rate += turn_speed
	turn_degrees += turn_rate * delta

	# Determine average turn rate (for drifting)
	self.was_drifting = is_drifting()
	add_to_avg_turn_rate(turn_rate)

	# Apply car movement and turning
	var turn_rads = deg2rad(turn_degrees + 90)
	self.set_rotation(turn_rads - 0.5*PI)
	
	self.forward_dir = Vector2(-cos(turn_rads), -sin(turn_rads))
	self.translate(forward_dir  * speed * delta)

	# Emit smoke particles out the back of the car
	emit_smoke(delta, -forward_dir)


# [ENGINE CALLBACK]
func _process(delta):
	if !is_driving:
		return
	if self.is_driving_automatic:
		process_automatic_drive(delta)
	else:
		process_controlled_drive(delta)
