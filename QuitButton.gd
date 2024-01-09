extends Button

func _process(delta):
	modulate = Color("ff8563") if !is_hovered() else Color.WHITE
