extends GoodCamera

class_name GameCamera

@export var player: Character

func _process(delta):
	super._process(delta)
	global_position = player.global_position.lerp(get_global_mouse_position(), 0.25)
