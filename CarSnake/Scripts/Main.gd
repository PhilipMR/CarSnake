extends Node2D
export (PackedScene) var Level1

func _ready():
	$Level_Prototype.connect("level_completed", self, "_on_level_completed", ["proto"])
	$Level_Prototype.connect("level_failed",    self, "_on_level_failed")
	
func _on_level_completed(name):
	if name == "proto":
		var next = Level1.instance()
		next.connect("level_completed", self, "_on_level_completed", ["Level1"])
		next.connect("level_failed",    self, "_on_level_failed")
		add_child(next)
		$Level_Prototype.queue_free()
	else:
		$FinishOverlay.set_visible(true)
	
func _on_level_failed():
	$CrashOverlay.set_visible(true)
