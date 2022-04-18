extends Control

func _ready():
	$CupList.connect("cup_selected", self, "_on_cup_selected")

func _on_cup_selected(cupname):
	Global.next_cup_id = -1
	for i in range(0, Global.CUPS.size()):
		if Global.CUPS[i][0] == cupname:
			Global.next_cup_id = i
			break
	assert(Global.next_cup_id != -1)
	get_tree().change_scene("res://Scenes/Main.tscn")


func _on_Back_pressed():
	get_tree().change_scene("res://Scenes/Menu_Start.tscn")
