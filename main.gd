extends Node

@onready var pause_menu = %PauseMenu
@onready var game = $GameLayer/Game

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	pause_menu.hide()

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func _input(event):
	if Input.is_action_just_pressed("ui_cancel") and !game.game_over:
		get_tree().paused = !get_tree().paused
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN if !get_tree().paused else Input.MOUSE_MODE_VISIBLE
		pause_menu.visible = get_tree().paused
 
	if Input.is_action_just_pressed("fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_quit_button_pressed():
	get_tree().quit()
	pass # Replace with function body.
