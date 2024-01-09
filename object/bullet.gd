extends Node2D

class_name Bullet

signal disappeared()

const BULLET = preload("res://object/bullet.tscn")
const BULLET_HIT_PARTICLE = preload("res://fx/bullet_hit.tscn")

const MAX_ENEMY_BULLET_SPEED = 1200
const LIFETIME = 4.0
const BASE_SPEED = 250 
const BASE_DAMAGE = 1.0
const BASE_SPRITE_SIZE = 0.75
const MIN_SPEED_SQUARED = 1000
const PARALYZE_DAMAGE_MODIFIER = 3.0
const BASE_KNOCKBACK = 300
const BASE_HITSTOP = 0.032
const LIGHTING_SPEED = 500
const MAX_KNOCKBACK = 1000
const EXPLOSION = preload("res://object/explosion.tscn")
const SPLIT_BULLET_PER = 0.3
const SPLIT_BULLET_SPEED = 150
const LIGHTNING_CHAINS = 7
const POISON_BUILDUP = 1.0
const EXPLOSION_DAMAGE_MODIFIER = 1.4
const PARALYZE_PERCENT = 10
const PLAYER_BULLET_SIZE_MOD = 1.2
const PLAYER_BULLET_SIZE_MOD_2 = 2.0

enum BulletProperty {
	Normal,
	Poison,
	Fire,
	Paralyze,
	Piercing,
	Explosive,
	Virus,
	LightningChain,
	Split,
	Big,
}

@onready var player_bullet_sprite = $PlayerBulletSprite
@onready var sprite = $Sprite
@onready var detector = $Detector
@onready var detector_collision_shape = %DetectorCollisionShape
@onready var nearby_detector = $NearbyDetector
@onready var lifetime = $Lifetime
@onready var smoother = get_tree().get_first_node_in_group("Smoother")


#@onready var player_bullet_sprite_2 = $PlayerBulletSprite2
var velocity = Vector2()
var drag = 0.0
var rng = BetterRng.new()
var pierces_left = 1
var knockback_modifier = 1.0
var lightning_chains_left = LIGHTNING_CHAINS
var startup = 0.00


var hitstopped = false
var spell_1 = null
var started = false
var lightning = false

var lightning_target = null
var disappear_when_stopped = true
var active = false

var hit_characters = {}

var flank = false
var flank_time = 0
var flank_target_pos = Vector2()
var flank_triggered = false
var update_2 = false

var t = 0

var player_side = false:
	set(b):
		player_side = b
		if detector:
			detector.set_collision_mask_value(2, !player_side)
			detector.set_collision_mask_value(3, player_side)
			nearby_detector.set_collision_mask_value(2, !player_side)
			nearby_detector.set_collision_mask_value(3, player_side)
			
			#player_bullet_sprite_2.visible = player_side
			
		sprite.animation = "enemy" if !player_side else "default"
		player_bullet_sprite.animation = sprite.animation

		await get_tree().create_timer(startup, false).timeout
		detector_collision_shape.disabled = false
		started = true

var properties = {}
var speed: float = BASE_SPEED
var damage: float = BASE_DAMAGE:
	set(d):
		damage = d
		if damage < 0.01:
			damage = 0.01
		if sprite:
			var r = get_size()
			sprite.scale = Vector2.ONE * r
			detector_collision_shape.shape.radius = r * 7
		if player_side:
			detector_collision_shape.shape.radius *= PLAYER_BULLET_SIZE_MOD
		player_bullet_sprite.scale = sprite.scale * PLAYER_BULLET_SIZE_MOD

var custom_move_function
var extra_custom_functions = []
var dying = false

func deactivate():
	hide()
	position.x = -1000000
	position.y = -1000000
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	lifetime.stop()
	set_process.call_deferred(false)
	set_physics_process.call_deferred(false)
	#set_process_internal(false)
	#set_physics_process_internal(false)
	detector.set_collision_mask_value.call_deferred(2, false)
	detector.set_collision_mask_value.call_deferred(3, false)
	nearby_detector.set_collision_mask_value.call_deferred(2, false)
	nearby_detector.set_collision_mask_value.call_deferred(3, false)
	detector_collision_shape.set_deferred("disabled", true)
	active = false
	t = 0.0
	flank = false
	flank_target_pos = Vector2()
	flank_time = 0.0
	flank_triggered = false
	dying = false
	extra_custom_functions = []
	custom_move_function = null
	properties = {}
	lifetime.start(LIFETIME)
	velocity = Vector2()
	drag = 0.0
	pierces_left = 1
	knockback_modifier = 1.0
	lightning_chains_left = LIGHTNING_CHAINS
	startup = 0.00
	hitstopped = false
	spell_1 = null
	started = false
	lightning = false
	update_2 = false
	hit_characters.clear()
	lightning_target = null
	disappear_when_stopped = true
	reset_properties()

