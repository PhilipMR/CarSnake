extends Control

signal clicked

const LOCKED_CUP_TEXT = "? ? ? ? ? ? ? ?"

const SWITCH_TIME_SECS     = 1.0
const SWITCH_DURATION_SECS = 1.0

var from = 0
var next_goal = 0
var is_switching = false
var time_till_switch = SWITCH_TIME_SECS
var time_switching = 0

func _ready():
	randomize()
	$ProgressBar.set_value(rand_range($ProgressBar.get_min(), $ProgressBar.get_max()))

func _process(delta):
	if not(is_switching):
		time_till_switch -= delta
		if time_till_switch <= 0:
			from = $ProgressBar.get_value()
			next_goal = rand_range($ProgressBar.get_min(), $ProgressBar.get_max())
			is_switching = true
			time_switching = 0
	else:
		time_switching += delta
		var progress = min(1, time_switching / SWITCH_DURATION_SECS)
		$ProgressBar.set_value(lerp(from, next_goal, progress))
		if progress >= 1:
			is_switching = false
			time_till_switch = SWITCH_TIME_SECS

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_LEFT:
				emit_signal("clicked")
				


func disable():
	$CupTitle.set_text(LOCKED_CUP_TEXT)
	$Background.set_self_modulate(Color.white.darkened(0.5))

func set_cup_title(title):
	$CupTitle.set_text(title)
