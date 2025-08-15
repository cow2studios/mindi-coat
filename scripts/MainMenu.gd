# scripts/MainMenu.gd attached to MainMenu
extends CenterContainer

@onready var start_button = $VBoxContainer/StartButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var rules_button = $VBoxContainer/RulesButton

func _ready():
	# Connect the button's "pressed" signal to our functions
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	rules_button.pressed.connect(UIManager.show_rules_popup)

func _on_start_button_pressed():
	SoundManager.play("click")
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_quit_button_pressed():
	SoundManager.play("click")
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
