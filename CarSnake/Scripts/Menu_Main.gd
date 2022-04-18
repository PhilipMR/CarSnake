extends Control

func _on_cup_selected(cupname):
		get_tree().change_scene("res://Scenes/Main.tscn")

func _ready():
	$CupList.connect("cup_selected", self, "_on_cup_selected")

func _on_Back_pressed():
	get_tree().change_scene("res://Scenes/Menu_Start.tscn")
