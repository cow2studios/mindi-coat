# Controls the main menu buttons.
extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var rules_button = $VBoxContainer/RulesButton

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	rules_button.pressed.connect(UIManager.show_rules_popup)

func _on_start_button_pressed():
	SoundManager.play("click")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_quit_button_pressed():
	SoundManager.play("click")
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
