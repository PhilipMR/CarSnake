extends Node2D

var current_cup_idx    = 0
var current_track_idx  = 0
var current_cup_tracks = []

func begin_next_track():
	current_track_idx += 1
	Global.next_track_id = current_track_idx
	assert(current_cup_tracks.size() > current_track_idx)
	
	var track_class = load(current_cup_tracks[current_track_idx])
	var track = track_class.instance()
	track.connect("level_completed", self, "_on_track_completed", [track])
	track.connect("level_failed",    self, "_on_track_failed")
	add_child(track)
	
	
func _on_track_completed(track):
	var tracks_completed = current_track_idx+1
	while Global.UserData.cups_progress.size() <= current_cup_idx:
		Global.UserData.cups_progress.append(0)
	if tracks_completed > Global.UserData.cups_progress[current_cup_idx]:
		Global.UserData.cups_progress[current_cup_idx] = tracks_completed
	
	var completed_cup = ((current_track_idx+1) == current_cup_tracks.size())
	if completed_cup:
		#$UI/FinishOverlay.set_visible(true)
		if Global.UserData.cups_unlocked <= (current_cup_idx+1):
			Global.UserData.cups_unlocked = current_cup_idx+2
		get_tree().change_scene("res://Scenes/Menu_Main.tscn")
	else:
		for obj in $_TempObjects.get_children():
			obj.queue_free()
		track.queue_free()
		begin_next_track()
	
func _on_track_failed():
	$UI/CrashOverlay.set_visible(true)
	
	
func begin_cup(cup_idx, first_track = 0):
	var cup_dir = "res://Scenes/Cups/" + Global.CUPS[cup_idx][1]	
	current_cup_tracks.clear()
	for i in range(1, Global.TRACKS_PER_CUP[cup_idx]+1):
		current_cup_tracks.append(cup_dir + "/Track_" + str(i) + ".tscn")
		
	current_cup_idx   = cup_idx
	current_track_idx = first_track-1
	begin_next_track()


func _ready():
	begin_cup(Global.next_cup_id, Global.next_track_id)
