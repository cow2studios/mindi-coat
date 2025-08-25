# scripts/HUD.gd
extends CanvasLayer

@onready var game_over_panel = $MainContainer/CenterContainer/GameOverPanel
@onready var game_over_label = $MainContainer/CenterContainer/GameOverPanel/VBoxContainer/GameOverLabel
@onready var new_game_button = $MainContainer/CenterContainer/GameOverPanel/VBoxContainer/NewGameButton

func _ready():
	new_game_button.pressed.connect(_on_play_again_pressed)

func _on_play_again_pressed():
	SoundManager.play("click")
	get_tree().paused = false # Make sure game is unpaused before changing scenes
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func show_game_over(message):
	game_over_label.text = message
	game_over_panel.show()
