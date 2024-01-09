extends Node2D

const SHOOT_DISTANCE = 4000
const BACK_AWAY_DISTANCE_REDUCTION_PER_LEVEL = 30
const BACK_AWAY_DISTANCE = 100
const MIN_BACKUP_DISTANCE = 120
const MAX_SPEED = 1100
const PUSH_FORCE = 200
const MAX_BACK_AWAY_DIST = 300
const SIZE_INCREASE_PER_LEVEL = 0.5
const BASE_SIZE = 1.5
const MAX_SIZE = 4.0
const SPEED_PER_LEVEL = 50
const BASE_HP = 3.0

const MIN_LEVEL_COLOR = Color("ffffff")
const MAX_LEVEL_COLOR = Color("e3e8c5")

@onready var sprite = %Sprite

@onready var nearby_enemy_detector = $NearbyEnemyDetector

@onready var hp_bar_container = $HPBarContainer
@onready var collision_shape_2d = $"../Body/CollisionShape2D"
@onready var character_detector_shape = $"../CharacterDetector/CollisionShape2D"
@onready var spell_1 = $SpellDisplay/Spell1
@onready var spell_2 = $SpellDisplay/Spell2
@onready var spell_1_pos = spell_1.position
@onready var spell_2_pos = spell_2.position

var rng = BetterRng.new()
@onready var spell_display = $SpellDisplay


var moving_away = false
var still = false
var can_shoot = false
var buffer_swap = false
var can_stay_still = false
var corrupted = false
var level = 1
var t = 0.0
var offs = 2.0

var buildup = 0
var max_buildup = 100

var player:
	get:
		return get_player()

var host: Character:
	get:
		return get_parent()

var _player

var nearby_enemies = []

var level_scale:
	get:
		return BASE_SIZE + (SIZE_INCREASE_PER_LEVEL * (level - 1)) 

var hp: float = BASE_HP:
	set(p):
		hp = p
		hp_bar_container.scale.x = (hp / base_hp) * (1 + (SIZE_INCREASE_PER_LEVEL * (level - 1)))
		hp_bar_container.position.y = -((level - 1)) * (4)
var base_hp: float = BASE_HP

func _ready():
	host.died.connect(on_death, CONNECT_DEFERRED)
	offs = rng.randf() * 100
	#for i in range(Game.MAX_LEVEL):
		#print(level_hp(i + 1))

func apply_damage_buildup(damage):
	buildup += damage

func check_damage_buildup():
	return buildup > max_buildup and rng.chance(pow((buildup / 5.5) / max_buildup, 1.25))

func damage_buildup_release():
	buildup = 0
	max_buildup *= clamp(rng.randfn(0.5, 0.05), 0.35, 0.65)

func on_death():
	var spells = host.get_active_spells()
	for spell in spells:
		if !host.get_parent().spawned_pickup or rng.percent(17):
			host.spawn_spell.call_deferred(spell)
			host.get_parent().spawned_pickup = true
			break

func get_player():
	if _player == null:
		_player = get_tree().get_first_node_in_group("Player")
	return _player

func wants_to_shoot():
	return can_shoot and get_aim_distance() < SHOOT_DISTANCE and far_enough

func level_hp(level):
	return snapped(BASE_HP + (level * (1 + pow(4, level / 5.0))) / 2.0, 0.125) - (3 - min(level, 3))

func enemy_setup(level):
	self.level = level
	var first_spell = (rng.randi() % 2) + 1
	if (rng.percent(90) and level >= 2) or rng.percent(5):
		if first_spell == 1:
			host.spell_1 = Spell.load_random_spell()
		else:
			host.spell_2 = Spell.load_random_spell()
	if (rng.percent(90) and level >= 3) or rng.percent(5):
		if first_spell == 1:
			host.spell_2 = Spell.load_random_spell()
		else:
			host.spell_1 = Spell.load_random_spell()
	var hp = level_hp(level)
	#print("hp: ", hp)
	set_starting_hp(hp)
	#var level_scale = BASE_SIZE + (SIZE_INCREASE_PER_LEVEL * (level - 1))
	host.sprite.scale *= level_scale
	host.sprite.self_modulate = MIN_LEVEL_COLOR.lerp(MAX_LEVEL_COLOR, (level - 1) / 5.0)
	collision_shape_2d.shape = collision_shape_2d.shape.duplicate(true)
	collision_shape_2d.shape.size = Vector2.ONE * 16 * level_scale
	character_detector_shape.shape = character_detector_shape.shape.duplicate(true)
	character_detector_shape.shape.radius *= level_scale
	spell_display.position.y = ((level - 1)) * (4)
	host.character_move_speed += SPEED_PER_LEVEL * (level - 1)
	if host.character_move_speed > MAX_SPEED:
		host.character_move_speed = MAX_SPEED
	setup_spell_display()

