extends Node2D

signal hit_by_car

func _ready():
	$Area2D.connect("body_entered", self, "_on_Area2D_body_entered")

func _on_Area2D_body_entered(_body):
	emit_signal("hit_by_car")
