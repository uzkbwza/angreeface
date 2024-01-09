extends Node2D

var spell: Spell
var velocity = Vector2()
var drag = 1.0

@onready var sprite_2d = $Sprite2D
@onready var e = $E
@onready var death_timer = $DeathTimer
@onready var sound = $Sound

var rng = BetterRng.new()

var pickup_time = Spell.PICKUP_TIME

func load_spell(spell: Spell, play_sound=true):
	death_timer.start(pickup_time)
	self.spell = spell
	sprite_2d.texture = spell.image
	sprite_2d.material.set_shader_parameter("color", spell.bullet_color)
	if play_sound:
		sound.go()

func _on_timer_timeout():
	if death_timer.time_left < 3:
		visible = !visible
	pass # Replace with function body.

func _ready():
	sprite_2d.rotation = rng.random_angle_centered()

func _physics_process(delta):
	if velocity.length_squared() > 0:
		position += velocity * delta
		sprite_2d.rotation += delta * velocity.length() * 0.25
		velocity.x = Utils.damp(velocity.x, 0, drag, delta)
		velocity.y = Utils.damp(velocity.y, 0, drag, delta)
		global_position.x = clamp(global_position.x, -Game.BOUNDARY_X, Game.BOUNDARY_X)
		global_position.y = clamp(global_position.y, -Game.BOUNDARY_Y, Game.BOUNDARY_Y)

func consume():
	queue_free()

func _on_death_timer_timeout():
	queue_free()
