extends Control

@onready var h_box_container = $HBoxContainer
@onready var lcd_container = $HBoxContainer2
@onready var hi_score_lcd_container = $HBoxContainer3
@onready var hi = %Hi

@export var color_1: Color
@export var color_2: Color

const SIZE = 8
const SPRITES = [
	preload("res://sprites/meta/spritesheet_1.png"),
	preload("res://sprites/meta/spritesheet_2.png"),
	preload("res://sprites/meta/spritesheet_3.png"),
	preload("res://sprites/meta/spritesheet_4.png"),
	preload("res://sprites/meta/spritesheet_5.png"),
	preload("res://sprites/meta/spritesheet_6.png"),
	preload("res://sprites/meta/spritesheet_7.png"),
	preload("res://sprites/meta/spritesheet_8.png"),
	preload("res://sprites/meta/spritesheet_9.png"),
	preload("res://sprites/meta/spritesheet_10.png"),
	preload("res://sprites/meta/spritesheet_11.png"),
	preload("res://sprites/meta/spritesheet_12.png"),
	preload("res://sprites/meta/spritesheet_13.png"),
	preload("res://sprites/meta/spritesheet_14.png"),
	preload("res://sprites/meta/spritesheet_15.png"),
	preload("res://sprites/meta/spritesheet_16.png"),
	preload("res://sprites/meta/spritesheet_17.png"),
	preload("res://sprites/meta/spritesheet_18.png"),
	preload("res://sprites/meta/spritesheet_19.png"),
	preload("res://sprites/meta/spritesheet_20.png"),
	preload("res://sprites/meta/spritesheet_21.png"),
	preload("res://sprites/meta/spritesheet_22.png"),
	preload("res://sprites/meta/spritesheet_23.png"),
	preload("res://sprites/meta/spritesheet_24.png"),
	preload("res://sprites/meta/spritesheet_25.png"),
	preload("res://sprites/meta/spritesheet_26.png"),
	preload("res://sprites/meta/spritesheet_27.png"),
	preload("res://sprites/meta/spritesheet_28.png"),
	preload("res://sprites/meta/spritesheet_29.png"),
]

var count = 0:
	set(x):
		count = x
		_set_count(x)

var str_rep = ""

var rng = BetterRng.new()

func _ready():
	rng.randomize()

func increment():
	count += 1

func _process(delta):
	for child in h_box_container.get_children():
		if rng.chance_delta(1, delta):
			child.texture = rng.choose(SPRITES)
	#increment()

func _set_count(count):
	str_rep = ""
	var num = count
	while num != 0:
		str_rep += str(num & 1)
		num = num >> 1
	str_rep = str_rep.reverse()
	#print(str_rep)
	update.call_deferred()

func finalize():
	if count > Global.high_score:
		Global.save_high_score(count)
	show_number(count, lcd_container)
	await get_tree().create_timer(1.0).timeout
	show_high_score()

func show_number(count, container):
	var final_count_string: String = str(int(count))
	var lcds = []
	for char in (final_count_string):
		var lcd = preload("res://kill_counter_lcd.tscn").instantiate()
		container.add_child(lcd)
		lcds.append(lcd)

	for i in range(len(lcds)):
		var lcd = lcds[i]
		lcd.set_number(int(final_count_string[i]))
		await get_tree().create_timer(0.5).timeout

func show_high_score():
	var tween = create_tween()
	tween.tween_property(hi, "self_modulate:a", 0.6, 1.0)
	show_number(Global.high_score, hi_score_lcd_container)

func update():
	for child in h_box_container.get_children():
		child.queue_free()
	for character in str_rep:
		var texture_rect = TextureRect.new()
		texture_rect.texture = rng.choose(SPRITES)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.custom_minimum_size = Vector2(SIZE, SIZE)
		texture_rect.self_modulate = color_1 if character == "1" else color_2
		h_box_container.add_child(texture_rect)

func reset():
	count = 0
