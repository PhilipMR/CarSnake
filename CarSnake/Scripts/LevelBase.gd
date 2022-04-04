extends Node2D

signal level_completed
signal level_failed

const       OUTRO_DRIVE_POINTS  = [Vector2(510, 100), Vector2(510, -50)]    # Points to auto-drive to after collecting all wheels.
onready var SECONDS_PER_REDRAW  = $Car/CarTail.CAR_TAIL_SECONDS_PER_SAMPLE  # The tail/drfit redraw frequency.
onready var CAR_TAIL_THICKNESS  = $Car/CarTail.CAR_TAIL_THICKNESS           # The thickness of the tail lines.
onready var CAR_DRIFT_THICKNESS = $Car/CarTail.DRIFT_TRACK_THICKNESS        # The thickness of the drift lines.
const       CAR_TAIL_COLOR      = Color(1, 0, 0)                            # The color of the car's tail.

var next_wheel_idx                  = 0
var game_over                       = false
onready var time_till_redraw_tracks = SECONDS_PER_REDRAW


# [ENGINE CALLBACK]
func _ready():
	# Connect all wheel-car collision signals.
	for child in self.get_children():
		if child.get_name().begins_with("Wheel"):
			child.connect("hit_by_car", self, "_on_wheel_collected")

	# Connect all warning-car collision signals.
	for child in self.get_children():
		if child.get_name().begins_with("Warning"):
			var anim_player = child.get_node("AnimationPlayer")
			anim_player.get_animation("BoundsWarning").set_loop(true)
			
			var area = child.get_node("Area2D")
			area.connect("body_entered", self, "_on_warning_entered", [child])
			area.connect("body_exited",  self, "_on_warning_exited", [child])
			
	# Connect all block-car collision signals.
	for child in self.get_children():
		if child.get_name().begins_with("SolidBlock"):
			child.connect("hit_by_car", self, "_on_crashed", ["block"])
	
	# Connect the car's crash signals.
	$Car.connect("crashed_into_tail",     self, "_on_crashed", ["tail"])
	$Car.connect("crashed_out_of_bounds", self, "_on_crashed", ["bounds"])
	
	# Start the game by revealing the first wheel.
	reveal_next_wheel()
	
	
# [PRIVATE]
func reveal_next_wheel():
	# Determine the name of the next wheel to obtain.
	var next_wheel_name = "Wheel"
	next_wheel_idx += 1
	if next_wheel_idx > 1:
		next_wheel_name += str(next_wheel_idx)
	
	# Disable/enable the visuals and physics of each wheel depending on if
	#   it is the one that should be obtained next.
	for child in self.get_children():
		if not(child.get_name().begins_with("Wheel")):
			continue
		var is_next = child.get_name() == next_wheel_name
		child.set_visible(is_next)
		child.set_process(is_next)
		child.set_collision_enabled(is_next)
		
	# If the "next" wheel doesn't exist, the level is succesfully finished.
	if find_node(next_wheel_name) == null:
		finish()


# [PRIVATE]
func crash():
	if game_over:
		return
	game_over = true
	$Car.stop_driving()
	emit_signal("level_failed")


# [PRIVATE]
func finish():
	if game_over:
		return 
	game_over = true 
	$Car.connect("arrived_at_destination", self, "_on_car_outro_complete")
	$Car.drive_to_points(OUTRO_DRIVE_POINTS)
	
	
# [ENGINE SIGNAL CALLBACK]
func _on_car_outro_complete():
	$Car.stop_driving()
	emit_signal("level_completed")
	
	
# [ENGINE SIGNAL CALLBACK]
func _on_crashed(how):
	print("Crashed against ", how)
	crash()
	
	
# [ENGINE SIGNAL CALLBACK]
func _on_wheel_collected():
	$Car.pickup_wheel()
	reveal_next_wheel()
	
	
# [ENGINE SIGNAL CALLBACK]
func _on_warning_entered(_body, warn):
	warn.get_node("AnimationPlayer").play("BoundsWarning")
	
	
# [ENGINE SIGNAL CALLBACK]
func _on_warning_exited(_body, warn):
	warn.get_node("AnimationPlayer").seek(0, true)
	warn.get_node("AnimationPlayer").stop()


# [ENGINE CALLBACK]
func _draw():
	# Nothing to do until tail exists.
	var last_car_points = $Car.get_tail_points()
	if last_car_points.size() < 2:
		return
		
	# Draw the car's tail.
	var colors = []
	for i in range(0, last_car_points.size()):
		var color = Color(CAR_TAIL_COLOR)
		color.a = max(0.2, (i+1.0)/last_car_points.size())
		colors.append(color)
	draw_polyline_colors(last_car_points, colors, CAR_TAIL_THICKNESS, true)
	
	# Draw left drifting tracks (if any).
	var last_left_drift_points  = $Car.get_left_drift_points()
	if (last_left_drift_points.size() >= 2):
		draw_polyline(last_left_drift_points,  Color.black, CAR_DRIFT_THICKNESS, true)
		
	# Draw right drifting tracks (if any).
	var last_right_drift_points = $Car.get_right_drift_points()
	if (last_right_drift_points.size() >= 2):
		draw_polyline(last_right_drift_points, Color.black, CAR_DRIFT_THICKNESS, true)


# [ENGINE CALLBACK]
func _process(delta):
	# Wait until it's time to redraw.
	time_till_redraw_tracks -= delta
	if time_till_redraw_tracks > 0:
		return
	
	# Redraw.
	update()
	time_till_redraw_tracks = SECONDS_PER_REDRAW


# [ENGINE CALLBACK]
func _input(event):
	if event.is_action_pressed("CarTurnLeft"):
		$Car.set_turning_left(true)
	elif event.is_action_released("CarTurnLeft"):
		$Car.set_turning_left(false)
	
	if event.is_action_pressed("CarTurnRight"):
		$Car.set_turning_right(true)
	if event.is_action_released("CarTurnRight"):
		$Car.set_turning_right(false)
