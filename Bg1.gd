extends Sprite2D

@export var zoom = 1.0

func _ready():
	region_rect.size /= (zoom * 2)
	scale *= zoom 

func _process(delta):
	region_rect.position = (global_position / scale) * zoom 
