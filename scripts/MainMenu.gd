# scripts/MainMenu.gd attached to MainMenu
extends CenterContainer

@onready var start_button = $VBoxContainer/StartButton
@onready var quit_button = $VBoxContainer/QuitButton

func _ready():
	# Connect the button's "pressed" signal to our functions
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	# This function changes the current scene to the main game scene
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_quit_button_pressed():
	# This function closes the application
	get_tree().quit()
