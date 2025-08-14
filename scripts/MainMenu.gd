# scripts/MainMenu.gd attached to MainMenu
extends Control

@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton

func _ready():
	# Connect the button's "pressed" signal to our functions
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	# This function changes the current scene to the main game scene
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_quit_button_pressed():
	# This function closes the application
	get_tree().quit()
