extends ObjectState

func _update(delta):
	var move_force = host.get_move_force()
	if move_force.length_squared() == 0:
		body.drag = host.idle_drag
	else:
		body.drag = host.move_drag
	host.character_move(move_force)
	host.update_selected_spell()
	if host.get_shoot_intent():
		host.cast()
	host.apply_poison(delta)
	host.check_load_spell()
