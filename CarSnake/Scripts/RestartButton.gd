extends Button

# [ENGINE CALLBACK]
func _ready():
	self.connect("button_down", self, "_on_restart_btn_down")

# [ENGINE SIGNAL CALLBACK]
func _on_restart_btn_down():
	var _err = get_tree().change_scene("res://Scenes/Main.tscn")
