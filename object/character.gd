extends BaseObject2D

class_name Character

const BULLET_OFFSET = 8
const PLAYER_BULLET_SPEED_MOD = 2.5
const ENEMY_BULLET_SPEED_MOD = 1.25
const ENEMY_FIRE_RATE_MOD = 2.0
const ENEMY_DROP_SPELL_TIME = 5.5

const FIRE_DAMAGE = 0.5
const POISON_REDUCTION_AMOUNT = 0.4
const MAX_POISON = 4.0
const POISON_DAMAGE_MODIFIER = 0.15
const SPELL_PICKUP = preload("res://object/spell_pickup.tscn")
const SPELL_PICKUP_DROP_VEL = 10
const NO_SPELL = preload("res://spells/None.tres")

const SHOOT_SOUNDS = {
	Bullet.BulletProperty.Normal: "ShootHi",
	Bullet.BulletProperty.Poison: "ShootPoison",
	Bullet.BulletProperty.Fire: "ShootFire",
	Bullet.BulletProperty.Virus: "ShootVirus",
	Bullet.BulletProperty.Paralyze: "ShootParalyze",
	Bullet.BulletProperty.Piercing: "ShootPiercing",
	Bullet.BulletProperty.Explosive: "ShootExplosive",
	Bullet.BulletProperty.Split: "ShootSplit",
	Bullet.BulletProperty.LightningChain: "ShootLightning",
	Bullet.BulletProperty.Big: "ShootBig",
}

signal loaded_spell(slot: int, spell: Spell)
signal player_moved
signal spell_lost(slot)
signal died

@export var character_move_speed: float = 1000

@export var move_drag = 3.0
@export var idle_drag = 5.0

@export var spell_count = 2

@onready var player_component = get_node_or_null("%PlayerComponent")
@onready var enemy_component = get_node_or_null("%EnemyComponent")

@onready var fire_timer = $FireTimer
@onready var poison_effect = %PoisonEffect
@onready var fire_effect = %FireEffect
@onready var virus_effect = %VirusEffect
@onready var on_fire_damage_timer = $OnFireDamageTimer
@onready var character_detector = $CharacterDetector
@onready var collision_shape_2d = $Body/CollisionShape2D
@onready var shield_icon = %ShieldIcon

@export var spell_1: Spell # projectile type
@export var spell_2: Spell # fire pattern
@export var modifier_spell: Spell

var spell_1_time_left = 13
var spell_2_time_left = 13

var invulnerable = false

var spell_selection = 1
var paralyzed = false
var dead = false

var poison_buildup = 0.0:
	set(amount):
		if player_component:
			poison_buildup = 0.0
			return

		poison_buildup = amount
		poison_effect.emitting = amount > 0

var on_fire = false:
	set(b):
		var was_on_fire = on_fire
		on_fire = b
		fire_effect.emitting = on_fire
		if on_fire and !was_on_fire:
			on_fire_damage_timer.start()
		if !on_fire:
			on_fire_damage_timer.stop()

var infected = false:
	set(b):
		infected = b
		virus_effect.emitting = infected

func spawn_spell(spell, time_left=Spell.PICKUP_TIME):
	if !spell:
		return
	var pickup = SPELL_PICKUP.instantiate()
	add_sibling(pickup)
	pickup.velocity = ((body.velocity) + get_aim_intent() * SPELL_PICKUP_DROP_VEL).rotated(rng.random_arc(TAU/4))
	if pickup.velocity.length() < 100:
		pickup.velocity = pickup.velocity.normalized() * 100
	pickup.pickup_time = time_left
	pickup.load_spell(spell)
	pickup.global_position = global_position