func reset_properties():
	for i in range(BulletProperty.size()):
		properties[Utils.enum_string(i, BulletProperty)] = false

func activate():
	active = true
	show()
	set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
	set_process.call_deferred(true)
	set_physics_process.call_deferred(true)
	#set_process_internal(true)
	#set_physics_process_internal(true)

func teleport_to(gp):
	global_position = gp
	smoother.reset_node(self)

func get_size():
	return max(0.5, damage * BASE_SPRITE_SIZE)

func _init():
	pass

func _ready():
	rng.randomize()
	#load_spell_1(preload("res://spells/None.tres"))
	detector.body_entered.connect(_on_body_entered)
	lifetime.timeout.connect(on_lifetime_over)

func on_lifetime_over():
	dying = true

func _on_body_entered(body):
	if body is StaticBody2D:
		disappear()
	if body is BaseObjectBody2D:
		if body.host is Character:
			if body.host in hit_characters:
				return
			hit(body.host)

func hit(character: Character):
	hit_characters[character] = true
	var paralyzed = false
	var prev_damage = damage
	if properties["Paralyze"] and rng.percent(PARALYZE_PERCENT * damage):
		paralyzed = true
		character.paralyze()
		damage *= PARALYZE_DAMAGE_MODIFIER
	if !properties["Explosive"]:
		character.hit_by(self, true, !lightning)
	if paralyzed:
		damage = prev_damage
	pierces_left -= 1
	hitstopped = true
	var prev_hitstopped = character.hitstopped
	if !(lightning and player_side):
		character.hitstopped = true
	hit_effect.call_deferred(character)
	if pierces_left <= 0:
		disappear()
		if properties["Split"]:
			split.call_deferred()
	if properties["Lightning Chain"] and player_side:
		for i in range(max(damage / 0.1, 2)):
			if rng.chance(max(damage * 0.5 - (i * (damage * 0.1)), 0.35)):
				lightning_chain.call_deferred()
	if properties["Poison"]:
		character.poison_buildup += POISON_BUILDUP
	if properties["Fire"]:
		character.on_fire = true
	if properties["Virus"] and character.enemy_component:
		character.infected = true


	while hitstopped:
		await get_tree().physics_frame
	if character and !prev_hitstopped and !properties["Explosive"] and !lightning:
		var knockback = speed * damage * knockback_modifier
		knockback = min(knockback, MAX_KNOCKBACK)
		if character.enemy_component:
			knockback /= min(character.enemy_component.level, 4)
		if lightning:
			knockback *= 0.25
		if player_side:
			knockback *= 0.5
		character.body.apply_impulse(knockback * velocity.normalized())

func make_particle():
	var scene = BULLET_HIT_PARTICLE if !lightning else preload("res://fx/bullet_hit_lightning.tscn")
	var particle = scene.instantiate()
	#particle.lifetime = hitstop_amount
	particle.scale = Vector2.ONE * get_size() * 3
	particle.modulate = sprite.self_modulate

	add_sibling(particle, true)
	particle.global_position = global_position
	return particle

func hit_effect(character):
	var hitstop_amount = BASE_HITSTOP * damage
	make_particle()
	var camera: GameCamera = get_tree().get_first_node_in_group("Camera")
	var bump_amount = global_position.distance_to(camera.global_position) / 200.0
	bump_amount = clamp(bump_amount, 0.5, 10)
	#print(bump_amount)
	camera.bump(Vector2(), (max(damage, BASE_DAMAGE / 2.0) / bump_amount) * 2, min(damage / 4.0, 0.5))

	await get_tree().create_timer(hitstop_amount, false, true).timeout
	hitstopped = false
	if character:
		character.hitstopped = false

