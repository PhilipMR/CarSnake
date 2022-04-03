extends Node2D

signal hit_by_car

func _ready():
	$Area2D.connect("body_entered", self, "_on_Area2D_body_entered")

func set_car_collision_enabled(enabled):
	$Area2D/CollisionShape2D.set_deferred("disabled", !enabled)

func _on_Area2D_body_entered(_body):
	emit_signal("hit_by_car")
	queue_free()