func check_load_spell():
	if player_component:
		var current_spell
		var discarded_spell
		var spell_data = player_component.try_load_spell()
		if spell_data:
			var spell = spell_data[0]
			var spell_time_left = spell_data[1]
			var discarded_slot = 1
			var old_spell_time_1 = spell_1_time_left
			var old_spell_time_2 = spell_2_time_left
			play_sound("SpellPickup")
			if spell_selection == 1:
				current_spell = spell_1
				if (spell_2.empty and !current_spell.empty) or current_spell.name == spell.name:
					discarded_spell = spell_2
					discarded_slot = 2
					load_spell_2(spell, spell_time_left)
				else:
					discarded_spell = spell_1
					discarded_slot = 1
					load_spell_1(spell, spell_time_left)
			if spell_selection == 2:
				current_spell = spell_2
				if (spell_1.empty and !current_spell.empty) or current_spell.name == spell.name:
					discarded_spell = spell_1
					discarded_slot = 1
					load_spell_1(spell, spell_time_left)
				else:
					discarded_spell = spell_2
					discarded_slot = 2
					load_spell_2(spell, spell_time_left)
			if !discarded_spell.empty:
				var spell_time = (old_spell_time_1 if discarded_slot == 1 else old_spell_time_2)
				if spell_time < 1.0:
					spell_time = 1.0
				spawn_spell.call_deferred(discarded_spell, spell_time)

func get_camera() -> GameCamera:
	return get_tree().get_first_node_in_group("Camera")

func get_move_force():
	var speed = character_move_speed
	#if player_component:
		#speed *= get_selected_spell().get_move_speed_modifier()
		#speed *= 1.0 / get_2nd_spell().damage_modifier
	return get_move_intent() * speed

func _ready():
	super._ready()
	load_modifier_spell(modifier_spell)
	await get_tree().process_frame
	on_fire_damage_timer.timeout.connect(on_fire_damage_timer_timeout)
	character_detector.body_entered.connect(on_character_detector_body_entered)
	if player_component:
		sprite.sprite_frames.remove_frame("default", 0)
		for i in Global.PLAYER_SPRITES.size():
			sprite.sprite_frames.add_frame("default", Global.PLAYER_SPRITES[i])

	#load_spell_1(Spell.load_random_spell())
	#load_spell_2(Spell.load_random_spell())
	load_spell_1(spell_1)
	load_spell_2(spell_2)
	if enemy_component and !get_active_spells():
		enemy_component.corrupted = true

func get_active_spells() -> Array:
	var arr = []
	for spell: Spell in [spell_1, spell_2]:
		if spell and !spell.empty:
			arr.append(spell)
	return arr

func paralyze():
	paralyzed = true
	sprite.offset.x = 3
	await get_tree().create_timer(1.6).timeout
	paralyzed = false
	sprite.offset.x = 0
	pass

func on_character_detector_body_entered(body):
	if not (body is BaseObjectBody2D):
		return
	if not (body.host is Character):
		return
	var character = body.host
	if on_fire:
		character.on_fire = true
	if infected:
		if character.enemy_component != null:
			character.infected = true
	pass

func load_spell_1(spell: Spell, spell_time_left = Spell.PICKUP_TIME):
	spell_1 = spell
	loaded_spell.emit(1, spell)
	spell_1_time_left = spell_time_left

func load_spell_2(spell: Spell, spell_time_left = Spell.PICKUP_TIME):
	spell_2 = spell
	loaded_spell.emit(2, spell)
	spell_2_time_left = spell_time_left

func load_modifier_spell(spell: Spell):
	pass

func on_fire_damage_timer_timeout():
	var obj = {
		"damage": FIRE_DAMAGE
	}
	hit_by(obj, true, true, false)
	play_sound("GotHit")
	play_sound("GotHitBass")
	if rng.percent(10) or player_component:
		on_fire = false

func apply_poison(delta):
	if poison_buildup <= 0:
		return
	hit_by({"damage": poison_buildup * delta * POISON_DAMAGE_MODIFIER}, false, false, false)
	poison_buildup -= POISON_REDUCTION_AMOUNT * delta
	poison_effect.amount_ratio = poison_buildup / MAX_POISON

