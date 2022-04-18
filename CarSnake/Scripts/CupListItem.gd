extends Control

export(Texture) var SeparatorTex

signal clicked

const LOCKED_CUP_TEXT = "? ? ? ? ? ? ? ?"

var is_enabled = true

func _enter_tree():
	var list_index = 0
	for child in get_parent().get_children():
		if child == self:
			break
		list_index += 1
	if list_index >= Global.UserData.cups_progress.size():
		$ProgressBar.set_value(0)
	else:
		$ProgressBar.set_value(Global.UserData.cups_progress[list_index])
		$ProgressBar.set_max(Global.TRACKS_PER_CUP[list_index])
		var pb_rect = $ProgressBar.get_rect()
		var num_tracks = Global.TRACKS_PER_CUP[list_index]
		var step_x = pb_rect.size.x / num_tracks
		for i in range(0, num_tracks-1):
			var sep = Sprite.new()
			sep.set_texture(SeparatorTex)
			sep.set_position(Vector2(pb_rect.position.x + step_x*(i+1), pb_rect.position.y + SeparatorTex.get_height()*0.4))
			sep.set_scale(Vector2(1.5, 1.0))
			add_child(sep)


func _gui_input(event):
	if not(is_enabled):
		return
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_LEFT:
				emit_signal("clicked")
				


func disable():
	$CupTitle.set_text(LOCKED_CUP_TEXT)
	$Background.set_self_modulate(Color.white.darkened(0.5))
	is_enabled = false


func set_cup_title(title):
	$CupTitle.set_text(title)
