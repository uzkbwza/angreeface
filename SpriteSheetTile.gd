@tool 

extends Sprite2D

@export var tile_size: Vector2i = Vector2i(16, 16)
@export var tile: Vector2i:
	set(xy):
		tile = xy
		region_enabled = true
		region_rect.position = Vector2(xy * tile_size)
		region_rect.size = Vector2(tile_size)
