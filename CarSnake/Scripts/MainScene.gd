extends Node2D


const CAR_TAIL_SECONDS_PER_SAMPLE  = 0.1  # The tail's resolution
const CAR_TAIL_INITIAL_CAPACITY    = 15   # The capacity for the samples 
const CAR_TAIL_CAPACITY_PER_WHEEL  = 7    # The capacity/tail growth rate
const CAR_TAIL_THICKNESS           = 20.0 
# ==> tail_length = distance travelled in (CAR_TAIL_INITIAL_CAPACITY * CAR_TAIL_SECONDS_PER_SAMPLE)


const DRIFT_TRACK_THICKNESS = 2.5

# The points the car will drive to automatically after collecting
#  all the wheels.
const OUTRO_DRIVE_POINTS = [Vector2(510, 100), Vector2(510, -50)]

# The offset from the car's origin to the point where the drift starts
const WHEEL_DRIFT_VERTICAL_OFFSET   = 20
const WHEEL_DRIFT_HORIZONTAL_OFFSET = 17

var time_till_register_point = 0
var car_track_capacity       = CAR_TAIL_INITIAL_CAPACITY
var last_car_points          = []

var next_wheel_idx = 0

var has_crashed  = false
var has_finished = false
func crash():
	if has_crashed or has_finished:
		return
	has_crashed = true
	print("CRASH")
	$Car.stop_driving()
	$CrashOverlay.set_visible(true)


func finish():
	if has_crashed or has_finished:
		return 
	has_finished = true 
	print("FINISH!")
	$Car.connect("arrived_at_destination", self, "_on_car_outro_complete")
	$Car.drive_to_points(OUTRO_DRIVE_POINTS)
	
func _on_car_outro_complete():
	$Car.stop_driving()
	$FinishOverlay.set_visible(true)

func reveal_next_wheel():
	next_wheel_idx += 1
	
	var next_wheel_name = "Wheel"
	if next_wheel_idx > 1:
		next_wheel_name += str(next_wheel_idx)
	
	for child in self.get_children():
		if not(child.get_name().begins_with("Wheel")):
			continue
		var is_next = child.get_name() == next_wheel_name
		child.set_visible(is_next)
		child.set_process(is_next)
		child.set_car_collision_enabled(is_next)
		
	if find_node(next_wheel_name) == null:
		print("Found all the wheels!")
		finish()
	else:
		print("Revealing " + next_wheel_name)


func _ready():
	for child in self.get_children():
		if child.get_name().begins_with("Wheel"):
			child.connect("hit_by_car", self, "_on_wheel_collected")

	for child in self.get_children():
		if child.get_name().begins_with("Warning"):
			var anim_player = child.get_node("AnimationPlayer")
			anim_player.get_animation("BoundsWarning").set_loop(true)
			
			var area = child.get_node("Area2D")
			area.connect("body_entered", self, "_on_warning_entered", [child])
			area.connect("body_exited", self, "_on_warning_exited", [child])
			
	for child in self.get_children():
		if child.get_name().begins_with("SolidBlock"):
			child.connect("hit_by_car", self, "_on_solid_block_collision")
	
	reveal_next_wheel()
	
	
func _on_wheel_collected():
	$Car.increase_speed()
	car_track_capacity += CAR_TAIL_CAPACITY_PER_WHEEL
	reveal_next_wheel()
	
func _on_solid_block_collision():
	crash()
	
	
func _on_warning_entered(_body, warn):
	print("WARNING ENTERED")
	warn.get_node("AnimationPlayer").play("BoundsWarning")
	
func _on_warning_exited(_body, warn):
	print("WARNING EXITED")
	warn.get_node("AnimationPlayer").seek(0, true)
	warn.get_node("AnimationPlayer").stop()
	
	

# How many of the last recorded points to ignore to avoid self-collision
const CAR_TAIL_BACK   = 1.0 / CAR_TAIL_SECONDS_PER_SAMPLE
const CAR_BOX_HWIDTH  = 20.0
const CAR_BOX_HHEIGHT = 20.0

