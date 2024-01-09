extends Node2D

@export var lifetime = 1.0
# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(lifetime, false).timeout
	queue_free()
