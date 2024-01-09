extends Control

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

@onready var top = %Top
@onready var middle = %Middle
@onready var bottom = %Bottom
@onready var w1 = %W1
@onready var w2 = %W2
@onready var e1 = %E1
@onready var e2 = %E2
@onready var group = %KillCounterLCD
@onready var panel = $Panel

@onready var display_map = {
	0: [top, bottom, w1, w2, e1, e2],
	1: [e1, e2],
	2: [top, middle, bottom, e1, w2],
	3: [top, middle, bottom, e1, e2],
	4: [middle, w1, e1, e2],
	5: [top, middle, bottom, w1, e2],
	6: [top, middle, bottom, w1, w2, e2],
	7: [top, e1, e2],
	8: [top, middle, bottom, w1, w2, e1, e2],
	9: [top, middle, w1, e1, e2],
}

var rng = BetterRng.new()

func _ready():
	rng.randomize()
	for child in group.get_children():
		child.hide()

func set_number(num: int):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	panel.modulate.a = 0.0
	tween.tween_property(panel, "modulate:a", 1.0, 1.0)
	
	for child in group.get_children():
		if child.visible and !(child in display_map[num]):
			shut_off(child)
		elif !child.visible and child in display_map[num]:
			switch_on(child)
		await get_tree().create_timer(rng.randf_range(0.05, 0.15)).timeout

func _process(delta):
	for child in group.get_children():
		if child.visible:
			if rng.chance_delta(4, delta):
				child.texture = rng.choose(SPRITES)
			if rng.chance_delta(3.0, delta):
				flicker(child)

func switch_on(segment):
	await get_tree().create_timer(rng.randf_range(0.05, 0.1), false).timeout
	for i in range(rng.randi_range(1, 30)):
		segment.visible = true
		for j in range(rng.randi_range(1, 2)):
			await get_tree().create_timer(0.016).timeout
		segment.visible = false
		for j in range(rng.randi_range(1, max(10 - i, 0))):
			await get_tree().create_timer(0.016).timeout
	segment.show()

func flicker(segment):
	segment.visible = false
	await get_tree().create_timer(rng.randf_range(0.016, 0.032)).timeout
	segment.visible = true
	

func shut_off(segment):
	await get_tree().create_timer(rng.randf_range(0.25, 0.73), false).timeout
	for i in range(rng.randi_range(1, 20)):
		for j in range(rng.randi_range(1, 10)):
			await get_tree().physics_frame
		segment.visible = !visible
	segment.hide()
