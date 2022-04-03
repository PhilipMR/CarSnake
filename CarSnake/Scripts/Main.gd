extends Node2D
export (PackedScene) var Level1

func _ready():
	$Level_Prototype.connect("level_completed", self, "_on_level_completed", ["proto"])
	$Level_Prototype.connect("level_failed",    self, "_on_level_failed")
	
func _on_level_completed(name):
	if name == "proto":
		for obj in $_TempObjects.get_children():
			obj.queue_free()
		$Level_Prototype.queue_free()
		var next = Level1.instance()
		next.connect("level_completed", self, "_on_level_completed", ["Level1"])
		next.connect("level_failed",    self, "_on_level_failed")
		add_child(next)
	else:
		$UI/FinishOverlay.set_visible(true)
	
func _on_level_failed():
	$UI/CrashOverlay.set_visible(true)