func does_car_collide_with_track():
	if last_car_points.size() <= CAR_TAIL_BACK:
		return false
		
	var tail = last_car_points.slice(0, last_car_points.size()-CAR_TAIL_BACK)
	var car_pos = $Car.get_position()
	var car_box = [
		Vector2(car_pos.x-CAR_BOX_HWIDTH, car_pos.y-CAR_BOX_HHEIGHT),
		Vector2(car_pos.x-CAR_BOX_HWIDTH, car_pos.y+CAR_BOX_HHEIGHT),
		Vector2(car_pos.x+CAR_BOX_HWIDTH, car_pos.y+CAR_BOX_HHEIGHT),
		Vector2(car_pos.x+CAR_BOX_HWIDTH, car_pos.y-CAR_BOX_HHEIGHT)
	]
	var result = Geometry.intersect_polyline_with_polygon_2d(tail, car_box)
	return result != null and result != []

var last_drifting_left_track_points = []
var last_drifting_right_track_points = []
func _draw():
	if last_car_points.size() < 2:
		return
		
	var colors = []
	for i in range(0, last_car_points.size()):
		var r = 1#randf()
		var g = 0#randf()
		var b = 0#randf()
		var a = max(0.2, (i+1.0)/last_car_points.size())
		colors.append(Color(r, g, b, a))
	draw_polyline_colors(last_car_points, colors, CAR_TAIL_THICKNESS, true)
	
	if (last_drifting_left_track_points.size() >= 2):
		draw_polyline(last_drifting_left_track_points,  Color.black, DRIFT_TRACK_THICKNESS, true)
	if (last_drifting_right_track_points.size() >= 2):
		draw_polyline(last_drifting_right_track_points, Color.black, DRIFT_TRACK_THICKNESS, true)

func _process(delta):
	if $Car.is_drifting():
		if !$Car.was_drifting():
			last_drifting_left_track_points.clear()
			last_drifting_right_track_points.clear()
			
	time_till_register_point -= delta
	if time_till_register_point <= 0:
		if last_car_points.size() > car_track_capacity:
			last_car_points.pop_front()
		last_car_points.append($Car.get_position())
		
		# Append to drifting tracks
		if $Car.is_drifting():
			var car_pos   = $Car.get_position()
			var car_fwd   = $Car.get_forward_dir()
			var car_left  = WHEEL_DRIFT_HORIZONTAL_OFFSET * car_fwd.rotated(0.5 * PI)
			var car_right = WHEEL_DRIFT_HORIZONTAL_OFFSET * car_fwd.rotated(-0.5 * PI)
			var car_back  = WHEEL_DRIFT_VERTICAL_OFFSET * -car_fwd
			var left_track_point  = car_pos + car_back + car_left
			var right_track_point = car_pos + car_back + car_right
			if $Car.is_drifting_cw():
				last_drifting_left_track_points.append(left_track_point)
				last_drifting_right_track_points.clear()
			else:
				last_drifting_right_track_points.append(right_track_point)
				last_drifting_left_track_points.clear()
			
		update() # Tell engine to call _draw
		time_till_register_point = CAR_TAIL_SECONDS_PER_SAMPLE
		
	if does_car_collide_with_track() or !$Car.is_within_bounds():
		crash()
		
	if $Car.is_drifting():
		if !$Car.was_drifting():
			print("START DRIFT ", $Car.avg_turn_rate)
	else:
		if $Car.was_drifting():
			print("STOP DRIFT!")

func _input(event):
	if event.is_action_pressed("CarTurnLeft"):
		$Car.set_turning_left(true)
	elif event.is_action_released("CarTurnLeft"):
		$Car.set_turning_left(false)
	
	if event.is_action_pressed("CarTurnRight"):
		$Car.set_turning_right(true)
	if event.is_action_released("CarTurnRight"):
		$Car.set_turning_right(false)
