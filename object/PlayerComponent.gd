extends Node2D


var current_hovered_spell = null

@onready var spell_detector = %SpellDetector
@onready var sprite = %Sprite
@onready var player = $".."

var nearby_spells = []
var t = 0.0

func get_move_dir():
	return Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()

func is_shoot_held():
	return Input.is_action_pressed("shoot")

func is_change_spell_pressed():
	return Input.is_action_just_pressed("swap")

func get_aim_dir():
	return get_local_mouse_position().normalized()

func get_aim_distance():
	return get_local_mouse_position().length()

func try_load_spell():
	if is_instance_valid(current_hovered_spell) and Input.is_action_just_pressed("interact"):
		current_hovered_spell.consume()
		return [current_hovered_spell.spell, current_hovered_spell.death_timer.time_left]

func _physics_process(delta):
	var closest = null
	var closest_dist = INF
	current_hovered_spell = null
	for spell in nearby_spells:
		spell.e.hide()
		var dist = global_position.distance_squared_to(spell.global_position)
		if dist < closest_dist:
			closest = spell
			closest_dist = dist
	if closest:
		closest.e.show()
		current_hovered_spell = closest
	var speed = player.body.velocity.length() / 130
	t += delta * speed

	if speed > 0:
		sprite.rotation = sin(t * 16) * (speed * 0.05)
	else:
		sprite.rotation = 0.0

func _process(delta):
	sprite.flip_h = get_aim_dir().x > 0

func _on_spell_detector_area_entered(area):
	nearby_spells.append(area.get_parent())


func _on_spell_detector_area_exited(area):
	nearby_spells.erase(area.get_parent())
	area.get_parent().e.hide()