func get_move_intent():
	if paralyzed:
		return Vector2()
	if player_component:
		var dir = player_component.get_move_dir()
		if dir:
			player_moved.emit()
		return dir
	if enemy_component:
		return enemy_component.get_move_dir()
	return Vector2()

func get_shoot_intent():
	if get_tree().get_first_node_in_group("Player").dead:
		return
	if player_component:
		return player_component.is_shoot_held()
	if enemy_component:
		return enemy_component.wants_to_shoot()
	return false

func update_selected_spell():
	if player_component:
		if player_component.is_change_spell_pressed():
			play_sound("Swap")
			swap_spell()

	elif enemy_component:
		if enemy_component.buffer_swap:
			play_sound("Swap")
			swap_spell()
			enemy_component.buffer_swap = false

func swap_spell():
	spell_selection = (2 if spell_selection == 1 else 1)

func get_aim_intent():
	if player_component:
		return player_component.get_aim_dir()
	if enemy_component:
		return enemy_component.get_aim_dir()
	return Vector2()

func hit_by(object, effect=true, force_minimum=true, damage_buildup=true):
	if invulnerable:
		return
	if effect:
		fx.hit_effect()
		if player_component:
			play_sound("GotHit")
			play_sound("GotHitBass")
	var damage = object.damage
	var spells = get_active_spells()
	if force_minimum:
		damage = max(damage, 0.1)
	if infected:
		damage *= 1.1
	if enemy_component:
		if spells.is_empty():
			damage *= 2
		else:
			damage *= 0.5
		#damage *= 1 + (1 - spells.size() * 0.5)
		#print(damage)
		enemy_component.hp -= damage
		if enemy_component.hp <= 0:
			die()
		if enemy_component.hp > enemy_component.base_hp:
			enemy_component.hp = enemy_component.base_hp
		enemy_component.apply_damage_buildup(damage * 2)
		
	if player_component or (damage_buildup and enemy_component and (enemy_component.check_damage_buildup()) and !dead):
		
		if spells:
			var slot = spell_selection if !get_selected_spell().empty else get_other_slot()
			var old_spell = get_spell(slot)
			#print(slot)
			load_spell(slot, NO_SPELL)
			spell_lost.emit(slot)
			if get_active_spells().is_empty():
				lost_shield_effect()
				if enemy_component:
					enemy_component.corrupted = true
			if player_component:
				get_camera().bump(Vector2(), 10, 1.0)
				play_sound("Hurt")
				invulnerable = true
				collision_shape_2d.set_deferred("disabled", true)
				
				sprite.animation = "square"
				if rng.percent(2):
					flicker_player_sprite()
				
				await get_tree().create_timer(0.5).timeout
				if !dead:
					collision_shape_2d.set_deferred("disabled", false)
				invulnerable = false
			else:
				enemy_component.damage_buildup_release()
				if rng.percent(30) or !get_parent().spawned_pickup:
					spawn_spell.call_deferred(old_spell, ENEMY_DROP_SPELL_TIME)
					get_parent().spawned_pickup = true
				enemy_component.setup_spell_display()
		elif player_component:
			die()

func flicker_player_sprite():
	sprite.animation = "default"
	for i in range(120):
		sprite.frame = rng.randi() % (sprite.sprite_frames.get_frame_count(sprite.animation))
		await get_tree().physics_frame

func lost_shield_effect():
	if enemy_component:
		play_sound("Hurt")
		get_camera().bump(Vector2(), 5, 1.0)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_parallel(true)
	shield_icon.visible = true
	shield_icon.self_modulate.a = 1.0
	shield_icon.scale = Vector2.ONE * 4.0 * sprite.scale.x
	tween.tween_property(shield_icon, "self_modulate:a", 0.0, 1.0)
	tween.tween_property(shield_icon, "scale", Vector2.ONE * 6.0 * sprite.scale.x, 1.0)
	await tween.finished
	shield_icon.visible = false

func get_other_slot():
	return 1 + ((spell_selection) % 2)

func load_spell(slot, spell):
	if slot == 1:
		load_spell_1(spell)
	elif slot == 2:
		load_spell_2(spell)

