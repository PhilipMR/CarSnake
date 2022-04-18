extends Control

# [ENGINE CALLBACK]
func _ready():
	var game_over = Global.hearts_remaining == 1 # Heart not taken away yet in this scene (Main) instance
	
	$Crashed.set_visible(!game_over)
	$GameOver.set_visible(game_over)
	
	if !game_over:
		$Crashed/Retry .connect("button_down",  self, "_on_retry_btn_down")
		$Crashed/GiveUp.connect("button_down",  self, "_on_return_btn_down")
	else:
		$GameOver/Return.connect("button_down", self, "_on_return_btn_down")


# [ENGINE SIGNAL CALLBACK]
func _on_retry_btn_down():
	var _err = get_tree().change_scene("res://Scenes/Main.tscn")

# [ENGINE SIGNAL CALLBACK]
func _on_return_btn_down():
	var _err = get_tree().change_scene("res://Scenes/Menu_Main.tscn")
