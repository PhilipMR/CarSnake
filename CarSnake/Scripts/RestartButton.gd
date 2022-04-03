extends Button

func _ready():
	self.connect("button_down", self, "_on_restart_btn_down")

func _on_restart_btn_down():
	var _err = get_tree().change_scene("res://Scenes/Main.tscn")
