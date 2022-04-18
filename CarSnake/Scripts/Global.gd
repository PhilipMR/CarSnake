extends Node

# GLOBAL LEVEL HIERARCHY / CUPS
const CUPS = [\
	["WARMING UP CUP", "1_WarmingUpCup"],		\
	["VROOM CUP",      "2_VroomCup"], 			\
	["HONK CUP",       "3_HonkCup"]				\
]
onready var TRACKS_PER_CUP = [] # Track/Level files are counted at startup (in respective cup dir)


# USER SAVE DATA
const MAX_MONEY = 9999999
var UserData = {
	"money": 1000000,
	"cups_unlocked": 1,
	"cups_progress": [0, 0]
}


# SHARED SCENE/INIT STATE
const MAX_HEARTS = 3
var hearts_remaining = MAX_HEARTS
var next_cup_id      = 0  # Set on cup selection in main menu, read on game (Main) ready


# GLOBAL INITIALIZATION
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
