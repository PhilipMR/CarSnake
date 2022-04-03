extends Node2D


const CAR_TAIL_SECONDS_PER_SAMPLE   = 0.1   # The frequency at which the car's position is sampled.
const CAR_TAIL_THICKNESS            = 20.0  # The line thicknes of the tail.

const DRIFT_TRACK_THICKNESS         = 2.5  # The line thickness of the drift tracks.
const DRIFT_HORIZONTAL_WHEEL_OFFSET = 17   # The horizontal offset from the car's center to the side.
const DRIFT_VERTICAL_WHEEL_OFFSET   = 20   # The vertical offset from the car's center to its rear.

const IGNORE_TAIL_COLLISION_AMOUNT  = 15   # The number of (most recent) points to ignore when checking
										   #   if the car is colliding with its own tail.
const CAR_BOX_HWIDTH                = 20.0 # The half width of the car (for testing tail collision).
const CAR_BOX_HHEIGHT               = 20.0 # The half height of the car (for testing tail collision).


onready var car               = get_parent()
var last_tail_points          = []
var last_drift_left_points    = []
var last_drift_right_points   = []
var time_till_record_position = CAR_TAIL_SECONDS_PER_SAMPLE
var car_tail_capacity         = 0 # The capacity for the samples.  ###[Initialized from Car::_ready()]
var car_tail_capacity_incr    = 0 # The capacity/tail growth rate. ###[Initialized from Car::_ready()]


# [PUBLIC]
# Sets the capacity for the tail's sample buffer.
#  The capacity is directly proportional to the tail's length.
# [capacity: int] - The new capacity
func set_tail_capacity(capacity: int):
	if capacity < car_tail_capacity:
		var diff = car_tail_capacity - capacity
		last_tail_points        = last_tail_points       .slice(diff, car_tail_capacity, false) # true?
		last_drift_left_points  = last_drift_left_points .slice(diff, car_tail_capacity, false) # true?
		last_drift_right_points = last_drift_right_points.slice(diff, car_tail_capacity, false) # true?
	car_tail_capacity = capacity
	
# [PUBLIC]
# Sets the incremental capacity for the tail's sample buffer.
#  In other words, how much the tail's length grows on pickup.
# [incr: int] - The amount by which the capacity extends on pickup.
func set_tail_incremental(incr: int):
	car_tail_capacity_incr = incr

# [PUBLIC]
# Determines whether or not a given object (box) collides with the tail.
# [pos:     Vector2] - The position of the object to test collision with.
# [hwidth:  float]   - The half-width of the object to test collision with.
# [hheight: float]   - The half-height of the object to test collision with.
# returns: bool -----> Whether or not the object collides with the tail.
func does_collide_with(pos: Vector2, hwidth: float, hheight: float):
	if last_tail_points.size() <= IGNORE_TAIL_COLLISION_AMOUNT:
		return false
	
	var tail = last_tail_points.slice(0, last_tail_points.size()-IGNORE_TAIL_COLLISION_AMOUNT)
	var box = [
		Vector2(pos.x-hwidth, pos.y-hheight),
		Vector2(pos.x-hwidth, pos.y+hheight),
		Vector2(pos.x+hwidth, pos.y+hheight),
		Vector2(pos.x+hwidth, pos.y-hheight)
	]
	var result = Geometry.intersect_polyline_with_polygon_2d(tail, box)
	return result != null and result != []


# [PUBLIC]
# Returns the most recently recorded tail points.
func get_tail_points():
	return last_tail_points


# [PUBLIC]
# Returns the most recently recorded left-wheel drifting points.
func get_left_drift_points():
	return last_drift_left_points


# [PUBLIC]
# Returns the most recently recorded left-wheel drifting points.
func get_right_drift_points():
	return last_drift_right_points


# [PUBLIC]
# Increases the length of the tail by the amount corresponding to one pick-up.
func increase_length():
	car_tail_capacity += car_tail_capacity_incr


# [ENGINE CALLBACK]
func _process(delta):
	# When starting a drift, clear the previous drift tracks.
	if car.is_drifting() and !car.was_drifting():
		last_drift_left_points.clear()
		last_drift_right_points.clear()
	
	# Wait until it's time to sample the tail again.
	time_till_record_position -= delta
	if time_till_record_position > 0:
		return
		
	# Sample and append the car's tail (and ensure it stays fixed length)
	if last_tail_points.size() > car_tail_capacity:
		last_tail_points.pop_front()
	last_tail_points.append(car.get_position())
	
	# Append to drifting tracks
	if car.is_drifting():
		var car_pos   = car.get_position()
		var car_fwd   = car.get_forward_dir()
		var car_left  = DRIFT_HORIZONTAL_WHEEL_OFFSET * car_fwd.rotated(0.5 * PI)
		var car_right = DRIFT_HORIZONTAL_WHEEL_OFFSET * car_fwd.rotated(-0.5 * PI)
		var car_back  = DRIFT_VERTICAL_WHEEL_OFFSET * -car_fwd
	
		# If turning clockwise, drift on left wheel, otherwise drift on right wheel.
		if car.is_drifting_cw():
			var left_track_point  = car_pos + car_back + car_left
			last_drift_left_points.append(left_track_point)
			last_drift_right_points.clear()
		else:
			var right_track_point = car_pos + car_back + car_right
			last_drift_right_points.append(right_track_point)
			last_drift_left_points.clear()
		
	time_till_record_position = CAR_TAIL_SECONDS_PER_SAMPLE
