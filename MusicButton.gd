extends Button

@onready var note = $Note
@onready var slash = $Slash

func _ready():
	await get_tree().process_frame
	button_pressed = !Global.audio_muted

func _process(delta):
	slash.modulate.a = 0.0
	if is_hovered() and button_pressed:
		slash.modulate.a = 0.5
	elif !button_pressed:
		slash.modulate.a = 1.0

func _on_toggled(toggled_on):
	Global.audio_muted = !toggled_on
