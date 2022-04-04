extends Node2D

signal crashed_into_tail
signal crashed_out_of_bounds

export(float) var INITIAL_SPEED_MULTIPLIER     = 1.0
export(float) var INCREMENTAL_SPEED_MULTIPLIER = 1.0
export(float) var INITIAL_TAIL_CAPACITY        = 15
export(float) var INCREMENTAL_TAIL_CAPACITY    = 7

const INITIAL_MOVE_SPEED       = 50.0  # The movement speed that the car starts out with.
const MAX_MOVE_SPEED           = 300   # The highest attainable movement speed.
const INITIAL_TURN_SPEED       = 50.0  # The turning speed that the car starts out with.
const MAX_TURN_SPEED           = 320   # The highest attainable turning speed.
const MOVE_SPEED_INC_PER_WHEEL = 20.0  # The movement speed increase per picked-up wheel. 
const TURN_SPEED_INC_PER_WHEEL = 20.0  # The turning speed increase per picked-up wheel.
const CAR_HWIDTH               = 20.0  # The car's half-width (used in tail-collision checking)
const CAR_HHEIGHT              = 20.0  # The car's half-height (used in tail-collision checking)
const DRIFT_TURN_THRESHOLD     = 115.0 # The minimal average turning speed required to drift.  



var forward_dir          : Vector2
onready var speed        = INITIAL_MOVE_SPEED * INITIAL_SPEED_MULTIPLIER
onready var turn_speed   = INITIAL_TURN_SPEED * INITIAL_SPEED_MULTIPLIER
var turn_degrees         = 0.0

var was_drifting         = false
var is_driving           = true
var is_turning_left      = false
var is_turning_right     = false

# [ENGINE CALLBACK]
func _ready():
	$CarTail.set_tail_capacity(INITIAL_TAIL_CAPACITY)
	$CarTail.set_tail_incremental(INCREMENTAL_TAIL_CAPACITY)

# [PUBLIC]
func get_speed():
	return speed

# [PUBLIC]
func get_tail_points():
	return $CarTail.get_tail_points()
	
# [PUBLIC]
func get_left_drift_points():
	return $CarTail.get_left_drift_points()
	
# [PUBLIC]
func get_right_drift_points():
	return $CarTail.get_right_drift_points()

# [PUBLIC]
func set_turning_left(tleft):
	is_turning_left = tleft

# [PUBLIC]
func set_turning_right(tright):
	is_turning_right = tright

# [PUBLIC]	
func pickup_wheel():
	speed += MOVE_SPEED_INC_PER_WHEEL * INCREMENTAL_SPEED_MULTIPLIER
	speed = min(MAX_MOVE_SPEED, speed)
	
	turn_speed += TURN_SPEED_INC_PER_WHEEL * INCREMENTAL_SPEED_MULTIPLIER
	turn_speed = min(MAX_TURN_SPEED, turn_speed)
	
	$CarTail.increase_length()

# [PUBLIC]
func is_driving():
	return self.is_driving

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
	stop_drifting()
	
	is_driving_automatic     = true
	driving_automatic_start  = position
	driving_automatic_goals  = goal_points
	driving_automatic_goal_i = 0
	driving_automatic_time   = 0.0
	
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
	self.forward_dir = (pos - get_position()).normalized()
	set_position(pos)
	set_rotation(atan2(forward_dir.y, forward_dir.x) + 0.5*PI)
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
	self.translate(forward_dir * speed * delta)


# [ENGINE CALLBACK]
func _process(delta):
	if !is_driving():
		return
		
	var xformed_car_rect = $CarSprite.get_global_transform().xform($CarSprite.get_rect())
	var is_out_of_bounds = !get_viewport().get_visible_rect().intersects(xformed_car_rect)
	
	if $CarTail.does_collide_with(get_position(), CAR_HWIDTH, CAR_HHEIGHT):
		emit_signal("crashed_into_tail")
	if is_out_of_bounds:
		emit_signal("crashed_out_of_bounds")
		
	if self.is_driving_automatic:
		process_automatic_drive(delta)
	else:
		process_controlled_drive(delta)
