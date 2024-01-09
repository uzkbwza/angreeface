extends Node2D

@export var character: Character

@onready var spell_1 = $Spell1
@onready var spell_2 = $Spell2

@onready var cursor = $Cursor
@onready var cursor2 = $Cursor2
@onready var reload_progress = $ReloadProgress
@onready var shield_icon = %ShieldIcon
@onready var shield_off = %ShieldOff
@onready var shield_on = %ShieldOn

const SPELL_SIZE = Vector2(32, 10)

var flashing_1 = false
var flashing_2 = false
var had_shield = false
var shield_flashing = false

func _ready():
	character.loaded_spell.connect(_on_loaded_spell)
	character.spell_lost.connect(_on_lost_spell)

func _on_loaded_spell(slot: int, spell: Spell):
	var sp: Sprite2D = spell_1
	if slot == 2:
		sp = spell_2
	sp.texture = spell.image
	var dimensions = spell.image.get_size()
	sp.scale = SPELL_SIZE / dimensions
	
	sp.get_material().set_shader_parameter("color", spell.bullet_color)

func _on_lost_spell(slot):
	if slot == 1:
		flashing_1 = true
	elif slot == 2:
		flashing_2 = true
	await get_tree().create_timer(0.5).timeout
	if slot == 1:
		flashing_1 = false
	elif slot == 2:
		flashing_2 = false

func _on_lost_shield():
	shield_flashing = true
	await get_tree().create_timer(0.25).timeout
	shield_flashing = false
	pass

func _process(delta):
	var cursor_target_x = cursor.position.x if character.spell_selection == 1 else cursor2.position.x
	var cursor_target_x2 = cursor2.position.x if character.spell_selection == 1 else cursor.position.x
	spell_1.position.x = lerp(spell_1.position.x, cursor_target_x, Utils.dtlerp(20, delta))
	if abs(spell_1.position.x - cursor_target_x) < 1:
		spell_1.position.x = cursor_target_x
	spell_2.position.x = lerp(spell_2.position.x, cursor_target_x2, Utils.dtlerp(20, delta))
	if abs(spell_2.position.x - cursor_target_x2) < 1:
		spell_2.position.x = cursor_target_x2
	
	spell_1.visible = (!flashing_1) or Utils.pulse(0.064)
	spell_2.visible = (!flashing_2) or Utils.pulse(0.064)
	var has_shield = !character.get_selected_spell().empty or !character.get_2nd_spell().empty
	shield_icon.visible = (has_shield or (!flashing_1 and !flashing_2 and !shield_flashing)) or Utils.pulse(0.064)
	shield_off.visible = !has_shield
	shield_on.visible = has_shield
	if !has_shield and had_shield:
		_on_lost_shield()
	
	reload_progress.value = 0.0
	if !character.fire_timer.is_stopped():
		reload_progress.value = (character.fire_timer.time_left / character.fire_timer.wait_time) * 100

	had_shield = has_shield
