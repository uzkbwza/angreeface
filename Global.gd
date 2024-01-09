extends Node

const MUSIC = preload("res://music.tscn")
const VOLUME = -6

var PLAYER_SPRITES = [
]

var high_score = 0

var music: AudioStreamPlayer
var audio_muted = false:
	set(b):
		audio_muted = b
		music.volume_db = VOLUME if !audio_muted else -100
		save_settings()

func save_settings():
	var dict = {
		"audio_muted": audio_muted,
	}
	Utils.quick_save_data(dict, "settings")

func load_settings():
	var settings = Utils.quick_load_data("settings")
	if settings:
		audio_muted = settings.audio_muted

func _init():
	for i in range(371, 472):
		var count = 1
		var sprite = ResourceLoader.load("res://sprites/spritesheet_%s.png" % i)
		if i in [421, 422, 423, 426, 433, 438, 439] or (i >= 441 and i <= 471):
			count *= 15
		if i == 446:
			count = 0
		if sprite:
			for j in count:
				PLAYER_SPRITES.append(load("res://sprites/spritesheet_%s.png" % i))

func _ready():
	load_high_score()
	music = MUSIC.instantiate()
	music.volume_db = VOLUME
	add_child.call_deferred(music)
	load_settings.call_deferred()

func play_music():
	if !music.playing:
		music.play()

func stop_music():
	music.stop()

func save_high_score(count):
	high_score = count
	var dict = {
		"high_score": high_score
	}
	Utils.quick_save_data(dict, "high_score")

func load_high_score():
	var data = Utils.quick_load_data("high_score")
	if data:
		high_score = data.high_score
