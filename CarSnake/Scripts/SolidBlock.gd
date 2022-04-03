extends ColorRect

signal hit_by_car

# [ENGINE CALLBACK]
func _ready():
	$Area2D.connect("body_entered", self, "_on_Area2D_body_entered")
	var collision_rect = $Area2D/CollisionShape2D.get_shape()
	collision_rect.set_extents(get_size() / 2.0)
	$Area2D/CollisionShape2D.set_shape(collision_rect)
	$Area2D/CollisionShape2D.set_position(get_size() / 2.0)

# [ENGINE SIGNAL CALLBACK]
func _on_Area2D_body_entered(_body):
	emit_signal("hit_by_car")
