extends Control

export(PackedScene) var CupListItem

signal cup_selected # False warning that it's not emitted (it is, on item.connect("clicked"))

const ITEM_PADDING = 100

func _ready():
	for dummy in $List.get_children():
		$List.remove_child(dummy)
		dummy.queue_free()
		
	var i = 0
	var item_height = 0
	for cup in Global.CUPS:
		var item = CupListItem.instance()
		$List.add_child(item)
		
		var is_name_hidden = (i+1) > Global.UserData.cups_unlocked
		if is_name_hidden:
			item.disable()
		else:
			item.set_cup_title(cup[0])
			
		item_height = item.get_rect().size.y
		item.set_position(item.get_position() + Vector2(0, i * (item_height + ITEM_PADDING)))
		item.connect("clicked", self, "emit_signal", ["cup_selected", cup[0]])
		i += 1

	var does_list_excess = i * (item_height + ITEM_PADDING) >= $MaskBottom.get_position().y
	$VScrollBar.set_visible(does_list_excess)
	$VScrollBar.set_max((i-2) * (item_height + ITEM_PADDING-1))
	
	
func _on_VScrollBar_value_changed(value):
	var pos = $List.get_position()
	pos.y = -(value - $VScrollBar.get_min())
	$List.set_position(pos)
	
	
const MOUSE_SCROLL_SPEED = 10.0
func _input(event):
	if not(event is InputEventMouseButton) or not(event.is_pressed()):
		return
		
	if event.button_index == BUTTON_WHEEL_UP:
		$VScrollBar.set_value($VScrollBar.get_value() - MOUSE_SCROLL_SPEED)
	elif event.button_index == BUTTON_WHEEL_DOWN:
		$VScrollBar.set_value($VScrollBar.get_value() + MOUSE_SCROLL_SPEED)

