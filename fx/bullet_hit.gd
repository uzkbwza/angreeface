extends "res://framework/Fx/ParticleEffect.gd"
@onready var animated_sprite_2d = $AnimatedSprite2D

var rng = BetterRng.new()

# Called when the node enteras the scene tree for the first time.
func _ready():
	super._ready()
	rng.randomize()
	animated_sprite_2d.rotation = rng.random_angle()
