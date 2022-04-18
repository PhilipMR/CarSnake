extends Control

export(Texture) var SeparatorTex

signal clicked

const LOCKED_CUP_TEXT    = "? ? ? ? ? ? ? ?"

const ACTIVATE_BAR_RANGE = [0.0, 723.0]
const ACTIVATE_BAR_SECS  = 0.5

var activate_bar_time = 0.0
var is_held    = false
var is_enabled = true

func _ready():
	var rect = $ActivateBar.get_rect()
	rect.size.x = ACTIVATE_BAR_RANGE[0]
	$ActivateBar.rect_size = rect.size

func _process(delta):
	if !is_held and activate_bar_time > 0:
		activate_bar_time -= delta
	elif is_held:
		activate_bar_time += delta 
		
	activate_bar_time = clamp(activate_bar_time, 0, ACTIVATE_BAR_SECS)
	var progress = activate_bar_time / ACTIVATE_BAR_SECS 
	var rect = $ActivateBar.get_rect()
	rect.size.x = lerp(ACTIVATE_BAR_RANGE[0], ACTIVATE_BAR_RANGE[1], progress)
	$ActivateBar.rect_size = rect.size

	if progress >= 1:
		emit_signal("clicked")


func _enter_tree():
	var list_index = 0
	for child in get_parent().get_children():
		if child == self:
			break
		list_index += 1
		
	if list_index >= Global.UserData.cups_progress.size():
		$ProgressBar.set_value(0)
	else:
		var num_tracks = Global.TRACKS_PER_CUP[list_index]
		$ProgressBar.set_value(Global.UserData.cups_progress[list_index])
		$ProgressBar.set_max(max(1, Global.TRACKS_PER_CUP[list_index]))
		var pb_rect = $ProgressBar.get_rect()
		if num_tracks > 0:
			var step_x = pb_rect.size.x / num_tracks
			for i in range(0, num_tracks-1):
				var sep = Sprite.new()
				sep.set_texture(SeparatorTex)
				sep.set_position(Vector2(pb_rect.position.x + step_x*(i+1), pb_rect.position.y + SeparatorTex.get_height()*0.4))
				sep.set_scale(Vector2(1.5, 1.0))
				add_child(sep)



func disable():
	$CupTitle.set_text(LOCKED_CUP_TEXT)
	$Background.set_self_modulate(Color.white.darkened(0.5))
	is_enabled = false


func set_cup_title(title):
	$CupTitle.set_text(title)


func _gui_input(event):
	if not(is_enabled):
		return
	if (event is InputEventMouseButton) and (event.button_index == BUTTON_LEFT):
		is_held = event.is_pressed()

func _on_CupTitle_gui_input(event):
	_gui_input(event)

func _on_ProgressBar_gui_input(event):
	_gui_input(event)
