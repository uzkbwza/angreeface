extends Camera2D

class_name GoodCamera

@export var default_screenshake_amount := 2.0
@export var default_screenshake_time := 1.0
#@onready var noise = FastNoiseLite.new()
#var noise_y = 0

#var shake_tween
var shake_amount = 0
var rng = BetterRng.new()

var offs_dir = Vector2()
var offs_value = 0

var shake_tween: Tween

@onready var starting_offset = offset

func _ready():
	rng.randomize()
	add_to_group("Camera")

func bump(dir:=Vector2(), amount:=default_screenshake_amount, time:=default_screenshake_time):
	if amount < offs_value:
		return
	if shake_tween:
		shake_tween.kill()
	shake_tween = create_tween()
	shake_tween.set_parallel(false)
	shake_tween.set_trans(Tween.TRANS_CIRC)
	shake_tween.set_ease(Tween.EASE_OUT)
	offs_dir = dir
	offs_value = amount
	shake_tween.tween_property(self, "offs_value", 0, time)


func _process(delta):
	offset = starting_offset
	if offs_value > 0:
		if offs_dir != Vector2():
			offset += offs_dir * offs_value
		else:
			offset += offs_value * rng.random_vec()