func setup_spell_display():
	spell_1.texture = host.spell_1.image
	spell_2.texture = host.spell_2.image
	spell_1.get_material().set_shader_parameter("color", host.spell_1.bullet_color)
	spell_2.get_material().set_shader_parameter("color", host.spell_2.bullet_color)

func set_starting_hp(amount):
	base_hp = float(amount)
	hp = float(amount)
	buildup = 0
	max_buildup = base_hp * clamp(rng.randfn(0.4, 0.15), 0.00, 0.6)

func _physics_process(delta):
	var far_enough = far_enough()
	if rng.chance_delta(0.3, delta):
		can_shoot = !can_shoot
	for body in nearby_enemies:
		body.apply_force(to_local(body.global_position).normalized() * PUSH_FORCE)
	#if rng.chance_delta(0.25, delta):
	if level >= 2 and rng.chance_delta(0.25, delta):
		buffer_swap = true
	if moving_away:
		if rng.chance_delta(0.4, delta) or get_aim_distance() > MAX_BACK_AWAY_DIST:
			moving_away = false
	if !far_enough():
		can_stay_still = true
	elif rng.chance_delta(0.3, delta):
		moving_away = true
	#host.modulate = Color.RED if moving_away else Color.WHITE
	if can_stay_still:
		if !still and far_enough:
			if rng.chance_delta((Game.MAX_LEVEL - level) * 0.25, delta):
				still = true
				moving_away = false
		else:
			if !far_enough or rng.chance_delta(0.5 + (level - 1) * 0.5, delta):
				still = false

func _process(delta):
	if corrupted:
		if rng.chance_delta(15, delta):
			sprite.frame = rng.randi_range(0, sprite.sprite_frames.get_frame_count(sprite.animation))
		if rng.chance_delta(3, delta):
			sprite.flip_h = !sprite.flip_h	
		if rng.chance_delta(3, delta):
			sprite.flip_v = !sprite.flip_v
	t += delta
	
	var spell_1_target = spell_1_pos.x if host.spell_selection == 1 else spell_2_pos.x
	var spell_2_target = spell_2_pos.x if host.spell_selection == 1 else spell_1_pos.x
	
	spell_1.position.x = lerp(spell_1.position.x, spell_1_target, Utils.dtlerp(20, delta))
	if abs(spell_1.position.x - spell_1_target) < 1:
		spell_1.position.x = spell_1_target
	spell_2.position.x = lerp(spell_2.position.x, spell_2_target, Utils.dtlerp(20, delta))
	if abs(spell_2.position.x - spell_2_target) < 1:
		spell_2.position.x = spell_2_target

func get_aim_dir():
	return to_local(player.global_position).normalized()

func get_aim_distance():
	return to_local(player.global_position).length()

func far_enough():
	return get_aim_distance() > (max(((BACK_AWAY_DISTANCE * Utils.wave(0.5, 1.5, 4.0 * offs / 100.0, offs)) - BACK_AWAY_DISTANCE_REDUCTION_PER_LEVEL * (level - 1)), MIN_BACKUP_DISTANCE))

func get_move_dir():
	if still:
		return Vector2()
	return to_local(player.global_position + Vector2.RIGHT.rotated(t * 0.26) * 100).normalized() * (1 if (far_enough() and !moving_away) else -1)

func _on_nearby_enemy_detector_body_entered(body):
	if nearby_enemies.size() < 10:
		nearby_enemies.append(body)

func _on_nearby_enemy_detector_body_exited(body):
	nearby_enemies.erase(body)
