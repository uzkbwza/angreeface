@tool

extends Resource

class_name Spell

const BASE_FIRE_RATE = 0.4
const PICKUP_TIME = 13.0
 
enum FirePattern {
	Normal,
	EqualSpread,
	Flank,
}

@export var name: String
@export var image: Texture2D
@export var empty = false
@export var special = false

# spell_1 stuff
@export_group("spell 1")
#@export var bullet_sprite: Texture2D
@export var bullet_property: Bullet.BulletProperty
var bullet_color: Color:
	get:
		return {
			Bullet.BulletProperty.Normal: Color("edc13b"),
			Bullet.BulletProperty.Poison: Color("a967ff"),
			Bullet.BulletProperty.Fire: Color("ff8563"),
			Bullet.BulletProperty.Paralyze: Color("acdba6"),
			Bullet.BulletProperty.Piercing: Color("ffffff"),
			Bullet.BulletProperty.Explosive: Color("11bfff"),
			#Bullet.BulletProperty.Swarm: Color("176ed2"),
			Bullet.BulletProperty.Virus: Color("63de53"),
			Bullet.BulletProperty.LightningChain: Color("ffe250"),
			Bullet.BulletProperty.Split: Color("68a3c9"),
			Bullet.BulletProperty.Big: Color("cd8668"),

		}[bullet_property]

@export var spell_1_damage_modifier = 1.0
@export var spell_1_speed_modifier = 1.0
@export var spell_1_fire_rate_modifier = 1.0

@export_multiline var call_update_functions = ""
@export_multiline var additional_properties = ""

# spell_2 stuff
@export_group("spell 2")
@export_multiline var call_update_functions_2 = ""
@export_multiline var additional_properties_2 = ""
@export var fire_pattern: FirePattern
@export var fire_rate = BASE_FIRE_RATE
@export var damage_modifier = 1.0
@export var speed = 250
@export var speed_random_distribution = 0.0
@export var drag = 0.0
@export var spread_degrees = 0.0
@export var num_bullets = 1
@export var num_bursts = 1
@export var num_pierces = 1
@export var burst_rate = 0.1

@export_group("flank")
@export var flank_angle = 90
@export var flank_time = 0.016

func is_special():
	#return special or call_update_functions or call_update_functions_2 or additional_properties or additional_properties_2
	return special or call_update_functions or call_update_functions_2 or additional_properties

var swarm_func = func(bullet: Bullet, delta): 
				if !bullet.player_side:
					return
				var mdir = (bullet.get_global_mouse_position() - bullet.global_position).normalized()
				bullet.velocity = bullet.velocity.lerp(mdir * bullet.speed * 0.85, Utils.dtlerp(1, delta))

func apply_properties(bullet: Bullet):
	match bullet_property:
		Bullet.BulletProperty.Normal:
			pass
		Bullet.BulletProperty.Poison:
			bullet.damage *= 0.25
			bullet.speed *= 1.5
			bullet.velocity *= 1.5
		Bullet.BulletProperty.Fire:
			bullet.damage *= 1.1
			bullet.speed *= 0.9
			bullet.velocity *= 0.9
		Bullet.BulletProperty.Big:
			bullet.damage *= 2.0
			bullet.speed *= 0.9
			bullet.velocity *= 0.9


	bullet.damage *= spell_1_damage_modifier
	bullet.speed *= spell_1_speed_modifier
	
	
	if name == "FOOD":
		bullet.damage *= 0.1
		#Bullet.BulletProperty.Swarm:
			#bullet.extra_custom_functions.append(swarm_func)
	
	apply_additional_properties(bullet)
	
	if bullet.properties["Split"]:
		bullet.damage = bullet.damage * 2.5
		bullet.speed *= 0.8

func apply_additional_properties(bullet: Bullet, slot = 1):
	for property in (additional_properties if slot == 1 else (additional_properties_2 if additional_properties_2 != null else "")).split("\n"):
		property = property.strip_edges()
		if property == "Piercing":
			bullet.pierces_left = 10000
		if property == "Explosive":
			bullet.pierces_left = 1
		bullet.properties[property] = true

func get_move_speed_modifier():
	var mod = 1.0
	match bullet_property:
		Bullet.BulletProperty.Normal:
			pass
		Bullet.BulletProperty.Poison:
			mod *= 1.2
		Bullet.BulletProperty.Paralyze:
			mod *= 1.1
		Bullet.BulletProperty.Piercing:
			mod *= 0.9
		Bullet.BulletProperty.Explosive:
			mod *= 0.8
		Bullet.BulletProperty.Virus:
			mod *= 1.15
		Bullet.BulletProperty.LightningChain:
			mod *= 1.3
		Bullet.BulletProperty.Split:
			mod *= 0.9
		Bullet.BulletProperty.Big:
			mod *= 0.75
	return mod


func get_custom_update_functions(slot):
	var call_update_functions = call_update_functions if slot == 1 else call_update_functions_2
	var funcs = []
	if "Swarm" in call_update_functions:
		funcs.append(swarm_func)
	return funcs

func get_fire_rate_modifier():
	var mod = 1.0 / spell_1_fire_rate_modifier
	if bullet_property == Bullet.BulletProperty.Split or "Split" in additional_properties:
		mod *= 2.0
	return mod

static func load_random_spell() -> Spell:
	var rng = BetterRng.new()
	rng.randomize()
	var spell: Spell = ResourceLoader.load(rng.choose([
		"res://spells/ANI.tres",
		"res://spells/AP.tres",
		"res://spells/ARMS.tres",
		"res://spells/BUIL.tres",
		"res://spells/BUS.tres",
		"res://spells/CES.tres",
		"res://spells/CKS.tres",
		"res://spells/DIN.tres",
		"res://spells/ELLS.tres",
		"res://spells/EMS.tres",
		"res://spells/ES.tres",
		"res://spells/F.tres",
		"res://spells/FOOD.tres",
		"res://spells/GRA.tres",
		"res://spells/GRO.tres",
		"res://spells/GS.tres",
		"res://spells/HER.tres",
		"res://spells/HES.tres",
		"res://spells/IT.tres",
		"res://spells/LIQ.tres",
		"res://spells/MALS.tres",
		"res://spells/MO.tres",
		"res://spells/MOUN.tres",
		"res://spells/NS.tres",
		"res://spells/NTS.tres",
		"res://spells/OADS.tres",
		"res://spells/OES.tres",
		"res://spells/OLS.tres",
		"res://spells/ONS.tres",
		"res://spells/OUR.tres",
		"res://spells/P.tres",
		"res://spells/PA.tres",
		"res://spells/PLA.tres",
		"res://spells/R.tres",
		"res://spells/REL.tres",
		"res://spells/RES.tres",
		"res://spells/RO.tres",
		"res://spells/ROPS.tres",
		"res://spells/SP.tres",
		"res://spells/SS.tres",
		"res://spells/TAINS.tres",
		"res://spells/TERS.tres",
		"res://spells/TO.tres",
		"res://spells/TRE.tres",
		"res://spells/UI.tres",
		"res://spells/UIDS.tres",
		"res://spells/UND.tres",
		"res://spells/WEAP.tres",
	]))
	if spell.is_special() and rng.percent(50):
		return load_random_spell()
	return spell
