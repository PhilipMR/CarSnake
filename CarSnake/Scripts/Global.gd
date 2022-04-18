extends Node

const WARMING_UP_CUP = ["WARMING UP CUP", "1_WarmingUpCup"]
const VROOM_CUP      = ["VROOM CUP",      "2_VroomCup"]
const HONK_CUP       = ["HONK CUP",       "3_HonkCup"]
onready var TRACKS_PER_CUP = [] # Track/Level files are counted at startup (in respective cup dir)

const CUPS = [WARMING_UP_CUP, VROOM_CUP, HONK_CUP]

# USER SAVE DATA
var UserData = {
	"money": 0,
	"cups_unlocked": 1,
	"cups_progress": [0, 0]
}

# Global state
var next_cup_id = 0  # Set on cup selection in main menu, read on game (Main) ready


func _ready():
	for cup in Global.CUPS:
		var cup_dir = "res://Scenes/Cups/" + cup[1]
			
		var dir = Directory.new()
		var status = dir.open(cup_dir)
		assert(status == OK)
		
		dir.list_dir_begin()
		
		var track_count = 0
		var file_name   = dir.get_next()
		while file_name != "":
			var next_track_name = "Track_" + str(track_count+1) + ".tscn"
			if file_name == next_track_name:
				track_count += 1
			file_name = dir.get_next()
		if track_count <= 0:
			print("WARNING: No tracks were found for cup \"", cup[0], "\"!")
		TRACKS_PER_CUP.append(track_count)
