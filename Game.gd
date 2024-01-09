extends Node2D

class_name Game

const MAX_LEVEL = 12
const SPAWN_DIST = 500
const SPAWN_TIME = 1.2
const BOUNDARY_X = 5000
const BOUNDARY_Y = 5000
const BULLET_POOL_SIZE = 300

@export var MAX_LEVEL_INCREASE_PER_WAVE = 0.2
@export var MAX_WAVE_SIZE = 30
var wave = 0
var spawns = 0

var game_started = false
var new_wave = false
var game_over = false
var spawned_pickup = false:
	set(b):
		if !spawned_pickup and b:
			spawn_random_spell_timer.start()
		spawned_pickup = b
var wave_spawns = 0
var bullet_index = -1
var bullet_pool = []

@export var WAVE_SIZE = 7
@export var EXTRA_ENEMIES_PER_WAVE = 0.5
@export var LEVEL_INCREASE_PER_WAVE = 0.25
@export var SPAWN_TIME_DECREASE_PER_WAVE = 0.05
@export var MIN_SPAWN_TIME = 0.1

@onready var bullets = $Bullets
@onready var kill_counter = %KillCounter
@onready var player = %Player
@onready var title = $Title
@onready var spawn_timer = $SpawnTimer
@onready var restart_button = %RestartButton
@onready var restart_button_holder = %RestartButtonHolder
@onready var spell_display = %SpellDisplay
@onready var spawn_random_spell_timer = $SpawnRandomSpellTimer


var wave_size = WAVE_SIZE
var num_enemies_active = 0
var rng = BetterRng.new()

func _on_player_player_moved():
	player.player_moved.disconnect(_on_player_player_moved)
	start_game()

func _ready():
	rng.randomize()
	player.died.connect(on_player_died)
	load_bullets()

func load_bullets():
	for i in range(BULLET_POOL_SIZE):
		#if i % 5 == 0:
			#await get_tree().physics_frame
		load_bullet.call_deferred()

func load_bullet():
	var bullet = preload("res://object/bullet.tscn").instantiate()
	bullets.add_child(bullet, true)
	#add_child(bullet, true)
	bullet.deactivate.call_deferred()
	bullet.disappeared.connect(_on_bullet_disappeared.bind(bullet))
	bullet_pool.append(bullet)

func _on_bullet_disappeared(bullet):
	pass

func get_bullet():
	bullet_index += 1
	bullet_index = bullet_index % bullet_pool.size()
	var bullet = bullet_pool[bullet_index]
	for i in range(BULLET_POOL_SIZE):
		if !bullet.active:
			break
		bullet_index += 1
		bullet_index = bullet_index % bullet_pool.size()
		bullet = bullet_pool[bullet_index]

	bullet.activate()
	return bullet

func on_player_died():
	game_over = true
	
	spell_display.hide()
	await get_tree().create_timer(1.0).timeout
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	restart_button_holder.show()
	restart_button_holder.self_modulate.a = 0.0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_parallel(true)
	tween.tween_property(restart_button_holder, "self_modulate:a", 1.0, 0.6)
	
	kill_counter.finalize.call_deferred()

	#tween.tween_property(restart_button_holder, "scale:y", 2.0, 0.6)

func start_game():
	if game_started:
		return
	Global.play_music()
	wave_size = WAVE_SIZE
	kill_counter.reset()
	game_started = true
	spawned_pickup = false
	var tween = create_tween()
	tween.tween_property(title, "self_modulate:a", 0.0, 0.4)
	spawn_timer.start(max(SPAWN_TIME - SPAWN_TIME_DECREASE_PER_WAVE * wave, MIN_SPAWN_TIME))
	#var spell = Spell.load_random_spell()
	#var pickup = preload("res://object/spell_pickup.tscn").instantiate()
	#add_child.call_deferred(pickup)
	#pickup.load_spell.call_deferred(spell)
	#pickup.global_position = player.global_position + Vector2(0, -80)
	#pickup.velocity = Vector2(0, 100)

func _on_spawn_timer_timeout():
	if new_wave:
		new_wave = false
		spawn_timer.stop()
		await get_tree().create_timer(9.0, false).timeout
		wave_size += EXTRA_ENEMIES_PER_WAVE
		if wave_size > MAX_WAVE_SIZE:
			wave_size = MAX_WAVE_SIZE
		wave_spawns = 0
		wave += 1
		spawn_timer.start(SPAWN_TIME) 
		
	if num_enemies_active >= floor(wave_size):
		return
	spawn_enemy.call_deferred()

func spawn_enemy():
	var enemy = preload("res://object/enemy.tscn").instantiate()

	num_enemies_active += 1
	var levels = []
	for i in range(floor(wave_size)):
		levels.append(clamp(floor(lerp(1.0, 3.0 + (wave * MAX_LEVEL_INCREASE_PER_WAVE), pow((i + 1.0) / floor(wave_size), 2.0)) + LEVEL_INCREASE_PER_WAVE * (wave - 1)), 1, 8))

	levels.shuffle()
#
	#if wave_spawns == 0:
		#print(levels)

	add_child(enemy)
	enemy.died.connect(on_enemy_died)
	enemy.global_position = player.global_position + rng.random_vec() * SPAWN_DIST

	#print("spawning enemy #", spawns + 1, " in wave ", wave + 1, ", #", wave_spawns + 1, " in wave, wave size ", wave_size, " (", int(floor(wave_size)), ")")


	enemy.enemy_component.enemy_setup(levels[wave_spawns - 1])
	if wave_spawns == int(floor(wave_size)) - 1:
		new_wave = true

	wave_spawns += 1
	spawns += 1

func on_enemy_died():
	num_enemies_active -= 1
	if !game_over:
		kill_counter.increment()

func _draw():
	var wall_color = Color("a967ff")
	wall_color.a *= 0.25
	var thickness = 4.0
	var boundary_x = BOUNDARY_X
	var boundary_y = BOUNDARY_Y
	draw_line(Vector2(-boundary_x + thickness / 2.0, -boundary_y), Vector2(boundary_x - thickness / 2.0, -boundary_y), wall_color, 4.0)
	draw_line(Vector2(-boundary_x, -boundary_y - thickness / 2.0), Vector2(-boundary_x, boundary_y + thickness / 2.0), wall_color, 4.0)
	draw_line(Vector2(boundary_x, -boundary_y - thickness / 2.0), Vector2(boundary_x, boundary_y + thickness / 2.0), wall_color, 4.0)
	draw_line(Vector2(boundary_x - thickness / 2.0, boundary_y), Vector2(-boundary_x + thickness / 2.0, boundary_y), wall_color, 4.0)


func _on_spawn_random_spell_timer_timeout():
	if game_started and !game_over and rng.percent(75):
		var spell = Spell.load_random_spell()
		var spell_pickup = preload("res://object/spell_pickup.tscn").instantiate()
		add_child.call_deferred(spell_pickup)
		spell_pickup.load_spell.call_deferred(spell, false)
		spell_pickup.global_position = player.global_position + rng.random_vec() * SPAWN_DIST
