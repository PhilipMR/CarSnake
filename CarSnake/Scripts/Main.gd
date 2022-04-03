extends Node2D
export(Array, PackedScene) var Levels

var current_level_idx : int

func load_level(idx):
	var level = Levels[idx].instance()
	level.connect("level_completed", self, "_on_level_completed", [level])
	level.connect("level_failed",    self, "_on_level_failed")
	add_child(level)
	
func _ready():
	current_level_idx = 0
	load_level(current_level_idx)
	
func _on_level_completed(level):
	var completed_all = ((current_level_idx+1) == Levels.size())
	if completed_all:
		$UI/FinishOverlay.set_visible(true)
	else:
		for obj in $_TempObjects.get_children():
			obj.queue_free()
		level.queue_free()
		
		current_level_idx += 1
		load_level(current_level_idx)
	
func _on_level_failed():
	$UI/CrashOverlay.set_visible(true)
