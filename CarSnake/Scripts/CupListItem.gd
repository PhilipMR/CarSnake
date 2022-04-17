extends Control

const LOCKED_CUP_TEXT = "? ? ? ? ? ? ? ?"

func disable():
	$Background/CupTitle.set_text(LOCKED_CUP_TEXT)
	$Background.set_self_modulate(Color.white.darkened(0.5))

func set_cup_title(title):
	$Background/CupTitle.set_text(title)