func get_spell(slot):
	if slot == 1:
		return spell_1
	if slot == 2:
		return spell_2

func get_2nd_spell() -> Spell:
	var spells = [spell_1, spell_2]
	return spells[spell_selection % spells.size()]

func get_selected_spell() -> Spell:
	var spells = [spell_1, spell_2]
	return spells[spell_selection - 1]

func set_selected_spell(spell: Spell):
	if spell_selection == 1:
		load_spell_1(spell)
	else:
		load_spell_2(spell)

func die():
	if dead:
		return
	dead = true
	died.emit()
	death_effect.call_deferred()

	if enemy_component:
		queue_free()
	elif player_component:
		change_state("Dead")
		collision_shape_2d.set_deferred("disabled", true)
		sprite.hide()

func death_effect():
	var effect = preload("res://fx/death.tscn").instantiate()
	add_sibling(effect)
	effect.scale = sprite.scale * 2.0
	effect.global_position = global_position
	effect.rotation = rng.random_angle()
	if enemy_component and infected:
		var explosion = preload("res://object/explosion.tscn").instantiate()
		explosion.damage = 1 + (enemy_component.level * 0.75)
		explosion.scale_mod = 1.0
		explosion.max_size = 7.0
		add_sibling(explosion)
		explosion.global_position = global_position

func cast():
	if !fire_timer.is_stopped():
		return
	cast_deferred.call_deferred()

func _physics_process(delta):
	super._physics_process(delta)
	if paralyzed:
		sprite.offset.x = -sprite.offset.x
	if abs(global_position.x) > Game.BOUNDARY_X:
		global_position.x = lerp(global_position.x, float(Game.BOUNDARY_X * sign(global_position.x)), Utils.dtlerp(3, delta))
	
	if abs(global_position.y) > Game.BOUNDARY_Y:
		global_position.y = lerp(global_position.y, float(Game.BOUNDARY_Y * sign(global_position.y)), Utils.dtlerp(3, delta))

func _process(delta):
	if player_component:
		visible = true
		if invulnerable:
			visible = Utils.pulse(0.064)
	#if infected and !virus_effect.emitting:
		#virus_effect.emitting = true

func get_aim_distance():
	if player_component:
		return player_component.get_aim_distance()
	if enemy_component:
		return enemy_component.get_aim_distance()

