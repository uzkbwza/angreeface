extends CanvasGroup

@export var color = Color()
@export var hover_color = Color()
@onready var restart_button = %RestartButton

func _process(delta):
	if visible:
		self_modulate = color if !restart_button.is_hovered() else hover_color
