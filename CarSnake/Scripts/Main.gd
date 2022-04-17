extends Node2D

const WARMING_UP_CUP = ["WARMING UP CUP", "1_WarmingUpCup"]
const VROOM_CUP      = ["VROOM CUP",      "2_VroomCup"]
onready var TRACKS_PER_CUP = [] # Track/Level files are counted at startup (in respective cup dir)

const CUPS = [WARMING_UP_CUP, VROOM_CUP]

# USER SAVE DATA
var UserData = {
	"money": 0,
	"cups_unlocked": 1,
	"cups_progress": [0, 0]
}

var current_cup_idx    = 0
var current_track_idx  = 0
var current_cup_tracks = []

func begin_next_track():
	current_track_idx += 1
	assert(current_cup_tracks.size() > current_track_idx)
	
	var track_class = load(current_cup_tracks[current_track_idx])
	var track = track_class.instance()
	track.connect("level_completed", self, "_on_track_completed", [track])
	track.connect("level_failed",    self, "_on_track_failed")
	add_child(track)
	
	
func _on_track_completed(track):
	var tracks_completed = current_track_idx+1
	while UserData.cups_progress.size() <= current_cup_idx:
		UserData.cups_progress.append(0)
	if tracks_completed > UserData.cups_progress[current_cup_idx]:
		UserData.cups_progress[current_cup_idx] = tracks_completed
	
	var completed_cup = ((current_track_idx+1) == current_cup_tracks.size())
	if completed_cup:
		$UI/FinishOverlay.set_visible(true)
		if UserData.cups_unlocked <= current_cup_idx:
			UserData.cups_unlocked = current_cup_idx+1
	else:
		for obj in $_TempObjects.get_children():
			obj.queue_free()
		track.queue_free()
		begin_next_track()
	
func _on_track_failed():
	$UI/CrashOverlay.set_visible(true)
	
	
func begin_cup(cup_idx):
	var cup_dir = "res://Scenes/Cups/" + CUPS[cup_idx][1]	
	current_cup_tracks.clear()
	for i in range(1, TRACKS_PER_CUP[cup_idx]+1):
		current_cup_tracks.append(cup_dir + "/Track_" + str(i) + ".tscn")
		
	current_cup_idx = cup_idx
	current_track_idx = -1
	begin_next_track()


func _ready():
	for cup in CUPS:
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
		assert(track_count > 0)
		TRACKS_PER_CUP.append(track_count)
		
	begin_cup(1)