func cast_deferred():
	var spells = [spell_1, spell_2]

	var spell_1 = spells[spell_selection - 1]
	var spell_2 = spells[spell_selection % spells.size()]

	var fire_rate = spell_2.fire_rate
	
	if spell_1.bullet_property == Bullet.BulletProperty.Big:
		fire_rate *= 2.0

	var burst_rate = spell_2.burst_rate * spell_1.get_fire_rate_modifier()
	burst_rate = max(burst_rate, get_physics_process_delta_time())
	

	if enemy_component:
		var mod = lerp(0.5, (enemy_component.level / 4.0) / 4.0, 0.5)
		#print(enemy_component.level, ", ", 1.0 / mod)
		fire_rate /= mod
		fire_rate *= ENEMY_FIRE_RATE_MOD
		burst_rate *= ENEMY_FIRE_RATE_MOD
	
	fire_rate *= spell_1.get_fire_rate_modifier()

	var num_bursts = spell_2.num_bursts
	if num_bursts > 1:
		num_bursts = max(2, num_bursts / spell_1.get_fire_rate_modifier())
		num_bursts = min(num_bursts, spell_2.num_bursts)

	var full_burst = burst_rate * num_bursts

	fire_rate = max(fire_rate, full_burst)

	fire_timer.start(fire_rate)
	#print(fire_rate)

	var fire_pattern = spell_2.fire_pattern
	var fire_pattern_damage_modifier = spell_2.damage_modifier
	var bullet_damage = Bullet.BASE_DAMAGE * fire_pattern_damage_modifier


	for i in range(num_bursts):
		var aim = get_aim_intent()
		var aim_angle = aim.angle()
		var target_dist = get_aim_distance()

		for j in range(spell_2.num_bullets):

			var bullet_speed = spell_2.speed

			bullet_speed *= rng.randfn(1.0, spell_2.speed_random_distribution)

			if player_component:
				bullet_speed *= PLAYER_BULLET_SPEED_MOD

			if enemy_component:
				bullet_speed *= ENEMY_BULLET_SPEED_MOD

			var bullet = get_parent().get_bullet()
			get_parent()
			bullet.player_side = player_component != null
			bullet.global_position = global_position + aim * BULLET_OFFSET

			#bullet.velocity = body.velocity

			bullet.damage = bullet_damage
			bullet.speed = bullet_speed
			bullet.rotation = aim_angle
			match spell_2.fire_pattern:
				Spell.FirePattern.Normal: 
					if spell_2.spread_degrees > 0:
						var angle = deg_to_rad(spell_2.spread_degrees)
						bullet.rotation += rng.randf_range(-angle, angle)
				Spell.FirePattern.EqualSpread:
					var angle = deg_to_rad(spell_2.spread_degrees)
					angle = Utils.map(float(j), 0, spell_2.num_bullets - 1, -angle, angle)
					bullet.rotation += angle
				Spell.FirePattern.Flank:
					var angle = deg_to_rad(spell_2.flank_angle * (1 - (2 * (j % 2))))
					bullet.rotation += angle
					bullet.global_position = global_position + aim.rotated(angle) * BULLET_OFFSET
					
					bullet.flank_time = spell_2.flank_time
					bullet.flank_target_pos = global_position + (aim * target_dist)
					bullet.flank = true
					var angle2 = deg_to_rad(spell_2.spread_degrees)
					bullet.rotation += rng.randf_range(-angle2, angle2)
		

			bullet.velocity += Vector2(bullet_speed, 0).rotated(bullet.rotation)
			if bullet.velocity.length() < bullet_speed:
				bullet.velocity = bullet.velocity.normalized() * bullet_speed
			bullet.drag = spell_2.drag
			if enemy_component:
				bullet.drag *= ENEMY_BULLET_SPEED_MOD
			bullet.pierces_left = spell_2.num_pierces
			
			bullet.extra_custom_functions.append_array(spell_1.get_custom_update_functions(1))
			bullet.extra_custom_functions.append_array(spell_2.get_custom_update_functions(2))
			
			#spell_2.apply_additional_properties(bullet, 2)
			
			bullet.load_spell_1(spell_1)
			bullet.teleport()

			if j == 0:
				var particle = bullet.make_particle()
				particle.scale.x = clamp(particle.scale.x, 0.5, 1.5)
				particle.scale.y = particle.scale.x

		var camera: GameCamera = get_tree().get_first_node_in_group("Camera")
		var bump_amount = global_position.distance_to(camera.global_position) / 200.0
		bump_amount = clamp(bump_amount, 0.5, 10)
		#print(bump_amount)
		camera.bump(Vector2(), spell_2.damage_modifier * (spell_2.burst_rate / bump_amount) * 4 * spell_2.num_bullets, spell_2.burst_rate * 2)

		
		var pitchmod = 1 + clamp(1.0 - fire_pattern_damage_modifier, -0.35, 1)
		play_sound("ShootBass") 

		var shoot_sound = "ShootHi"
		if spell_1.bullet_property in SHOOT_SOUNDS:
			shoot_sound = SHOOT_SOUNDS[spell_1.bullet_property]
		play_sound(shoot_sound, pitchmod) 
		play_sound("ShootHi2", pitchmod)
		if shoot_sound != "ShootHi":
			play_sound("ShootHi3") 
		
		if num_bursts > 1:
			#print(spell_2.burst_rate * spell_1.get_fire_rate_modifier())
			await get_tree().create_timer(burst_rate, false).timeout

func character_move(dxy: Vector2):
	body.apply_force(dxy)
