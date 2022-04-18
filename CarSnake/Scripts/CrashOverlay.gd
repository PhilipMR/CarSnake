extends Control

# [ENGINE CALLBACK]
func _ready():
	$Retry .connect("button_down", self, "_on_retry_btn_down")
	$GiveUp.connect("button_down", self, "_on_giveup_btn_down")

# [ENGINE SIGNAL CALLBACK]
func _on_retry_btn_down():
	var _err = get_tree().change_scene("res://Scenes/Main.tscn")


# [ENGINE SIGNAL CALLBACK]
func _on_giveup_btn_down():
	var _err = get_tree().change_scene("res://Scenes/Menu_Main.tscn")
