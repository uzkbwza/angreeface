extends "res://framework/Fx/ParticleEffect.gd"

const SIZE_MOD = 4.0
const KNOCKBACK = 200
const MIN_SIZE = 0.7
const MAX_SIZE = 10.0

#var player_side = false
var damage = 1.0
var scale_mod = 1.0
var max_size = 1000
var rng = BetterRng.new()
@onready var collision_shape_2d = $Area2D/CollisionShape2D
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var explosion = $Explosion
@onready var explosion_2 = $Explosion2

func get_camera() -> GameCamera:
	return get_tree().get_first_node_in_group("Camera")

func _ready():
	super._ready()
	var size = min(min(max(damage * scale_mod, MIN_SIZE) * SIZE_MOD, MAX_SIZE), max_size)
	var volume = (-3 - (MAX_SIZE - size) * 0.5)
	var volume2 = (-3 - (MAX_SIZE - size) * 1.0)
	#volume = - 80
	explosion.volume_db = volume
	explosion_2.volume_db = volume2 
	explosion.go.call_deferred(0.0, min(1.5, max(2 / damage, 0.4)))
	collision_shape_2d.shape.radius = size * 7.0 
	animated_sprite_2d.scale *= size
	var camera = get_camera()
	var bump_amount = global_position.distance_to(camera.global_position) / 200.0
	bump_amount = clamp(bump_amount, 0.5, 10)
	rotation += rng.random_angle()
	camera.bump(Vector2(), (5 * max(damage, MIN_SIZE)) / bump_amount, min(0.15 * max(damage, MIN_SIZE), 0.5))
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	collision_shape_2d.disabled = true


func _on_area_2d_body_entered(body):
	if body is BaseObjectBody2D:
		if body.host is Character:
			body.host.hit_by(self)
			body.apply_impulse(KNOCKBACK * damage * (body.global_position - global_position).normalized())