func _physics_process(delta):
	if hitstopped:
		return

	position += (velocity) * delta
	if drag > 0:
		velocity.x = Utils.damp(velocity.x, 0, drag, delta)
		velocity.y = Utils.damp(velocity.y, 0, drag, delta)
	if disappear_when_stopped and velocity.length_squared() < MIN_SPEED_SQUARED and rng.chance_delta(25.0, delta):
		disappear()
	if lightning:
		if lightning_target:
			var dir = (lightning_target.global_position - global_position).normalized()
			velocity = dir * speed
		else:
			disappear()
	if flank and !flank_triggered:
		if t >= flank_time:
			flank_triggered = true
			var current_speed = velocity.length()
			velocity = (flank_target_pos - global_position).normalized() * current_speed
			#velocity *= 0
	if t == 0:
		if !player_side:
			velocity = velocity.limit_length(MAX_ENEMY_BULLET_SPEED)
	elif !update_2:
		update_2 = true
		damage = damage
		show()

	for function in extra_custom_functions:
		function.call(self, delta)

	if dying and rng.chance_delta(25.0, delta):
		disappear()

	t += delta

func load_spell_1(spell: Spell):
	var prop = Utils.enum_string(spell.bullet_property, BulletProperty)
	properties[prop] = true

	sprite.rotation = rng.random_angle()

	player_bullet_sprite.rotation = sprite.rotation
	
	sprite.frame = rng.randi_range(0, sprite.sprite_frames.get_frame_count(sprite.animation))
	player_bullet_sprite.frame = sprite.frame
	#player_bullet_sprite_2.frame = sprite.frame
	sprite.self_modulate = spell.bullet_color
	player_bullet_sprite.self_modulate = spell.bullet_color
	#player_bullet_sprite_2.self_modulate = spell.bullet_color
	match spell.bullet_property:
		BulletProperty.Normal:
			pass
		BulletProperty.Piercing:
			pierces_left += 100000
		BulletProperty.Explosive:
			pierces_left = 1
	
	spell_1 = spell
	
	if properties["Lightning Chain"]:
		nearby_detector.monitoring = true
	
	spell.apply_properties(self)
	
	queue_redraw()

func disappear():
	while hitstopped:
		await get_tree().physics_frame
	if properties["Explosive"]:
		var explosion = EXPLOSION.instantiate()
		explosion.global_position = global_position
		#explosion.player_side = player_side
		add_sibling.call_deferred(explosion)
		explosion.damage = damage * EXPLOSION_DAMAGE_MODIFIER
	disappeared.emit()
	deactivate.call_deferred()

func lightning_chain():
	if !active:
		return
	if lightning_chains_left <= 0:
		return
	
	var target = rng.choose(nearby_detector.get_overlapping_bodies())
		
	if !target:
		return
	
	for i in range(10):
		if target.host in hit_characters:
			target = rng.choose(nearby_detector.get_overlapping_bodies())
		else:
			break

	if target.host in hit_characters:
		return

	var bullet = create_sub_bullet(rng.randf_range(0.01, 0.3))

	bullet.damage = 0.35 * damage
	bullet.lightning_chains_left = lightning_chains_left - 1
	if !player_side:
		bullet.lightning_chains_left -= 8
	bullet.lightning = true
	
	bullet.lightning_target = target
	bullet.lightning = true
	bullet.disappear_when_stopped = false
	#print(bullet.velocity)

func teleport():
	smoother.reset_node(self)
	pass

func create_sub_bullet(startup=0.1):
	var bullet = get_parent().get_parent().get_bullet()
	if spell_1:
		bullet.load_spell_1(spell_1.duplicate())
	bullet.custom_move_function = custom_move_function
	bullet.extra_custom_functions = extra_custom_functions.duplicate()
	bullet.teleport_to(global_position)
	bullet.startup = startup
	bullet.player_side = player_side
	bullet.speed = LIGHTING_SPEED
	for property in properties:
		if properties[property]:
			bullet.properties[property] = true
	
	return bullet

func split():
	if !active:
		return
	if rng.chance(-0.5 + 1.0 - damage):
		return
	var num_bullets = min(max(ceil(SPLIT_BULLET_PER / (damage / BASE_DAMAGE)), 3), 7)
	for i in range(num_bullets):
		var bullet = create_sub_bullet()
		bullet.speed = SPLIT_BULLET_SPEED
		bullet.velocity = Vector2(SPLIT_BULLET_SPEED, 0).rotated(TAU * (i / float(num_bullets)))
		bullet.damage = damage / num_bullets
		if (bullet.damage) > SPLIT_BULLET_PER / 2.0:
			pass
		else:
			bullet.properties["Split"] = false



#func _draw():
	#var color = sprite.self_modulate
	#color.a = 0.25
	#draw_arc(Vector2(), detector_collision_shape.shape.radius, 0.0, TAU, 32, color)

