extends Control

func get_money_str():
	var txt = str(Global.UserData.money)
	var length = txt.length()
	if length > 6:
		txt = txt.insert(txt.length()-3, "'")
		txt = txt.insert(txt.length()-7, "'")
	elif length > 4:
		txt = txt.insert(txt.length()-3, "'")
	return txt

func _ready():
	$CupList.connect("cup_selected", self, "_on_cup_selected")
	$CoinIcon/CoinAmount.set_text(get_money_str())

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
